# 三端复刻验证矩阵

> 状态：`✅` 已运行验证 · `◐` 已实现未验证 · `—` 未实现/不适用 · `[U]` 受环境限制  
> 验证以实际构建、安装、点击/输入/截图为准，不以代码存在为准。最后更新：2026-10-20。

| # | 功能/页面 | 原版证据 | Flutter | Android 原生 | iOS 原生 | 备注 |
|---:|---|---|:---:|:---:|:---:|---|
| 1 | 首次引导两步 | 01/57/58 |  |  |  |  |
| 2 | 隐私声明/智能vs基础 | 02/21 |  |  |  |  |
| 3 | 首次键盘类型选择 | 25 |  |  |  |  |
| 4 | 主设置全部行 | 107 |  |  |  |  |
| 5 | 语音设置 | 10/11 |  |  |  |  |
| 6 | 语音口令 | 代码/布局 |  |  |  |  |
| 7 | 键盘类型六卡片 | 12 |  |  |  |  |
| 8 | 双拼（小鹤/自然码） | 13 |  |  |  |  |
| 9 | 五笔设置 | 14 |  |  |  |  |
| 10 | 布局与显示（含滑杆/符号） | 15/16/17 |  |  |  |  |
| 11 | 模糊拼音 | 75/76 |  |  |  |  |
| 12 | 智能联想 | 77 |  |  |  |  |
| 13 | 输入预测类型 | 80 |  |  |  |  |
| 14 | 按键反馈 | 85/86 |  |  |  |  |
| 15 | 快捷格式输入 | 87 |  |  |  |  |
| 16 | 超级互传 | 92 |  |  |  |  |
| 17 | 剪切板设置/历史 | 65/93 |  |  |  |  |
| 18 | 词库管理 CRUD | 96 |  |  |  |  |
| 19 | 输入模式/智能输入 | 97/99 |  |  |  |  |
| 20 | 系统权限页 | 102 |  |  |  |  |
| 21 | 账号/登录/消息中心 | 108/109/110 |  |  |  |  |
| 22 | 电脑版/帮助/关于 | 103–106 |  |  |  |  |
| 23 | 26 键布局/上滑/长按 | 26/33 |  |  |  |  |
| 24 | 26 键拼音候选/上屏 | 27/29/31 |  |  |  |  |
| 25 | 9 键布局/候选 | 45 |  |  |  |  |
| 26 | 手写画布/识别 | 51 |  |  |  |  |
| 27 | 笔画键盘 | 设置/皮肤 |  |  |  |  |
| 28 | 工具箱 8+项 | 34 |  |  |  |  |
| 29 | 表情三 Tab | 38/39/40 |  |  |  |  |
| 30 | 键盘切换面板 | 44 |  |  |  |  |
| 31 | 剪贴板首次授权/列表 | 65 |  |  |  |  |
| 32 | 常用语 CRUD | 布局/设置 |  |  |  |  |
| 33 | 翻译 | 工具栏 |  |  |  |  |
| 34 | 智能整理 | 布局/接口 |  |  |  |  |
| 35 | AI 写作/改写/总结 | 布局/接口 |  |  |  |  |
| 36 | 语音浮层/识别/错误 | 53/54 |  |  |  |  |
| 37 | 单手/悬浮/高度调节 | 设置/皮肤 |  |  |  |  |
| 38 | 主题跟随/浅/深 | 布局设置 |  |  |  |  |
| 39 | 繁简切换 | 工具栏 |  |  |  |  |
| 40 | 平板/横屏 | tablet_* |  |  |  |  |
| 41 | 系统 IME 可启用 | Android 设置 | — |  | — | Flutter 可选 |
| 42 | 系统键盘扩展可添加 | iOS 设置 | — | — |  |  |
| 43 | AI 真实调用（有 Key） | 后端 |  |  |  | 不记录 Key |
| 44 | 无 Key 离线回退 | 设计 |  |  |  |  |

## 验证命令（示例）

```bash
# Android 原生
adb -s emulator-5560 install -r clones/android_native/app/build/outputs/apk/debug/app-debug.apk
adb -s emulator-5560 shell am start -n com.huapohen.doubaoinput.android/.settings.MainActivity
adb -s emulator-5560 shell ime enable com.huapohen.doubaoinput.android/.ime.DoubaoImeService
adb -s emulator-5560 shell ime set com.huapohen.doubaoinput.android/.ime.DoubaoImeService

# Flutter Android
adb -s emulator-5560 install -r clones/flutter/build/app/outputs/flutter-apk/app-debug.apk
adb -s emulator-5560 shell am start -n com.huapohen.doubaoinput.flutter/.MainActivity

# iOS 模拟器
xcrun simctl install booted clones/ios_native/build/DerivedData/Build/Products/Debug-iphonesimulator/DoubaoInput.app
xcrun simctl launch booted com.huapohen.doubaoinput.ios
```

> 构建/安装结果、截图数量、失败项与修复记录见 `progress.md` 与各 clone 的 README。
