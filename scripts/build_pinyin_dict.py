# -*- coding: utf-8 -*-
"""Regenerate the clean-room pinyin dictionary from open-source data.

Requires: pip install jieba pypinyin
Output: clones/shared/data/pinyin_dict.json
"""
import json
import os
import re

import jieba
from pypinyin import Style, lazy_pinyin

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, 'clones/shared/data/pinyin_dict.json')

candidates = {}
dict_path = os.path.join(os.path.dirname(jieba.__file__), 'dict.txt')
with open(dict_path, encoding='utf-8') as f:
    for line in f:
        parts = line.split()
        if len(parts) < 2:
            continue
        word = parts[0]
        try:
            freq = int(parts[1])
        except ValueError:
            continue
        if not all('\u4e00' <= ch <= '\u9fff' for ch in word):
            continue
        if len(word) > 4:
            continue
        candidates[word] = max(candidates.get(word, 0), freq)

manual = {
    '你好': 9999999, '豆包': 9999998, '输入法': 9999997, '豆包输入法': 9999996,
    '语音输入': 9999995, '人工智能': 9999994, '智能联想': 9999993,
    '智能文字整理': 9999992, '超级互传': 9999991, '微信': 9999990,
    '支付宝': 9999989, '谢谢': 9999988, '我爱你': 9999987, '在吗': 9999986,
    '好的': 9999985, '收到': 9999984, '没问题': 9999983, '今天': 9999982,
    '明天': 9999981, '可以': 9999980, '不可以': 9999979, '什么': 9999978,
    '为什么': 9999977, '怎么样': 9999976, '请问': 9999975, '麻烦': 9999974,
    '不好意思': 9999973, '没关系': 9999972, '再见': 9999971,
    '生日快乐': 9999970, '新年快乐': 9999969, '恭喜发财': 9999968,
    '一路顺风': 9999967,
}
for k, v in manual.items():
    candidates[k] = max(v, candidates.get(k, 0))

entries = []
for word, freq in candidates.items():
    py = lazy_pinyin(word, style=Style.NORMAL, errors='ignore')
    if not py or any(not p for p in py):
        continue
    if not all(re.fullmatch(r'[a-z]+', p) for p in py):
        continue
    entries.append((word, ' '.join(py), freq))
entries.sort(key=lambda x: (-x[2], -len(x[0]), x[0]))

singles = [e for e in entries if len(e[0]) == 1][:3500]
words = [e for e in entries if len(e[0]) > 1][:30000]
seen = set()
out = []
for word, py, freq in singles + words:
    if word in seen:
        continue
    seen.add(word)
    out.append({'w': word, 'p': py, 'f': freq})

data = {
    'version': 1,
    'source': 'jieba 0.42.1 dict + pypinyin 0.55.0 (both MIT); compact clean-room build',
    'count': len(out),
    'entries': out,
}
os.makedirs(os.path.dirname(OUT), exist_ok=True)
with open(OUT, 'w', encoding='utf-8') as f:
    json.dump(data, f, ensure_ascii=False, separators=(',', ':'))
print('wrote', OUT, len(out), 'entries', os.path.getsize(OUT), 'bytes')
