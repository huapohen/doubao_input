# 豆包输入法（复刻）— Flutter 通用版

> 净室行为复刻，非官方产品，与字节跳动及其关联公司无任何隶属或授权关系。

- applicationId / bundleId：`com.huapohen.doubaoinput.flutter`
- 显示名：豆包输入法（复刻）
- Flutter 3.47.2 / Dart 3.13.2
- Android minSdk 26 / targetSdk 36；iOS 15+
- 目录：`clones/flutter`

本实现只使用自写 UI 代码、系统图标、以及 `clones/shared/data/pinyin_dict.json`
（jieba + pypinyin，MIT，33,500 条）。不包含官方 APK/DEX/SO、皮肤 XML、字体、
图片、音频、Lottie 或私有词典。仓库中不包含任何 API Key。

## 1. 构建与运行

```bash
cd clones/flutter
/Users/lwblx/development/flutter/bin/flutter pub get
/Users/lwblx/development/flutter/bin/flutter analyze
/Users/lwblx/development/flutter/bin/flutter test
```

### Android

```bash
/Users/lwblx/development/flutter/bin/flutter build apk --debug
adb -s emulator-5560 install -r build/app/outputs/flutter-apk/app-debug.apk
adb -s emulator-5560 shell am start -n com.huapohen.doubaoinput.flutter/.MainActivity
```

如果本机 `~/.gradle/init.gradle` 注入了项目级 maven 仓库，Flutter 的
`flutter-plugin-loader` 可能报 `PREFER_SETTINGS` 冲突。可用隔离的 Gradle home
绕过（不修改项目）：

```bash
mkdir -p /tmp/doubao_flutter_gradle
ln -sfn ~/.gradle/caches /tmp/doubao_flutter_gradle/caches
ln -sfn ~/.gradle/wrapper /tmp/doubao_flutter_gradle/wrapper
GRADLE_USER_HOME=/tmp/doubao_flutter_gradle \
  /Users/lwblx/development/flutter/bin/flutter build apk --debug
```

项目固定 AGP 8.11.1 + Gradle 8.14.3 + Kotlin 2.0.0，以兼容当前 Flutter 3.47
工具链；Flutter 会提示“即将停止支持”，但构建通过。

### iOS（模拟器）

```bash
/Users/lwblx/development/flutter/bin/flutter build ios --simulator --no-codesign
xcrun simctl install <UDID> build/ios/iphonesimulator/Runner.app
xcrun simctl launch <UDID> com.huapohen.doubaoinput.flutter
```

可使用 `doubaoinput://` 深链直接打开页面：

```bash
xcrun simctl openurl <UDID> "doubaoinput://keyboard?composing=nihao"
# 或在自动化环境中（避免系统 “Open in app?” 弹窗）：
SIMCTL_CHILD_DOUBAO_DEEPLINK="doubaoinput://keyboard?panel=emoji" \
  xcrun simctl launch <UDID> com.huapohen.doubaoinput.flutter
```

支持的路由：`/settings`、`/keyboard?panel=emoji|clipboard|ai|toolbox|translate|organize|handwriting|onehand|adjust|keyboard|phrases|toolbar|candidates`、
`/layout`、`/voice-settings`、`/fuzzy`、`/account`、`/about` 等（host 即路由名）。

## 2. 架构

```text
lib/
  main.dart              加载设置与 33.5k 词典后启动
  app.dart               MaterialApp、路由、RootGate（Splash→引导→隐私→选键盘→主页）
  theme.dart             规格令牌（#4F84FF、#F2F7FF、圆角 18/10/999）+ 深浅色
  core/
    app_state.dart       SharedPreferences 单一状态源；所有开关/列表/账号/密钥
    pinyin_engine.dart   全拼前缀/简拼/组合/T9/模糊拼音/MRU/删除词/联想
    handwriting.dart     离屏字形模板 + 笔迹栅格覆盖率识别（56 个常用字/数字）
    stroke_engine.dart   五笔画前缀表（约 60 字）
    ai_service.dart      OpenAI 兼容 Chat Completions + 全部离线回退
    local_tools.dart     繁简映射、离线翻译、文字整理、写作模板
    speech_service.dart  系统语音识别（speech_to_text）
    deep_link.dart       `doubaoinput://` 路由桥
    platform_bridge.dart 打开输入法设置/选择器/App 设置
  ui/
    onboarding.dart      两步引导、隐私两种模式、六种键盘选择
    settings_home.dart   账号头、键盘体验卡、6 张自动轮播 banner、全部设置行
    pages/               所有设置子页（语音/键盘/隐私/账户/工具）
    keyboard/            键盘 demo：controller、26/9/笔画/手写视图、9 个面板、
                         语音浮层、AI 写作/聊天、悬浮/单手/调节
android/app/src/main/kotlin/.../
  MainActivity.kt        MethodChannel（系统设置、IME 状态）+ 深链
  DoubaoImeService.kt    真实系统 IME（候选栏 + 原生键盘 + InputConnection）
  ImeKeyboardView.kt     程序化 26 键/数字键盘
  PinyinImeEngine.kt     原生词典索引（与服务共享 assets/pinyin_dict.json）
```

### 本地输入引擎

- 载入 `assets/data/pinyin_dict.json`；按拼音排序后二分前缀搜索。
- 全拼前缀、简拼精确、单字组合、T9 数字串、双拼还原、五笔码表。
- 排序：词频 × 长度 × MRU × 精确匹配加成；上屏学习写入最近使用；删词写入黑名单。
- 模糊拼音：声母 6 / 韵母 9 / 音节 2，生成最多 24 个查询变体。
- 候选栏显示实测查询耗时（通常 1–5 ms，首次 T9 扫描约十几 ms）。
- 个人词库优先级最高；`learned_words` 保留最近 200 条。

### 键盘体验

- 26 键：长按字母气泡（大小写/数字/符号）、上滑数字符号、Shift 单击/双击大写锁定、
  退格长按连删、空格长按语音、中英切换、英文前缀联想、双击空格句号、回车发送开关、
  候选 9 个/页、长按候选查看详情/删词、分词键、繁简、数字/符号布局。
- 9 键：T9 候选、自定义侧边符号、重输、长按数字直输、符号/123/空格/中英/换行。
- 手写：Pointer 笔迹、撤销/清空/识别、650 ms 自动识别、候选插入、手写找字。
- 笔画：横竖撇捺折 + 通配，前缀候选。
- 双拼：小鹤/自然码还原后走本地词典；五笔：编码提示、拼音混输、四码唯一/第五码。
- 工具条 13 项（可定制两页、拖拽排序、左右吸附、恢复默认）；工具箱 8+5 项。
- 面板：Emoji/表情图/颜文字、剪切板（本机/跨设备/拆词/图片占位）、常用语增删改、
  翻译、智能整理、AI 写作/聊天、键盘选择、手写找字、单手/悬浮、键盘调节、候选详情。
- 语音浮层：真实申请麦克风/语音识别；权限拒绝、无服务、超时、空结果均有明确提示，
  并提供明确标注的演示结果；结果可编辑、整理、插入、触发语音口令。
- 单手、悬浮（拖动/贴边/缩放/恢复）、键盘高度/底部间距/候选字号均有独立持久化。
- 平板：设置页最大 780 dp 居中，键盘最大 960 dp 居中；横屏降低键盘占比；旋转不崩溃。

### Android 系统输入法

同一 APK 内提供真实的 `InputMethodService`（原生 Kotlin View，非 FlutterEngine），
与 App 共用词典资源与 FlutterSharedPreferences 中的声音/振动/回车设置。

```bash
adb -s emulator-5560 shell ime list -s | grep doubaoinput
adb -s emulator-5560 shell ime enable com.huapohen.doubaoinput.flutter/.DoubaoImeService
adb -s emulator-5560 shell ime set com.huapohen.doubaoinput.flutter/.DoubaoImeService
# App 内「更多 → 系统输入法测试」或任意系统搜索框输入
adb -s emulator-5560 shell am start -a android.intent.action.VIEW \
  -d "doubaoinput://ime-test" com.huapohen.doubaoinput.flutter
```

系统 IME 支持 26 键拼音、简拼、候选上屏、退格长按、空格、中英、数字/符号布局、
回车/发送和收起；系统 IME 不包含 9 键/手写/双拼（这些在 App 内键盘体验中完整提供）。

## 3. AI 服务

设置 → AI 服务配置：

- Base URL：默认 `https://api.deepseek.com`
- Model：默认 `deepseek-chat`，可改为 `deepseek-flash` / `deepseek-reasoner` 或任意兼容模型
- API Key：密码框，保存到平台安全存储（Keychain / EncryptedSharedPreferences）；
  不可用时退回本地偏好并显示警告
- 测试连接：发送 `ping`，只期待 `OK`

优先级：用户设置 > `--dart-define=DEEPSEEK_API_KEY=...` > 空。
**不要**在构建命令、CI 或仓库中写入真实 Key；交付 APK/IPA 未包含 Key。

调用格式（非流式，20 s 超时）：

```http
POST {base}/v1/chat/completions
Authorization: Bearer <user key>
{"model": "...", "messages": [...], "temperature": 0.7, "max_tokens": 900, "stream": false}
```

错误映射：401/403 鉴权、429 限流、5xx 服务端、超时、网络不可用；错误可重试，
UI 显示原因。无 Key / 基础模式：全部走本地模板，并标注「离线示例」。

### 可替换后端契约（README 约定，不作为官方接口）

```http
POST /v1/asr            multipart audio -> {text, confidence, segments[]}
POST /v1/ai/organize    {text, mode} -> {text}
POST /v1/ai/write       {action, text, context} -> {text} 或 SSE
POST /v1/ai/translate   {text, from, to} -> {text}
POST /v1/clipboard/sync {deviceId, items[]} -> {items[]}
GET  /v1/config         -> {features, limits}
Authorization: Bearer <token>
```

客户端不硬编码任何官方域名作为回退；默认离线可用。

## 4. 持久化键

`onboarding_done`, `privacy_mode`, `keyboard_type`, `theme_mode`, `input_mode`,
`fuzzy_enabled`, `fuzzy_initials`, `fuzzy_finals`, `fuzzy_syllables`,
`association_enabled`, `prediction_emoji`, `prediction_image`, `prediction_kaomoji`,
`key_sound`, `key_vibrate`, `key_vibrate_level`, `key_bubble`, `quick_space`,
`quick_capitalize`, `quick_double_space_period`, `clipboard_candidate`, `clipboard_history`,
`voice_smart_organize`, `voice_punctuation`, `voice_filler`, `voice_offline`,
`voice_action_enabled`, `voice_actions`, `candidate_font_size`, `pinyin_location`,
`enter_send`, `one_hand`, `floating`, `keyboard_height`, `custom_toolbar`,
`common_phrases`, `personal_lexicon`, `clipboard_items`, `ai_base_url`, `ai_model`,
`ai_key`（安全存储）, `account_logged_in`, `account_name`, `super_transfer_enabled`,
`device_id`, `traditional`, `learned_words`, `deleted_words`, plus UI tuning keys.

所有修改立即写入并重建 UI；重启保持。

## 5. 测试与验证

已执行（2026-10-20）：

```text
flutter analyze                          # 0 errors
flutter test                             # 4 tests passed
flutter build ios --simulator --no-codesign   # ✓ Built Runner.app
flutter build apk --debug                # 结果见交付报告 / dist
```

- AI 客户端：`test/ai_client_test.dart` 用本地 `HttpServer` 模拟 OpenAI 兼容服务，
  校验 `Authorization: Bearer`、model、messages 与响应解析；无 Key 时校验本地回退。
- 未使用真实 DeepSeek Key 构建；Key 只在运行时由用户输入。
- iOS：iPhone 17e（`8FD1EDF8-DF9A-4FA0-9B98-985FA601ED68`）实机安装运行；
  通过 `SIMCTL_CHILD_DOUBAO_DEEPLINK` 驱动状态截图。iPad 截图见下。
- Android：emulator-5560 安装运行；系统 IME 通过 `ime enable/set` 与真实
  `InputConnection` 测试。

## 6. 已知限制

- 不连接豆包官方后端、账号、ASR、云候选、表情或超级互传服务；这些入口为本地实现。
- iOS 版不包含键盘扩展（Keyboard Extension）；iOS 系统键盘需另建扩展 target。
  App 内键盘体验完整可用。
- Android 系统 IME 只有 26 键拼音（含简拼/候选/删除/中英/数字），不包含 9 键、手写、
  双拼、五笔；这些在 App 内 demo 中完整提供。
- 手写为 56 个常用字/数字的模板匹配，不是通用手写模型；笔画约 60 字；五笔约 70 条
  常用码。均为演示级覆盖。
- AI 使用非流式请求；未实现 SSE 增量渲染。语音、AI 的离线回退为明确标注的本地结果。
- 剪贴板图片仅提供占位项；跨设备互传为本机模拟。
- 官方后端/私有协议不可获得，因此候选排序、语音体验、表情内容与官方不同。
- Android 构建使用 AGP 8.11.1 / Gradle 8.14.3（Flutter 提示即将停止支持）；
  iOS 真机签名未配置，仅验证模拟器构建。

## 7. 截图

`clones/flutter/screenshots/`：Android 15+、iPhone 8+、iPad 3 张，覆盖引导、隐私、
主页、26/9/手写键盘、工具箱、表情、AI、布局、账户、关于、深色、平板等状态。
