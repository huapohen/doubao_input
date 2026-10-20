# -*- coding: utf-8 -*-
"""Collect clone screenshots into reports/assets/clones and a JSON manifest."""
import json
import os
import re
from PIL import Image

ROOT = '/Users/lwblx/huapohen/agent/rea/doubao_input'
OUT = os.path.join(ROOT, 'reports/assets/clones')
os.makedirs(OUT, exist_ok=True)

SOURCES = {
    'flutter': os.path.join(ROOT, 'clones/flutter/screenshots'),
    'android': os.path.join(ROOT, 'clones/android_native/screenshots'),
    'ios': os.path.join(ROOT, 'clones/ios_native/screenshots'),
}

LABEL_RULES = [
    (r'onboard|guide|welcome', '引导/启用'),
    (r'privacy|consent', '隐私与模式'),
    (r'keyboard.?type|picker', '键盘类型选择'),
    (r'keyboard|ime|26|9key|t9|hand', '键盘/输入'),
    (r'toolbox|toolbar|panel|emoji|clipboard|phrase', '键盘面板'),
    (r'voice|asr|mic', '语音'),
    (r'ai|write|organize|translate', 'AI'),
    (r'settings|home|main', '设置首页'),
    (r'layout|fuzzy|feedback|prediction|clipboard|lexicon|permission|account|login|about|help|desktop|transfer|mode', '设置子页'),
    (r'ipad|tablet|pad|land', '平板/横屏'),
]


def label_for(name):
    low = name.lower()
    for pattern, label in LABEL_RULES:
        if re.search(pattern, low):
            return label
    return '其他'


manifest = []
for group, src in SOURCES.items():
    if not os.path.isdir(src):
        continue
    for fn in sorted(os.listdir(src)):
        if not re.search(r'\.(png|jpe?g)$', fn, re.I):
            continue
        path = os.path.join(src, fn)
        try:
            im = Image.open(path).convert('RGB')
        except Exception:
            continue
        w, h = im.size
        max_w = 704
        if w > max_w:
            im = im.resize((max_w, int(h * max_w / w)), Image.LANCZOS)
        base = re.sub(r'\.(png|jpe?g)$', '', fn, flags=re.I)
        safe = re.sub(r'[^A-Za-z0-9._-]+', '_', base)
        out_name = f'{group}_{safe}.webp'
        im.save(os.path.join(OUT, out_name), 'WEBP', quality=82, method=6)
        label = label_for(base)
        manifest.append({
            'file': out_name,
            'group': group,
            'label': f'{label} · {base}',
            'w': im.width,
            'h': im.height,
        })

with open(os.path.join(ROOT, 'reports/assets/clones.json'), 'w', encoding='utf-8') as f:
    json.dump(manifest, f, ensure_ascii=False, indent=2)
print('clone screenshots', len(manifest),
      'bytes', sum(os.path.getsize(os.path.join(OUT, m['file'])) for m in manifest))
