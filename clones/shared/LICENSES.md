# Third-party data and licenses

## pinyin_dict.json

Generated for this clean-room clone from:

- **jieba** 0.42.1 word frequencies — MIT License — https://github.com/fxsjy/jieba
- **pypinyin** 0.55.0 — MIT License — https://github.com/mozillazg/python-pinyin

The generated file contains only word strings, toneless pinyin, and integer
frequencies. It contains no ByteDance/豆包 dictionary data.

Regenerate with `scripts/build_pinyin_dict.py` (requires `jieba` and `pypinyin`).

## Fonts and icons

The clone uses system fonts (Roboto / Noto Sans SC / PingFang SC / SF Pro) and
Material Symbols / SF Symbols. No official MiSans font or `oimeui2023` icon font
from the target APK is redistributed.

## Trademark

“豆包” and “豆包输入法” are trademarks of their respective owner. This project
is an unofficial, non-commercial interoperability study and clean-room clone.
