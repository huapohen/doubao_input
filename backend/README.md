# 可替换后端参考实现

这是给三端复刻使用的**最小可替换后端**，不依赖任何官方豆包接口。Node 20+，零 npm 依赖。

## 运行

```bash
cd backend
node server.js
# http://127.0.0.1:8787
```

配置环境变量（不要把 Key 写入仓库）：

```bash
export DEEPSEEK_API_KEY='...'
export DEEPSEEK_BASE_URL='https://api.deepseek.com'
export DEEPSEEK_MODEL='deepseek-flash'   # 或 deepseek-chat
export API_TOKEN='optional-bearer-token'
export PORT=8787
node server.js
```

无 Key 时所有 AI 接口返回**确定性的本地模板**，便于离线演示；有 Key 时走 OpenAI 兼容
`POST {BASE}/chat/completions`。

## 接口

| Method | Path | Body / Query | 返回 |
|---|---|---|---|
| GET | `/health` | — | `{ok, ai, model}` |
| GET | `/v1/config` | — | `{features, limits, model}` |
| POST | `/v1/ai/write` | `{action, text, context, local?}` | `{text, provider}` |
| POST | `/v1/ai/organize` | `{text, mode}` | `{text, provider}` |
| POST | `/v1/ai/translate` | `{text, from, to}` | `{text, provider}` |
| POST | `/v1/asr` | multipart/audio（TODO） | `{text, confidence, segments}` |
| POST | `/v1/clipboard/sync` | `{deviceId, items[]}` | `{items[]}` |
| GET | `/v1/clipboard/sync?deviceId=` | — | `{items[]}` |

`action`: `blessing` `circle` `comment` `intro` `invitation` `mail` `popular`
`rewrite` `summary` `keypoints` `list` `check` `translate`。

`Authorization: Bearer <API_TOKEN>`（若设置了 `API_TOKEN`）。

## 验证

```bash
curl -s http://127.0.0.1:8787/health
curl -s -X POST http://127.0.0.1:8787/v1/ai/write \
  -H 'content-type: application/json' \
  -d '{"action":"blessing","text":"朋友生日","context":"轻松真诚"}'
```

本机验证结果（未记录 Key）：

- 无 Key：`{"provider":"local"}`，返回中文模板。
- 有 Key / `deepseek-flash`：`{"provider":"deepseek"}`，返回真实生成文本（已实际调用成功）。

## 替换为自有服务

三端客户端都支持在设置里修改 `Base URL` / `Model` / `API Key`；只要实现上表即可替换。
建议保留 `provider` 字段用于区分 `local` / 云端，便于 UI 标注。

## 安全

- 参考实现只监听 `127.0.0.1`；对外部署时请加 TLS、鉴权、限流、审计与内容安全。
- 不要把 `DEEPSEEK_API_KEY` 写入代码、日志、截图或 Git。
- ASR 接口是占位；生产环境请接自己的语音模型，并明确音频存储/保留策略。
