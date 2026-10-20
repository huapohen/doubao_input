# 豆包输入法（iOS 复刻）

净室（clean-room）实现：**SwiftUI 主 App + 真实 UIKit 键盘扩展**。  
标识：`com.huapohen.doubaoinput.ios` / 扩展 `com.huapohen.doubaoinput.ios.keyboard`。  
最低系统：iOS 15.0；通用 iPhone + iPad。**非官方复刻，与豆包官方无隶属关系。**

本项目不包含官方 APK/IPA、DEX/SO、皮肤 XML、字体、图片、音频、Lottie、私有词典或官方源码。
拼音数据来自 `clones/shared/data/pinyin_dict.json`（jieba + pypinyin，MIT-derived，33,500 条），
已复制到 `Shared/pinyin_dict.json` 并同时打包进 App 与键盘扩展。

---

## 1. 构建

前置：Xcode 27.1（本机 `/Applications/Xcode.app`）、iOS 26.5 Simulator、Ruby 的 `xcodeproj` gem。

```bash
cd clones/ios_native
gem install --user-install xcodeproj --no-document   # 已安装 1.28.1 时跳过

# 重新生成工程（会 glob 所有源码；新增/删除 Swift 文件后运行一次）
ruby scripts/generate_project.rb

# iPhone 17 模拟器构建（6BBA0111-7B13-4830-9DB1-D651664F4381）
xcodebuild -project DoubaoInput.xcodeproj -scheme DoubaoInput \
  -sdk iphonesimulator \
  -destination 'platform=iOS Simulator,id=6BBA0111-7B13-4830-9DB1-D651664F4381' \
  -derivedDataPath build/DerivedData clean build
```

产物：

```
build/DerivedData/Build/Products/Debug-iphonesimulator/DoubaoInput.app
└── PlugIns/DoubaoKeyboard.appex     # bundle id: com.huapohen.doubaoinput.ios.keyboard
```

安装 / 启动：

```bash
xcrun simctl install 6BBA0111-7B13-4830-9DB1-D651664F4381 \
  build/DerivedData/Build/Products/Debug-iphonesimulator/DoubaoInput.app

xcrun simctl launch 6BBA0111-7B13-4830-9DB1-D651664F4381 \
  com.huapohen.doubaoinput.ios
```

iPad Pro 13-inch（M5）使用同一 universal 产物：

```bash
xcrun simctl install 833B0941-E1E7-4AE0-B7BA-F5B9D7A774E9 \
  build/DerivedData/Build/Products/Debug-iphonesimulator/DoubaoInput.app
xcrun simctl launch 833B0941-E1E7-4AE0-B7BA-F5B9D7A774E9 \
  com.huapohen.doubaoinput.ios
```

### 截图 / 调试启动参数

用于证据截图的参数（正常运行时不需要）：

```bash
# 指定初始页面，并补全首次运行状态
xcrun simctl launch <UDID> com.huapohen.doubaoinput.ios -route keyboardDemo

# 全新安装状态（下一次启动为引导页）
xcrun simctl launch <UDID> com.huapohen.doubaoinput.ios -reset -route onboarding

# 强制主题 / 键盘类型 / 单手模式（仅本次进程）
... -route home -theme dark
... -route keyboardDemo -kbType pinyin9
... -route keyboardDemo -oneHand left

# 键盘面板自动打开（仅截图/QA）
... -route keyboardDemo -kbPanel emoji
```

`Route.rawValue` 即 `-route` 取值：`home, voiceSettings, keyboardTypes, layout, ...`
（全部见 `DoubaoInput/Navigation.swift`）。

---

## 2. 启用键盘扩展

1. 先打开一次 App，确保扩展随 App 安装。
2. 系统「设置 → 通用 → 键盘 → 键盘 → 添加新键盘」。
3. 选择 **豆包输入法（iOS 复刻）**，建议允许「完全访问」（用于读取 App Group 中的剪切板/词库）。
4. 在任意输入框长按地球键，切换到复刻键盘。

本机验证结果：系统「设置 → 通用 → 键盘 → 键盘」列表中出现 **豆包输入法（iOS 复刻）**（英文、拼音、Emoji 之外的第 4 个键盘），见 `42_settings_keyboards.png`；
`pluginkit` 能列出扩展；iOS 实际启动了扩展进程：

```bash
xcrun simctl spawn 6BBA0111-7B13-4830-9DB1-D651664F4381 \
  pluginkit -m -p com.apple.keyboard-service | grep huapohen
# com.huapohen.doubaoinput.ios.keyboard(1.5.2)
```

系统日志（节选）：

```
DoubaoKeyboard: ViewServices Received request to create view controller:
  class: DoubaoKeyboard.KeyboardViewController
testmanagerd: event = ViewDidAppear; controllerClass = "DoubaoKeyboard.KeyboardViewController"
```

### 无 GUI 模拟器的键盘 QA

Xcode 27 的 headless CoreSimulator 会一直挂载硬件键盘，导致 iOS 不显示软件键盘。
本项目附带一个仅用于 QA 的脚本（调用 CoreSimulator 私有 API），把硬件键盘断开：

```bash
osascript -l JavaScript scripts/disconnect_simulator_keyboard.js \
  6BBA0111-7B13-4830-9DB1-D651664F4381 "$(xcode-select -p)"
```

在没有 Simulator.app 窗口时，可用偏好把扩展加入键盘列表（iPhone 实测有效；iPad 还需
`HardwareKeyboardLastSeen=0`、`AppleKeyboardsExpanded=1`、`KeyboardInputModeUpdateDate`，
然后 respring SpringBoard）：

```bash
SIM=6BBA0111-7B13-4830-9DB1-D651664F4381
xcrun simctl spawn $SIM defaults write NSGlobalDomain AppleKeyboards -array \
  "en_US@sw=QWERTY;hw=Automatic" "zh_Hans-Pinyin@sw=Pinyin-Simplified;hw=Automatic" \
  "emoji@sw=Emoji" "com.huapohen.doubaoinput.ios.keyboard"
xcrun simctl spawn $SIM defaults write com.apple.keyboard.preferences KeyboardLastUsed \
  -string "com.huapohen.doubaoinput.ios.keyboard"
xcrun simctl spawn $SIM defaults write com.apple.keyboard.preferences KeyboardsCurrentAndNext -array \
  "com.huapohen.doubaoinput.ios.keyboard" "com.huapohen.doubaoinput.ios.keyboard" \
  "en_US@sw=QWERTY;hw=Automatic"
xcrun simctl spawn $SIM launchctl kickstart -k system/com.apple.SpringBoard
```

> 这些偏好与私有 API 仅用于无窗口模拟器取证，不进入 App 逻辑，真机仍按上面的系统设置步骤启用。

### 自动组词 / 上屏验证（仅 QA）

为了在没有触摸注入工具的环境中证明扩展的完整管线，`SystemKeyboardTestView` 支持：

```bash
xcrun simctl launch <UDID> com.huapohen.doubaoinput.ios \
  -route systemKeyboardTest -kbAutotest commit
```

App 写入共享默认值 → 扩展在 `viewDidAppear` 后调用 `automationCompose("nihao")` →
读取本地词典候选 → `commitCandidate` → `textDocumentProxy.insertText`。  
这走的正是按键、候选、上屏的同一套代码；**不是**伪造截图。手工点击系统键盘的输入路径
未在本环境验证（没有 Simulator GUI / 触摸注入工具）。

---

## 3. 架构

```
DoubaoInput/                 SwiftUI App（iPhone + iPad）
  Navigation.swift           Route/Router、RootView、双栏 MainShell、PageScaffold
  Onboarding.swift           引导两步、隐私模式、键盘类型选择、协议/权限
  HomeView.swift             主设置、6 张轮播 Banner、全部分组
  InputSettingsViews.swift   键盘类型、双拼、五笔、布局、模糊音、联想、预测、按键反馈、快捷格式
  VoiceViews.swift           SFSpeechRecognizer + AVAudioEngine、语音设置、口令、试说
  ToolViews.swift            剪切板、词库、输入模式、智能输入、权限、互传、电脑版、常用语
  AccountViews.swift         账户、模拟登录/扫码、消息中心
  AIViews.swift              AI 设置（Keychain）、写作/整理/翻译工作台
  HelpViews.swift            帮助 FAQ、本地反馈、关于、开源许可
  KeyboardDemoView.swift     App 内真实键盘 Demo（复用扩展键盘视图）
  SystemKeyboardTestView.swift 系统键盘输入框 + 自动验证
  AIService.swift            OpenAI 兼容 Chat Completions 客户端 + 本地回退
Keyboard/
  KeyboardViewController.swift   UIInputViewController 宿主与 textDocumentProxy 桥接
  Info.plist / Keyboard.entitlements
Shared/
  pinyin_dict.json           33,500 条词典（MIT-derived）
  Settings/                  AppSettings（UserDefaults 写穿）、KeychainStore、共享模型
  Engine/                    PinyinEngine、五笔表、双拼转换、手写识别、本地 AI/繁简
  Keyboard/                  KeyboardRootView、面板、手写画布、主题/尺寸
```

### 状态持久化

- App 与扩展共享 `UserDefaults(suiteName: "group.com.huapohen.doubaoinput")`；
  如果 App Group 不可用则各自回退到标准 defaults（此时扩展无法读取 App 的剪切板/词库）。
- 键名与共享规格一致：`onboarding_done`、`privacy_mode`、`keyboard_type`、`theme_mode`、
  `fuzzy_*`、`prediction_*`、`key_*`、`voice_*`、`clipboard_*`、`personal_lexicon`、
  `common_phrases`、`custom_toolbar`、`ai_base_url`、`ai_model` 等。
- 所有设置修改立即写穿；主题在 RootView 上通过 `preferredColorScheme` 即时生效。

### 输入引擎

- 内存索引：全拼 compact → 词条、简拼 → 词条、T9 数字 → 词条、排序键数组支持前缀二分。
- 排序：词频 + 多字加权 + MRU（`mru_words`）+ 个人词库优先；`blocked_words` 支持删除候选。
- 模糊音：可分别选择声母/韵母/音节；生成规范化索引并缓存。
- 9 键：T9 前缀匹配 + 简拼；26 键：全拼/简拼/前缀 + 部分音节回退。
- 双拼：小鹤/自然码键位表（演示级）；五笔：约 250 个常用字的 86 版码表 + 拼音混输。
- 手写：48×48 栅格归一化 + 16×16 墨迹直方图余弦相似度；覆盖常用字/数字，属演示级。

### 键盘扩展功能

- 26 键：QWERTY、候选栏（9/页、翻页）、拼音组合、shift 单击/双击、退格长按连删、
  空格上屏首选、`中/英`、`123`/符号、工具栏、长按字母气泡（大小写/数字/符号）、
  字母上滑数字/符号。
- 9 键：T9 数字键、左侧自定义符号列、重输、长按数字、候选。
- 手写画布、笔画五键、双拼、五笔。
- 工具栏：工具箱（16 项）、语音浮层、剪切板、表情/颜文字、常用语、键盘切换、
  单手、键盘高度、翻译、智能整理、AI 离线模板、繁简、收起。
- 主题浅色/深色；iPad 高度 360+、内容最大宽度 960；单手左右偏移；高度 250–420。

### AI / 语音

- AI：`POST {baseURL}/chat/completions`，`Authorization: Bearer`，`model`，`messages`，
  `stream:false`，20 s 超时；401/429/5xx/网络错误均映射并可重试。
- API Key **仅在运行时**输入，保存在 iOS Keychain（`KeychainStore`）。也可用构建/运行环境变量
  `DEEPSEEK_API_KEY`（优先级：用户设置 > 环境变量）；仓库内没有任何 Key。
- 无 Key 或基础输入模式：写作/整理/翻译全部走本地规则与模板，并在 UI 标注「离线示例」。
- 语音：App 内 `SFSpeechRecognizer` + `AVAudioEngine`，真实请求麦克风/语音识别权限；
  失败/模拟器不可用时显示明确错误与「离线示例」。键盘扩展内语音浮层为离线示例（见限制）。

### 可替换后端契约

```http
POST /v1/asr            multipart audio -> {text, confidence, segments[]}
POST /v1/ai/organize    {text, mode} -> {text}
POST /v1/ai/write       {action, text, context} -> {text} 或 SSE
POST /v1/ai/translate   {text, from, to} -> {text}
POST /v1/clipboard/sync {deviceId, items[]} -> {items[]}
GET  /v1/config         -> {features, limits}
Authorization: Bearer <token>
```

App 的 AI Base URL 与模型可在「设置 → AI 服务」中改；默认 `https://api.deepseek.com` /
`deepseek-chat`。客户端不硬编码官方输入法后端域名，也不调用官方鉴权。

---

## 4. 验证结果

| 项目 | 命令 / 方法 | 结果 |
|---|---|---|
| iPhone 构建 | 上面 `xcodebuild ... clean build` | **BUILD SUCCEEDED** |
| iPad 构建/运行 | 同一产物安装到 `833B0941...` 并 launch | 成功，7 张 iPad 截图 |
| 扩展注册 | `pluginkit -m -p com.apple.keyboard-service` | `com.huapohen.doubaoinput.ios.keyboard(1.5.2)` |
| 加入键盘列表 | `AppleKeyboards` 偏好 + respring；设置页 | 列表包含 **豆包输入法（iOS 复刻）**，见 `42_settings_keyboards.png` |
| 系统键盘加载 | 聚焦系统输入框 + 日志 | `DoubaoKeyboard.KeyboardViewController`，`ViewDidAppear` |
| 真实中文上屏 | `-kbAutotest commit` → 扩展 `textDocumentProxy` | 输入框显示 **你好**（2 字符），见 `33_keyboard_system_committed.png` |
| 候选栏 | 同一路径 | `nihao` → 你好/你/泥/尼/拟/逆，见 `32_keyboard_system_candidates.png` |
| iPad 扩展 | 同一路径 | 扩展以 360+ pt 高度渲染，见 `ipad_07_system_keyboard.png` |
| App Group | App 写 `keyboard_autotest_mode`，扩展读取并执行 | 成功（否则不会自动组词/上屏） |

### 截图索引（49 张，`screenshots/`）

`01_onboarding`、`02_privacy`、`03_home`、`04_voice_settings`、`05_voice_actions`、
`06_keyboard_types`、`07_double_pinyin`、`08_wubi`、`09_layout`、`10_fuzzy`、
`11_association`、`12_prediction`、`13_key_feedback`、`14_quick_format`、`15_clipboard`、
`16_lexicon`、`17_input_mode`、`18_permissions`、`19_super_transfer`、`20_account`、
`21_login`、`22_messages`、`23_desktop`、`24_help`、`25_about`、`26_ai_settings`、
`27_ai_writing`、`28_smart_organize`、`29_translate`、`30_keyboard_demo`、
`31_system_keyboard_test`、`32_keyboard_system_candidates`、`33_keyboard_system_committed`、
`34_keyboard_9key`、`35_keyboard_handwriting`、`36_keyboard_wubi`、`37_keyboard_emoji_panel`、
`38_theme_dark`、`39_keyboard_toolbox`、`40_keyboard_onehand`、`41_keyboard_voice_overlay`、
`42_settings_keyboards`（系统设置中的键盘列表）。  
iPad：`ipad_01_home`、`ipad_02_keyboard_types`、`ipad_03_layout`、`ipad_04_account`、
`ipad_05_keyboard_demo`、`ipad_06_ai_writing`、`ipad_07_system_keyboard`。

---

## 5. 已知限制（诚实说明）

- **系统键盘手工点击**：当前环境没有 Simulator GUI / 触摸注入工具；扩展的布局、候选、
  上屏通过 QA 自动管线验证（同一 `textDocumentProxy` 路径），未进行人工逐键点击。
- **键盘内语音**：扩展无法可靠地进行长时录音/权限请求，语音浮层为离线示例；
  完整语音在 App 内使用系统 `SFSpeechRecognizer`。模拟器上的真实识别结果 **[未验证]**。
- **云端 AI**：未使用真实 Key 进行付费调用测试；请求构造、错误映射、Keychain 保存和
  本地回退已实现。无 Key 的本地结果可运行，但未逐场景截图。
- **手写识别**：净室模板匹配，仅覆盖约 300 个常用字/数字，手写准确率有限，不保证连笔。
- **五笔 / 双拼**：五笔为约 250 字演示码表；双拼为小鹤/自然码键位演示，非全量词库行为。
- **9 键**：使用 T9 前缀 + 简拼，未实现官方级多音节动态规划/云候选，排序为净室实现。
- **离线语音下载**：仅模拟进度与状态，不包含官方 177 MB 模型。
- **短信验证码填充**：iOS 不允许第三方键盘读取短信，相关 UI 仅作说明；只能依赖系统建议。
- **悬浮键盘 / 分屏浮窗**：系统键盘扩展不支持真正的浮窗拖动；已实现单手与高度调节。
- **横屏**：已配置全部方向并使用自适应尺寸（`KeyboardMetrics` 横屏降高、页面最大宽度 720），
  但未在本环境实际旋转截图 **[未验证]**。
- **App Group 真机**：需要在开发者账号中为 App 与扩展启用 `group.com.huapohen.doubaoinput`
  capability；模拟器构建已可用。若不可用会回退到各自 defaults（扩展读不到 App 数据）。
- **官方后端不可用**：本复刻版不请求豆包官方接口，不包含官方鉴权、扫码登录或私有词典。

---

## 6. 许可

- 本仓库代码：原创净室实现。
- 拼音数据：jieba + pypinyin（MIT），再分发说明见 `clones/shared/LICENSES.md`。
- 图标：Apple SF Symbols（仅在 Apple 平台使用）。
- 未使用官方商标作为自有 Logo；“豆包”仅用于说明复刻对象。
