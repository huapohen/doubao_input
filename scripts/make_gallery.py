# -*- coding: utf-8 -*-
import os, json
from PIL import Image

ROOT = '/Users/lwblx/huapohen/agent/rea/doubao_input'
SRC = os.path.join(ROOT, 'evidence/runtime/screenshots')
OUT = os.path.join(ROOT, 'reports/assets/screens')
os.makedirs(OUT, exist_ok=True)

GROUPS = {
    'onboarding': ['01_launcher', '02_ime_system_settings', '21_privacy', '57_guide_enable',
                   '58_guide_step2', '59_after_ime_switch'],
    'settings': ['07_settings_main', '09_main_top', '107_main_top2', '10_voice_settings',
                 '11_voice_settings_bottom', '12_keyboard_types', '13_shuangpin', '14_wubi',
                 '15_layout_top', '16_layout_mid', '17_layout_bottom', '71_fuzzy_top',
                 '73_fuzzy_enabled', '75_fuzzy_on', '76_fuzzy_on_bottom', '77_association',
                 '80_input_recommend', '85_key_feedback', '86_key_feedback_bottom',
                 '87_quick_format', '92_super_transfer', '93_clipboard_settings',
                 '96_lexicon', '97_input_mode', '99_smart_input', '102_system_permissions',
                 '103_help', '104_help_loaded', '105_about', '106_desktop', '108_account',
                 '109_login', '110_login_page'],
    'keyboard': ['25_keyboard_26', '26_keyboard_26_active', '27_keyboard_typing',
                 '28_pinyin_nihao', '29_pinyin_nihao_keyevents', '30_candidate_committed',
                 '31_pinyin_onscreen', '33_keyboard_clean', '34_toolbox_open',
                 '38_emoji_panel', '39_emoji_stickers', '40_kaomoji',
                 '41_keyboard_switcher', '44_keyboard_switcher', '45_keyboard_9key',
                 '46_handwriting', '48_handwriting_active', '51_handwriting_keyboard',
                 '53_voice_overlay', '54_voice_overlay_after', '63_26key_ready',
                 '65_clipboard'],
    'tablet': ['tablet_03_settings', 'tablet_05_keyboard', 'tablet_06_keyboard26',
               'tablet_07_toolbox', 'tablet_08_switcher', 'tablet_09_9key'],
}

LABELS = {
    '01_launcher': '首次安装：启用输入法引导',
    '02_ime_system_settings': '隐私与输入模式声明',
    '21_privacy': '隐私声明（干净模拟器）',
    '57_guide_enable': '引导第一步',
    '58_guide_step2': '第二步：打开输入法切换器',
    '59_after_ime_switch': '切换后进入设置',
    '07_settings_main': '主设置页',
    '09_main_top': '主设置页（顶部）',
    '107_main_top2': '主设置页（完整头部与 banner）',
    '10_voice_settings': '语音转文字设置',
    '11_voice_settings_bottom': '语音设置底部：离线语音/其他',
    '12_keyboard_types': '键盘类型选择',
    '13_shuangpin': '双拼方案（小鹤/自然码）',
    '14_wubi': '五笔设置',
    '15_layout_top': '布局与显示（上）',
    '16_layout_mid': '布局与显示（中）',
    '17_layout_bottom': '布局与显示（下）',
    '71_fuzzy_top': '模糊拼音（关闭态）',
    '73_fuzzy_enabled': '模糊拼音（开启态）',
    '75_fuzzy_on': '模糊拼音：声母/韵母',
    '76_fuzzy_on_bottom': '模糊拼音：音节',
    '77_association': '智能联想开关',
    '80_input_recommend': '输入预测类型',
    '85_key_feedback': '按键反馈',
    '86_key_feedback_bottom': '按键反馈底部',
    '87_quick_format': '快捷格式输入',
    '92_super_transfer': '超级互传',
    '93_clipboard_settings': '剪切板设置',
    '96_lexicon': '词库管理',
    '97_input_mode': '输入模式与信息保护',
    '99_smart_input': '智能输入设置',
    '102_system_permissions': '系统权限设置',
    '103_help': '帮助与反馈（加载中）',
    '104_help_loaded': '帮助与反馈（远程客服中心）',
    '105_about': '关于（1.5.2 / build）',
    '106_desktop': '电脑版下载页',
    '108_account': '我的账号页',
    '109_login': '登录底部弹层',
    '110_login_page': '豆包账号登录（加载中）',
    '25_keyboard_26': '首次键盘类型选择浮层',
    '26_keyboard_26_active': '26 键键盘（工具条/语音条）',
    '27_keyboard_typing': '26 键候选与工具条',
    '28_pinyin_nihao': '拼音输入状态',
    '29_pinyin_nihao_keyevents': '候选栏（你好/美女）',
    '30_candidate_committed': '候选上屏',
    '31_pinyin_onscreen': '真实组合输入态',
    '33_keyboard_clean': '26 键键盘干净态（点击说话）',
    '34_toolbox_open': '工具箱第一页',
    '38_emoji_panel': 'Emoji 面板',
    '39_emoji_stickers': '表情图 Tab（后端资源缺失时空白）',
    '40_kaomoji': '颜文字 Tab',
    '41_keyboard_switcher': '键盘切换面板（9键选中）',
    '44_keyboard_switcher': '键盘切换面板（26键选中）',
    '45_keyboard_9key': '9 键键盘',
    '46_handwriting': '手写键盘布局',
    '48_handwriting_active': '手写键盘（切换后）',
    '51_handwriting_keyboard': '手写画布',
    '53_voice_overlay': '语音浮层（错误：请连接网络）',
    '54_voice_overlay_after': '语音浮层（错误保持）',
    '63_26key_ready': '26 键键盘（恢复）',
    '65_clipboard': '剪切板首次开启授权',
    'tablet_03_settings': '平板：设置页（居中单列）',
    'tablet_05_keyboard': '平板：首次键盘类型浮窗',
    'tablet_06_keyboard26': '平板：26 键悬浮键盘',
    'tablet_07_toolbox': '平板：悬浮工具箱',
    'tablet_08_switcher': '平板：悬浮键盘切换',
    'tablet_09_9key': '平板：9 键悬浮键盘',
}

manifest = []
for group, names in GROUPS.items():
    for name in names:
        path = os.path.join(SRC, name + '.png')
        if not os.path.exists(path):
            print('MISSING', path)
            continue
        im = Image.open(path).convert('RGB')
        w, h = im.size
        tw = 704
        th = int(h * tw / w)
        im.resize((tw, th), Image.LANCZOS).save(
            os.path.join(OUT, name + '.webp'), 'WEBP', quality=82, method=6)
        manifest.append({'file': name + '.webp', 'group': group,
                         'label': LABELS.get(name, name), 'w': tw, 'h': th})

with open(os.path.join(ROOT, 'reports/assets/screens.json'), 'w', encoding='utf-8') as f:
    json.dump(manifest, f, ensure_ascii=False, indent=2)
print('screens', len(manifest), 'bytes',
      sum(os.path.getsize(os.path.join(OUT, m['file'])) for m in manifest))
