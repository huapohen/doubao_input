# Shared clone assets

## `data/pinyin_dict.json`

- 33,500 entries: common single characters + 2–4 character words.
- Fields: `w` word, `p` toneless space-separated pinyin, `f` frequency.
- Generated from **jieba** word frequencies and **pypinyin** (both MIT); no ByteDance/豆包 data.
- Regenerate: `python3 scripts/build_pinyin_dict.py` (needs `jieba`, `pypinyin`).
- Licensed under MIT; see `LICENSES.md`.

Each clone copies this file into its platform assets:

- Flutter: `clones/flutter/assets/data/pinyin_dict.json`
- Android: `clones/android_native/app/src/main/assets/pinyin_dict.json`
- iOS: `clones/ios_native/Shared/pinyin_dict.json` (app + keyboard extension resource)

The engine is a clean-room implementation; candidate ranking will not match the official app exactly.
