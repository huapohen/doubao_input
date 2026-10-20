#!/usr/bin/env node
/**
 * Reference replaceable backend for the Doubao IME clean-room clone.
 * No dependencies. Node 20+.
 *
 * Env:
 *   PORT=8787
 *   DEEPSEEK_API_KEY=...        optional; without it, deterministic local fallbacks are used
 *   DEEPSEEK_BASE_URL=https://api.deepseek.com
 *   DEEPSEEK_MODEL=deepseek-chat
 *   API_TOKEN=...               optional bearer token
 */
const http = require('http');
const { URL } = require('url');

const PORT = Number(process.env.PORT || 8787);
const KEY = process.env.DEEPSEEK_API_KEY || '';
const BASE = (process.env.DEEPSEEK_BASE_URL || 'https://api.deepseek.com').replace(/\/$/, '');
const MODEL = process.env.DEEPSEEK_MODEL || 'deepseek-chat';
const TOKEN = process.env.API_TOKEN || '';
const clipboardStore = new Map();

function json(res, code, obj) {
  const body = JSON.stringify(obj);
  res.writeHead(code, {
    'content-type': 'application/json; charset=utf-8',
    'content-length': Buffer.byteLength(body),
    'access-control-allow-origin': '*',
    'access-control-allow-headers': 'authorization,content-type',
    'access-control-allow-methods': 'GET,POST,OPTIONS',
  });
  res.end(body);
}
function authorized(req) {
  if (!TOKEN) return true;
  return (req.headers.authorization || '') === `Bearer ${TOKEN}`;
}
function readBody(req) {
  return new Promise((resolve, reject) => {
    let data = '';
    req.on('data', c => { data += c; if (data.length > 2_000_000) reject(new Error('too large')); });
    req.on('end', () => { try { resolve(data ? JSON.parse(data) : {}); } catch (e) { reject(e); } });
    req.on('error', reject);
  });
}
function localWrite(action, text, context) {
  const t = (text || '').trim();
  const map = {
    blessing: `祝你${t || '一切顺利'}，所愿皆成，所行皆坦途。`,
    circle: `${t || '今天的小确幸'}。\n\n生活不必处处满分，但每一刻都值得被认真记录。`,
    comment: `看完很有共鸣。${t || '谢谢你分享这份感受'}，期待更多。`,
    intro: `你好，我是${t || '一个热爱学习与创造的人'}。喜欢把复杂的问题讲清楚，也喜欢把简单的事做扎实。`,
    invitation: `诚挚邀请你参加${t || '这次聚会'}。期待与你相见，一起度过愉快的时光。`,
    mail: `您好：\n\n${t || '关于近期的事项，想与您同步一下进展。'}\n\n如有疑问，欢迎随时联系。\n\n祝好`,
    popular: `${t || '这件事'}，我终于想明白了。\n\n不是所有努力都会立刻有结果，但每一次认真都算数。`,
    rewrite: t ? `${t}\n\n（已按更清晰的表达重写）` : '请先输入要重写的内容。',
    summary: t ? `要点：\n1. ${t.slice(0, 60)}\n2. 保留核心信息，删去重复表达。` : '请先输入要总结的内容。',
    keypoints: t ? `• ${t.slice(0, 40)}\n• 关键结论\n• 下一步行动` : '请先输入内容。',
    list: t ? `1. ${t}\n2. 补充说明\n3. 下一步` : '请先输入内容。',
    check: t ? `检查结果：\n- 语句整体通顺\n- 建议补充标点与主语\n- 原文：${t}` : '请先输入要检查的内容。',
    translate: t,
  };
  return map[action] || (t ? `${t}` : '请先输入内容。');
}
function localOrganize(text, mode) {
  const t = (text || '').trim();
  if (!t) return '';
  const sentences = t.replace(/\s+/g, ' ').split(/(?<=[。！？!?；;])/).filter(Boolean);
  if (mode === 'summary') return sentences.slice(0, 3).join('');
  if (mode === 'bullet') return sentences.map((s, i) => `${i + 1}. ${s.trim()}`).join('\n');
  return sentences.map(s => s.trim()).join('\n');
}
async function deepseek(messages, { stream = false } = {}) {
  if (!KEY) return null;
  const r = await fetch(`${BASE}/chat/completions`, {
    method: 'POST',
    headers: { 'content-type': 'application/json', authorization: `Bearer ${KEY}` },
    body: JSON.stringify({ model: MODEL, messages, temperature: 0.8, stream }),
  });
  if (!r.ok) throw new Error(`deepseek ${r.status}: ${(await r.text()).slice(0, 300)}`);
  return r;
}
function promptFor(action, text, context) {
  const sys = '你是豆包输入法复刻版的写作助手。输出简体中文，直接给出可用文本，不要解释过程。';
  const map = {
    blessing: '写一段真诚、不过度套话的祝福。',
    circle: '写一条高赞社交媒体动态，口语化、有记忆点。',
    comment: '写一条有共鸣、不油腻的评论。',
    intro: '写一段简洁有力的自我介绍。',
    invitation: '写一份得体的宴席/活动邀请。',
    mail: '写一封结构清晰、礼貌的邮件。',
    popular: '写一段有传播力的爆款文案。',
    rewrite: '在不改变事实的前提下重写，使表达更清晰。',
    summary: '总结为 3 条以内要点。',
    keypoints: '提取关键点，使用项目符号。',
    list: '整理为有序列表。',
    check: '检查语法、标点、表达问题，给出简短建议。',
    translate: '翻译为自然、准确的目标语言。',
  };
  const instr = map[action] || '润色下面的文本。';
  return [
    { role: 'system', content: sys },
    { role: 'user', content: `${instr}\n\n${context ? `上下文：${context}\n` : ''}文本：${text || ''}` },
  ];
}
const server = http.createServer(async (req, res) => {
  const u = new URL(req.url, `http://localhost:${PORT}`);
  if (req.method === 'OPTIONS') return json(res, 204, {});
  if (u.pathname === '/health') return json(res, 200, { ok: true, ai: !!KEY, model: MODEL });
  if (u.pathname === '/v1/config') return json(res, 200, {
    features: { asr: false, ai: !!KEY, clipboard: true, translate: true, organize: true },
    limits: { text: 20000, audioSeconds: 60 },
    model: MODEL,
  });
  if (!authorized(req)) return json(res, 401, { error: 'unauthorized' });

  try {
    if (u.pathname === '/v1/ai/write' && req.method === 'POST') {
      const b = await readBody(req);
      const action = b.action || 'rewrite';
      const text = b.text || '';
      const context = b.context || '';
      if (!KEY || b.local) return json(res, 200, { text: localWrite(action, text, context), provider: 'local' });
      const r = await deepseek(promptFor(action, text, context));
      const data = await r.json();
      return json(res, 200, { text: data.choices?.[0]?.message?.content || localWrite(action, text, context), provider: 'deepseek' });
    }
    if (u.pathname === '/v1/ai/organize' && req.method === 'POST') {
      const b = await readBody(req);
      const text = b.text || '';
      const mode = b.mode || 'paragraph';
      if (!KEY || b.local) return json(res, 200, { text: localOrganize(text, mode), provider: 'local' });
      const r = await deepseek([
        { role: 'system', content: '你是文字整理助手。保留原意，补全标点，分段清晰，不添加事实。' },
        { role: 'user', content: `模式：${mode}\n原文：${text}` },
      ]);
      const data = await r.json();
      return json(res, 200, { text: data.choices?.[0]?.message?.content || localOrganize(text, mode), provider: 'deepseek' });
    }
    if (u.pathname === '/v1/ai/translate' && req.method === 'POST') {
      const b = await readBody(req);
      const text = b.text || '';
      const to = b.to || 'en';
      if (!KEY || b.local) return json(res, 200, { text: localWrite('translate', text), provider: 'local', note: '无 Key 时仅回显；请配置 DEEPSEEK_API_KEY' });
      const r = await deepseek([
        { role: 'system', content: `你是专业翻译。只输出译文，目标语言：${to}。` },
        { role: 'user', content: text },
      ]);
      const data = await r.json();
      return json(res, 200, { text: data.choices?.[0]?.message?.content || '', provider: 'deepseek' });
    }
    if (u.pathname === '/v1/asr' && req.method === 'POST') {
      return json(res, 200, {
        text: '（参考后端未接入语音模型；请在此实现 ASR）',
        confidence: 0,
        segments: [],
        provider: 'stub',
      });
    }
    if (u.pathname === '/v1/clipboard/sync' && req.method === 'POST') {
      const b = await readBody(req);
      const deviceId = String(b.deviceId || 'unknown');
      const items = Array.isArray(b.items) ? b.items : [];
      clipboardStore.set(deviceId, [...items, ...(clipboardStore.get(deviceId) || [])].slice(0, 50));
      return json(res, 200, { items: clipboardStore.get(deviceId) });
    }
    if (u.pathname === '/v1/clipboard/sync' && req.method === 'GET') {
      const deviceId = u.searchParams.get('deviceId') || 'unknown';
      return json(res, 200, { items: clipboardStore.get(deviceId) || [] });
    }
    return json(res, 404, { error: 'not found' });
  } catch (e) {
    return json(res, 500, { error: String(e.message || e) });
  }
});
server.listen(PORT, '127.0.0.1', () => {
  console.log(`doubao clone backend on http://127.0.0.1:${PORT}  ai=${KEY ? 'deepseek' : 'local-fallback'}`);
});
