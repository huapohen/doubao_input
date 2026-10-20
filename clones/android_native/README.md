# 豆包输入法（原生复刻）— Android Native Clone

非官方、净室实现（clean-room）的 Android 输入法 + 设置应用，用于互操作性与输入法技术研究。
不包含官方 APK/DEX/SO、皮肤 XML、字体、图片、音频、Lottie 或词典二进制，也不请求豆包官方私有接口。

- 包名：`com.huapohen.doubaoinput.android`
- 显示名：豆包输入法（原生复刻）
- minSdk 26 / targetSdk 36 / compileSdk 36
- Kotlin 2.2.20、AGP 8.11.1、Gradle 8.13、JDK 21
- 手机 + 平板（sw600dp 响应式，设置页居中最大宽度 + 首页 NavigationRail；键盘最大宽度 960dp 居中；横屏缩短键盘高度）

---

## 1. 构建与运行

```bash
cd clones/android_native
./gradlew assembleDebug
# APK: app/build/outputs/apk/debug/app-debug.apk

adb -s <serial> install -r app/build/outputs/apk/debug/app-debug.apk
adb -s <serial> shell ime enable com.huapohen.doubaoinput.android/.ime.DoubaoImeService
adb -s <serial> shell ime set    com.huapohen.doubaoinput.android/.ime.DoubaoImeService
adb -s <serial> shell am start -n com.huapohen.doubaoinput.android/.settings.MainActivity
```

设备上启用步骤：

1. 系统设置 → 系统 → 语言和输入法 → 屏幕键盘 / 管理键盘 → 启用「豆包输入法（原生复刻）」。
2. 输入法选择器中选择它（首次打开 App 的引导页也提供“打开输入法设置”和“弹出输入法选择器”）。
3. 在任意输入框聚焦后即可输入。首次可长按空格或点击工具条“🎤 点击说话”进入语音。

> 部分模拟器在 `adb install -r` 后会把默认输入法重置为 Gboard，重新执行 `ime set` 即可。

### 依赖与离线说明

- 拼音词库 `app/src/main/assets/pinyin_dict.json`（33,500 条，1.3 MB）来自 `clones/shared/data/pinyin_dict.json`，由 jieba/pypinyin（MIT）生成。
- 除 AndroidX / Compose / Material Icons / security-crypto 外无其他运行时依赖。
- 明文 HTTP 只对 `10.0.2.2`、`localhost` 放行（用于本地 AI mock 测试）；其他外部请求必须 HTTPS。

---

## 2. 架构

```
app/src/main/java/com/huapohen/doubaoinput/android/
├── App.kt / core/
│   ├── Prefs.kt            全部设置、MRU、黑名单、侧边栏符号；AI Key 使用 EncryptedSharedPreferences（失败回退）
│   └── Repos.kt            常用语、个人词库、剪贴板、消息、反馈、设备、工具栏 JSON 持久化
├── engine/
│   ├── PinyinEngine.kt     全拼 / 简拼 / T9 / 模糊拼音 / MRU / 联想 / 双拼转换；TreeMap 前缀索引
│   ├── Data.kt             翻译词表、繁简映射、五笔码表、笔画表、手写形状模板
│   └── EmojiData.kt        Emoji、颜文字、表情图分类与最近使用
├── ime/
│   ├── DoubaoImeService.kt InputMethodService；提交/删除/动作、剪贴板、权限、设置路由
│   ├── KeyboardRootView.kt 工具条、候选栏、字号/拼音位置、单手/悬浮、键盘类型状态机
│   ├── KeyboardView.kt     Canvas 自绘键帽、按键/长按/上滑/气泡、声音振动回调
│   ├── KeyboardLayouts.kt  26 键、T9、数字、符号、笔画布局；数字/符号合并、逗句号、中英位置
│   ├── KeyboardPanels.kt   工具箱、键盘选择、Emoji、剪贴板、常用语、翻译、AI 写作、智能整理、
│   │                       键盘调节、单手、定制工具栏（RecyclerView 拖拽）、手写找字、候选详情、语音结果
│   ├── VoiceManager.kt     SpeechRecognizer + 波形浮层 + 错误/权限/示例文本
│   ├── HandwritingPadView.kt 手写画布与停顿识别
│   └── UiUtil.kt           颜色、圆角、Toast、dp
├── ai/AiClient.kt          OpenAI 兼容 Chat Completions；20s 超时、错误映射、离线回退
└── settings/
    ├── MainActivity.kt     Compose 入口（edge-to-edge）
    ├── PermissionProxyActivity.kt  IME 侧麦克风权限代理
    ├── TextInputActivity.kt        IME 面板里的文本编辑（IME 无法编辑自身视图）
    └── ui/                 Compose 设置应用（Theme/Components/Home/Voice/Keyboard/Tools/Account/Privacy/More）
```

### 输入引擎要点

- 启动时后台解析 JSON，建立三套前缀索引：无空格全拼、简拼、T9 数字串；另建首字索引用于联想。
- 候选排序：词频 × 长度/前缀惩罚 + MRU 学习加成；个人词库最高优先；黑名单过滤。
- 模糊拼音：按设置生成替换变体查询并合并；不改变实际拼音串。
- 9 键：数字串直接查 T9 前缀；数字 1 键打开符号，长按输入数字。
- 双拼：小鹤 / 自然码表转换为全拼后复用词库；9 键双拼标注“敬请期待”。
- 五笔：净室整理的 ~140 条常用码表演示，支持编码提示、拼音混输、四码唯一、第五码首选。
- 笔画：35 条常用字笔画序列演示；`?` 为通配。
- 手写：按笔画数量/方向/闭合/宽高比匹配 34 个形状模板；无法识别时提示“换个写法试试”，并提供拼音查字（真实覆盖全词库）。

### 键盘交互

- 26 键：字母上滑数字/符号（可关）、长按气泡、Shift 单击/双击锁定、退格长按连删、空格提交首选、长按空格语音、中/英切换、动作键（搜索/发送/前往/完成/换行）。
- 候选栏：拼音/双拼/五笔/笔画组合态、点击上屏、长按候选详情（上屏/复制/删除该词）、‹ › 滚动、“▾”更多候选（全部/单字）、点拼音串打开分词面板。
- 工具条：工具箱、语音、剪贴板、翻译、表情、常用语、键盘选择、繁简、单手、手写找字、撤销、AI、收起；可定制排序（拖拽）。
- 工具箱 14 项、分两页；每个入口都打开真实面板或执行操作，无占位按钮。
- 单手左/右、悬浮（⠿ 拖动）、键盘高度/底部间距/候选字号滑杆、三维外观切换；均可恢复默认。
- 工具栏“繁简”：有选区时转换选区，无选区时切换后续上屏的繁/简输出。
- 语音结果：原文、编辑、智能整理（AI/离线规则）、插入、发送、复制、重试；语音口令提示。
- AI 写作：8 个动作 + 重写/总结/关键点/检查/复制/插入/上一条/下一条；无 Key 时标注“离线示例”并可跳转配置。

---

## 3. 设置应用页面（全部可交互、可返回、持久化）

引导（两步 + 系统设置/选择器）→ 隐私模式（智能/基础 + 协议）→ 首次键盘选择（6 卡片）→ 主设置。

主设置：头像/账号、6 张自动轮播 banner、语音输入、键盘输入、工具、隐私与权限、更多。

子页：
`VoiceSettings`、`VoiceAction`、`OfflineVoice`（演示下载）、`KeyboardTypes`、`DoublePinyin`（实时转换）、`Wubi`（码表试用）、`LayoutSettings`（字号/拼音位置/数字符号/逗句号/中英位置/外观/上滑/侧栏符号增删排序/回车发送/键盘高度/恢复默认）、`FuzzyPinyin`（声母/韵母/音节全选/清空）、`Association`、`PredictionTypes`、`KeyFeedback`（试听/试振）、`QuickFormat`、`ClipboardSettings`（历史/置顶/删除/清空）、`LexiconManagement`（个人词条 CRUD、通讯录真实导入、引擎统计）、`InputMode`、`SmartInput`、`SystemPermissions`（实时状态/请求/去设置）、`SuperTransfer`（设备增删/复制示例）、`Account`、`Login`（手机号/扫码本地模拟）、`MessageCenter` + `MessageDetail`、`DesktopApp`（复制/打开/二维码）、`HelpFeedback`（FAQ 手风琴 + 本地反馈 + 复制诊断信息）、`About`（版本/DID/检查更新/协议许可）、`AiService`（Base URL/模型/Key/测试连接/清除）、`AuxInput`、`KeyboardDemo`（内嵌试用输入框，自动聚焦调起系统键盘）、`Document`（协议/隐私/权限/第三方/许可）。

设置项立即写入 SharedPreferences，Compose 使用快照版本号驱动全应用重组；IME 通过 SharedPreferences 监听 + 重建同步。

---

## 4. AI / 语音接入

### AI

- 运行时配置：`设置 → AI 服务` 的 Base URL / 模型 / API Key；默认 `https://api.deepseek.com`、`deepseek-chat`。
- 请求：`POST {base}/chat/completions`，`Authorization: Bearer <key>`，20 秒超时；错误映射 401/402/403/429/5xx、超时、DNS。
- 无 Key / 基础模式 / 关闭 AI：返回标注为“离线示例”的本地模板或规则结果。
- Key 仅存本机：优先 EncryptedSharedPreferences；初始化失败时回退普通 SharedPreferences 并在 UI 明示。Key 不写日志、不读环境变量、不打包进 APK。仓库内无任何 Key。
- 可替换后端契约（README 供替换实现参考）：

```http
POST /v1/asr            multipart audio -> {text, confidence, segments[]}
POST /v1/ai/organize    {text, mode} -> {text}
POST /v1/ai/write       {action, text, context} -> {text}
POST /v1/ai/translate   {text, from, to} -> {text}
POST /v1/clipboard/sync {deviceId, items[]} -> {items[]}
GET  /v1/config         -> {features, limits}
Authorization: Bearer <token>
```

当前实现直接使用 OpenAI 兼容 Chat Completions；本地 mock 可通过 `http://10.0.2.2:<port>/v1` 测试（已加入明文白名单）。

### 语音

- Android `SpeechRecognizer`（`zh-CN`、部分结果、优先离线可配）。真实请求 RECORD_AUDIO；IME 通过透明 `PermissionProxyActivity` 请求并回传结果。
- 浮层：波形 + 计时 + “正在倾听” + 取消/完成；错误态（网络/没听清/麦克风占用/无服务）+ 重试 + 示例文本 + 去设置。
- 结果面板：编辑/插入/发送/复制/重试/智能整理；无网络或模拟器缺少语音服务时明确提示，并可插入示例文本。

---

## 5. 验证记录

环境：Pixel 9 Pro XL AVD（Android 16 / API 36，1344×2992 @480dpi，专用 AVD `AndroidNative_API_36`，emulator-5572），JDK 21，SDK 36。

| 项目 | 结果 | 证据 |
|---|---|---|
| `./gradlew assembleDebug` | ✅ BUILD SUCCESSFUL（19 MB debug APK） | 构建日志 |
| 出现在系统输入法列表 | ✅ `ime list` 包含 `com.huapohen.doubaoinput.android/.ime.DoubaoImeService` | — |
| 设为默认输入法 | ✅ `ime set` 后 `default_input_method` 为该服务 | — |
| 系统 Settings 搜索框真实输入中文 | ✅ 通过屏幕键盘依次点 `n i h a o`，候选出现“你好”，空格上屏，搜索框显示“你好” | `screenshots/05_ime_in_settings.png`、`06_ime_pinyin.png`、`07_ime_commit.png`、`08_ime_search_result.png` |
| 26 键候选/联想 | ✅ 上屏后出现“好的/好像”等联想候选 | `06_ime_pinyin.png`、`07_ime_commit.png` |
| 9 键布局 | ✅ 设置切到 9 键后键盘显示 T9 网格 + 侧边符号 | `screenshots/12_ime_9key.png` |
| 语音浮层 / 错误 / 示例结果 | ✅ 请求麦克风；Google 语音服务启动后返回网络错误“请连接网络后再试”；示例文本 → 结果面板 | `15_voice_overlay.png`、`16_voice_result.png`、`17_voice_result_panel.png` |
| 设置首页 / 引导 / 隐私 / 键盘选择 | ✅ 全流程可完成，设置即时持久化 | `00_onboarding.png`、`01_privacy.png`、`02_privacy_consent.png`、`03_keyboard_picker.png`、`04_home.png` |
| 语音设置 / 键盘类型 | ✅ 单选项切换持久化（`voice_segment=none` 已核对） | `09_voice_settings.png`、`10_voice_segment.png`、`11_keyboard_types.png` |
| 键盘试用页自动调起键盘 | ✅ | `13_keyboard_demo.png` |
| 平板（2560×1600，横屏）首页 NavigationRail + 内容最大宽度 | ✅ 实际 APK 运行 | `tablet_02_home.png`、`tablet_04_home.png` |
| 平板键盘最大宽度 960dp 居中 + 横屏高度 | ✅ 键盘横向居中、键位完整 | `tablet_05_keyboard.png` |
| 平板设置子页（居中最大宽度、滑杆/开关/分段） | ✅ | `tablet_06_layout.png` |
| AI 服务页（运行时 Base URL / 模型 / Key） | ✅ 使用本地 mock `http://10.0.2.2:8787/v1` | `tablet_07_ai_settings.png` |
| AI 测试连接（OpenAI 兼容请求） | ✅ 显示“连接成功（HTTP 200）”，mock 返回 200 | `tablet_07_ai_settings.png`、`tablet_09_ai_test.png` |
| AI 写作面板真实请求（本地 mock） | ✅ 点击“写祝福”后状态显示 `AI · mock-model`，说明请求返回非离线结果 | `tablet_08_ai_result.png` |

未在此次运行中逐页截图验证的项目（功能已实现、编译通过）：剪贴板/常用语/词库 CRUD 的完整 UI 流程、手写/笔画/五笔实际输入、深色主题、悬浮拖动、AI 生成文本在面板中的完整可见内容（mock 响应已返回，但截图时结果卡片滚动位置未能完整展示）。标注为 **[未验证]**，不作为已通过项。

### 已知限制 / [未验证]

- 手写识别是形状模板演示（34 个），复杂字请用“手写找字 / 拼音查字”；笔画 35 字、五笔约 140 码，均为演示级覆盖。
- 双拼 9 键未实现（界面标注“敬请期待”）；双拼表为小鹤/自然码常见映射。
- 离线语音下载是本地演示进度，不包含官方 177MB 模型；实际语音依赖系统 SpeechRecognizer。
- 翻译离线词表约 190 条常用短语，未命中时提示配置 AI。
- 超级互传/账号/消息/验证码填充为本地模拟，不连接官方服务。
- 平板/横屏布局：已在 2560×1600 平板 AVD 上实际运行并截图；设置页最大宽度、首页 NavigationRail、键盘 960dp 居中和横屏高度均可见。
- AI 真实调用：已用本地 mock（`http://10.0.2.2:8787/v1`）验证测试连接 HTTP 200 与写作面板请求成功（状态 `AI · mock-model`）。未使用真实 DeepSeek Key，也未验证真实内容质量；mock Key 仅注入模拟器本地数据用于测试，APK/仓库内无 Key。
- 手写/笔画/五笔输入未做真机笔迹/码表全量回归 → **[未验证]**。

---

## 6. 截图

`screenshots/`（手机 1344×2992）：

| 文件 | 内容 |
|---|---|
| 00_onboarding.png | 启用输入法引导（已启用状态） |
| 01_privacy.png / 02_privacy_consent.png | 隐私与输入模式 |
| 03_keyboard_picker.png | 首次键盘选择（6 卡片） |
| 04_home.png | 主设置首页 + banner |
| 05_ime_in_settings.png | 系统 Settings 搜索框 + 键盘 |
| 06_ime_pinyin.png | 输入 nihao 的拼音组合与“你好”候选 |
| 07_ime_commit.png | 中文上屏与联想候选 |
| 08_ime_search_result.png | 搜索框中的“你好” |
| 09_voice_settings.png / 10_voice_segment.png | 语音设置与分段单选 |
| 11_keyboard_types.png | 六种键盘卡片 |
| 12_ime_9key.png | 9 键 T9 键盘 |
| 13_keyboard_demo.png | 应用内键盘试用页 |
| 15_voice_overlay.png | 语音倾听浮层 |
| 16_voice_result.png | 语音网络错误与重试/示例文本 |
| 17_voice_result_panel.png | 示例语音结果面板 |
| tablet_01_onboarding.png / tablet_03_onboarding2.png | 平板引导（2560×1600） |
| tablet_02_home.png / tablet_04_home.png | 平板首页 + NavigationRail + 最大宽度内容 |
| tablet_05_keyboard.png | 平板横屏键盘（960dp 居中） |
| tablet_06_layout.png | 平板布局设置（居中最大宽度） |
| tablet_07_ai_settings.png | 平板 AI 服务页（mock Base URL/模型/Key） |
| tablet_09_ai_test.png | 平板 AI 测试连接：连接成功（HTTP 200） |
| tablet_08_ai_result.png | AI 写作面板（状态 `AI · mock-model`） |
| tablet_07_ai_panel.png | AI 写作面板动作网格（写祝福/邮件/聊天助手等） |

所有截图来自实际运行的 APK；未使用官方截图冒充。平板截图由本机平板 AVD `AndroidNative_Tablet_API_36`（2560×1600 @320dpi）采集。

---

## 7. 许可与合规

- 词库：jieba 0.42.1 + pypinyin 0.55.0（MIT），仅词、无声调拼音、整数词频。
- 代码/UI：本项目原创；AndroidX/Compose/Material Icons 为 Apache-2.0。
- 未复制官方 APK/DEX/SO、皮肤 XML、字体、图片、音频、Lottie、词典二进制或官方源码。
- “豆包”及相关标识归其权利人所有；本项目为非官方、非商业的互操作性研究。
