# 豆包输入法 1.5.2 — REA 逆向分析与三端复刻报告

> 非官方、净室互操作性研究。目标 APK 来自官方下载接口。  
> 分析日期：2026-10-20 · 分析工具：REA 6.7.0 / JADX headless 0.7.1 / apktool 2.11.1 / JADX 1.5.1 / Android API 36 模拟器  
> 复刻：Flutter 通用版、Android 原生版、iOS 原生版（iPhone + iPad / Android pad）  
> 本报告中的 `[O]` 为直接观察，`[I]` 为推断，`[U]` 为未验证。

---

## 摘要

豆包输入法不是“一个带候选栏的键盘”，而是**键盘引擎 + 语音会话 + AI 写作/聊天 + 云剪贴板 + 账号同步 + 动态皮肤**的组合。Android 包 170 MB，4 个 DEX、23,039 个类、3,367 个资源、41 项权限；键盘 UI 由 APK 内的 XML 皮肤驱动，核心布局/绘制/候选/触摸在 `libkeyboard.so`，云输入在 `libime_net_sdk.so`，离线词库 164 MB，离线语音模型约 7 MB。

最重要的结论：

1. **UI 可高保真复刻**：主设置、语音设置、键盘类型、布局、模糊拼音、按键反馈、超级互传、账号、登录、帮助、关于等运行时页面已逐页取证；26/9/手写键盘、工具箱、表情、语音浮层、剪贴板授权等关键界面已截图。
2. **输入引擎不能“复制”**：官方候选排序、云词库、纠错、手写/五笔模型、164 MB 私有词典均不可获得；复刻采用公开数据（jieba + pypinyin，MIT）构建净室引擎，行为级兼容、排序不同。
3. **官方后端不可获得**：域名可达，但业务接口需要设备指纹、安装 ID、签名/风控 token、账号态与 TTNet 加密；ASR、AI、表情图、登录、客服均依赖官方服务。复刻默认本地可用，AI 用用户自己的 DeepSeek Key，后续可替换为自有后端。
4. **iOS 二进制逆向未完成**：App Store 版本存在（1.6.2，iPhone-only），但本机没有授权 IPA，无法做 Mach-O/扩展静态分析；iOS 复刻按公开键盘扩展架构 + Android 行为实现，报告中明确标注。
5. **三端复刻**：Flutter（Android/iOS/平板）、Android 原生（真实系统 IME）、iOS 原生（SwiftUI + 键盘扩展）。所有页面要求可点击、可返回、状态可持久化，不做“只有截图”的空壳。

---

## 0. 结论速览

| 维度 | 结论 | 证据级别 |
|---|---|---|
| 包名 / 版本 | `com.bytedance.android.doubaoime` / `1.5.2` (100502008) | [O] |
| 体积 / DEX / 类 | 170 MB / 4 DEX / 23,039 类 | [O] |
| 键盘架构 | 原生 XML 皮肤 + C++ `libkeyboard.so` + JNI | [O] |
| 设置页 | 70 Activity / 28 个设置 Fragment 路由 | [O] |
| 输入方式 | 9/26/手写/笔画/双拼/五笔/英文/数字/符号 | [O] |
| 语音 | 在线 ASR + 离线包 + 标点/口水词/智能整理/口令 | [O] |
| AI | 写作、改写、总结、要点、列表、检查、翻译、聊天助手、百科 | [O] |
| 云能力 | 账号同步、词库同步、跨端剪贴板（超级互传） | [O] |
| 官方后端 | 可达但需签名/账号/设备绑定，不能直接复用 | [O]/[I] |
| iOS | 有 App Store 版本；无授权 IPA，未做二进制分析 | [O]/[U] |
| 复刻可行性 | UI/交互高；引擎行为级；官方云端不可复制 | [I] |

---

## 1. 目标与方法

### 1.1 目标

- Android：`com.bytedance.android.doubaoime` 1.5.2，官方 arm64 APK。
- iOS：`com.bytedance.ios.doubaoime` 1.6.2（仅元数据/行为参考）。
- PC：`https://shurufa.doubao.com/pc`（macOS/Windows 安装包由同一 API 下发，未深入逆向）。

### 1.2 证据链

| 阶段 | 工具 | 产物 |
|---|---|---|
| 获取 | 官方下载 API | `evidence/android/doubaoime_v1.5.2_...apk` |
| 包检查 | REA `inspect-android-package` + JADX 0.7.1 | `evidence/android/rea_inspect.json` |
| 资源/清单 | apktool 2.11.1 | `evidence/android/decoded/` |
| 全量源码 | JADX 1.5.1 | `evidence/android/jadx_out/`（23,092 个 .java） |
| 原生 | `strings` / 文件类型 | 域名、协议、库职责 |
| 运行时 | Pixel 10 Pro XL API 36（专用 AVD） | `evidence/runtime/screenshots/`（122 张） |
| 布局/交互 | UI Automator + adb | `evidence/runtime/*.xml` |

### 1.3 证据强度与局限

| 证据 | 强度 | 局限 |
|---|---|---|
| AndroidManifest / 资源 / 字符串 | 高 | 资源混淆、动态下发皮肤/配置可能改变运行时 |
| JADX 源码 | 中高 | 23,092 个 .java，30 个反编译错误；大量 `a/b/c` 混淆类与反射/JNI |
| 原生库 strings | 中 | 仅字符串与符号，未做 ARM64 反汇编/动态调试 |
| 运行时截图/UI 层级 | 高 | 模拟器环境；官方云端功能不可用；IME 窗口触摸注入受限 |
| 官方接口 | 中 | 只做了可达性/未登录探测，未逆向签名与加密 |
| iOS | 低 | 仅 App Store 元数据/公开物料；无 IPA |

> 因此，报告中的“功能存在”以清单/资源/字符串/运行时为准；“内部算法/排序/协议”不做超出证据的断言。
**制品身份**

| 项 | 值 |
|---|---|
| SHA-256 | `dd96dd84fd8e09fc98b46e71ee8df9d1a44ec8b1bfaa3e1ce1e49ddb6e56c08f` |
| 签名 DN | `OU=北京春田知韵科技有限公司, O=北京春田知韵科技有限公司, ...` |
| 证书 SHA-256 | `d47cafb450b9c8191180402795f35ce50ce2d8b37f1300b42e7d8633bc86b7df` |
| releaseTime | `20261019.1338` |
| min/target SDK | 26 / 37 |
| ABI | arm64-v8a |

---

## 2. 应用架构

```mermaid
flowchart TB
  subgraph APP["Android 应用"]
    L[LauncherActivity<br/>:Setting]
    S[SettingsActivityNext<br/>:Setting]
    I[ImeService<br/>主进程]
    P[ImeContentProvider / SettingsContentProvider]
  end
  subgraph UI["键盘表现层"]
    IV[InputView]
    R[InputViewRoot / areacontrol]
    KB[KeyboardView]
    SKIN[assets/skin/default<br/>XML 皮肤]
    NATIVE[libkeyboard.so<br/>布局/绘制/触摸]
  end
  subgraph ENGINE["输入引擎"]
    JNI[KeyboardJni]
    DICT[assets/dict<br/>34 个二进制资源]
    ASR[ASR 会话]
    LLM[LLM / 云候选]
  end
  subgraph NET["网络与账号"]
    GW[ime.doubao.com]
    OG[oceancloudapi / speech.bytedance.com]
    ACC[Larus 账号 / 风控 / 推送]
  end
  L --> S
  S --> P
  I --> IV
  IV --> R
  IV --> KB
  KB --> SKIN
  KB --> NATIVE
  R --> JNI
  JNI --> DICT
  JNI --> ASR
  JNI --> LLM
  ASR --> OG
  LLM --> GW
  S --> ACC
  ACC --> GW
```

### 2.1 关键组件

- `ImeService` 继承 `LifecycleInputMethodService`，静态持有 `InputView`；`onCreateInputView` 创建/复用键盘。
- `InputView` 持有两个 `KeyboardView`、三个 `InputViewRoot`、`AiPanelView`、`AsrEditorLayoutView`；切换键盘/面板通过 `InputViewRoot` 与 JNI 完成。
- 键盘皮肤是资产 XML：`input_kbd_pinyin26.xml`、`input_kbd_pinyin9.xml`、`input_kbd_stroke.xml`、`input_kbd_wubi.xml`、`input_toolbar_idle.xml` 等；按键包含 `keycode`、上滑数字、长按气泡、图标字体。
- `libkeyboard.so` 4.9 MB，负责皮肤解析/绘制/候选择/触摸；`libime_net_sdk.so` 6.6 MB；`liboime-config.so`、`libskity.so`、`librelax.so`、`libquick.so` 为配置/渲染/动画/性能。
- `KeyboardJni` 暴露 50+ 功能键：语音、剪切板、表情、常用语、键盘选择、繁简、单手、手写找字、撤销删除、AI 写作、AI 聊天、百科、翻译、定制工具栏、侧边符号。

### 2.1.1 权限与运行时授权

| 权限 | 运行时用途 | 设置页/弹窗 |
|---|---|---|
| `RECORD_AUDIO` | 语音输入/长按说话 | 麦克风权限、语音浮层首次请求 |
| `READ_SMS` | 本地提取短信验证码并填充 | “验证码填充”开关、系统权限页 |
| `READ_CONTACTS` | 导入通讯录人名，提升人名输入准确率 | “导入通讯录人名”、系统权限页 |
| `CAMERA` | 扫码登录（扫 Mac 端二维码） | 相机权限弹窗 |
| `SYSTEM_ALERT_WINDOW` | 内测反馈浮窗/悬浮能力 | 反馈 SDK 引导 |
| `REQUEST_INSTALL_PACKAGES` | 应用内升级安装 | 升级弹窗 |
| `POST_NOTIFICATIONS` | 功能更新/活动通知 | 推送通知权限 |
| `VIBRATE` | 按键振动 | 按键反馈 |
| `ACCESSIBILITY`（服务） | 助写/上下文能力 | 无障碍权限引导 |
| `DETECT_SCREEN_CAPTURE` / `DETECT_SCREEN_RECORDING` | 防截屏/录屏安全 | 刘海屏/安全场景 |
| `INTERNET` / `ACCESS_NETWORK_STATE` | 云候选、ASR、AI、同步 | 网络错误提示 |

> 复刻版只申请实际使用的权限（录音、网络、通知、振动、相机、通讯录），不实现内测/推送/升级/防截屏等基础设施；权限页保留同样的信息架构。

### 2.2 与“普通 App”不同的运行形态

- 设置页在 `:Setting` 独立进程；键盘在主进程；两者通过 `SettingsContentProvider` / 多进程 SharedPreferences / 广播同步。
- 键盘是**系统输入法窗口**，可由任意 App 唤起；首次使用有系统级启用/切换引导。
- 语音、AI、剪贴板、登录是**运行时浮层**，不是独立页面；复刻必须实现浮层状态机，而不是只做静态页面。
- 键盘支持单手、悬浮、横屏、平板分屏、键盘高度调节；这些会改变布局与命中区域。

---

## 3. 功能地图

```mermaid
mindmap
  root((豆包输入法))
    输入
      拼音26
      拼音9
      手写
      笔画
      双拼
      五笔
      英文
      数字/符号
    语音
      在线ASR
      离线ASR
      标点策略
      口水词去除
      智能文字整理
      语音口令
    键盘工具
      工具箱
      表情/表情图/颜文字
      剪切板
      常用语
      键盘选择
      单手/悬浮
      键盘调节
      繁简
      翻译
      手写找字
      撤销删除
    AI
      AI写作
      改写/总结/要点/列表
      检查/纠错
      AI聊天助手
      百科/快捷回复
    账号与云
      登录/扫码
      设置同步
      词库同步
      超级互传
      消息中心
    设置
      语音设置
      键盘类型
      布局与显示
      模糊拼音
      智能联想
      输入预测
      按键反馈
      快捷格式
      辅助输入
      权限
      关于
```

### 3.1 输入方式

| 键盘 | 观察 | 关键行为 |
|---|---|---|
| 拼音 26 | 皮肤 XML、运行时 | QWERTY、上滑数字/符号、长按气泡、分词、中英、空格语音、搜索/发送 |
| 拼音 9 | 皮肤 XML、运行时 | T9、侧边符号、重输、候选翻页 |
| 手写 | 运行时 | 全屏画布、右侧符号、候选/删除、手写找字 |
| 笔画 | 设置页 | 五笔画 + 通配 |
| 双拼 | 设置页 | 小鹤/自然码；9 键双拼“敬请期待” |
| 五笔 | 设置页 | 86 版；编码提示、拼音混输、四码唯一、第五码首选 |
| 英文/数字/符号 | 皮肤 XML | 中英切换、首字母大写、双击空格句号 |
| 单手/悬浮 | 皮肤/设置 | 左右手、拖动、恢复、键盘高度 |

### 3.2 设置页清单（28 个 Fragment 路由）

`MAIN, FUZZY, VOICE_INPUT, KEY_FEEDBACK, KEY_AUXILIARY_INPUT, INPUT_MODE, AI_CHAT_ASSISTANT, DEBUG_SETTINGS, ABOUT, KBD_LAYOUT, CLIPBOARD, LEXICON_MANAGEMENT, SYSTEM_PERMISSION, DESKTOP, OFFLINE_DOWNLOAD, INTELLIGENT_ASSOCIATION, INPUT_RECOMMEND, SMART_INPUT, MESSAGE_CENTER, CUSTOM_SYMBOL, MULTIPLE_INPUT_TYPE, DOUBLE_SPELL_PAGE, VOICE_INPUT_ACTION, VIDEO_PLAY, SUPER_TRANSFER, ACCOUNT, HELP_AND_FEEDBACK, WUBI_PAGE`。

主设置分组：

- **语音输入**：语音转文字（智能整理、分段、标点、口水词、语音入口、离线语音、WiFi/耳机）。
- **键盘输入**：键盘类型、布局与显示、模糊拼音、智能联想、输入预测类型、按键反馈、快捷格式输入、辅助输入。
- **工具**：超级互传、剪切板、验证码填充、导入通讯录人名、词库管理。
- **隐私与权限**：输入模式与信息保护、体验改进计划、系统权限设置。
- **更多**：电脑版、帮助与反馈、关于。
- **账号**：我的、登录、消息中心、数据同步、个人词库、常用语、超级互传。

```mermaid
flowchart LR
  H[SettingsHome] --> V[VoiceSettings]
  V --> VA[VoiceAction]
  V --> OFF[OfflineVoice]
  H --> K[KeyboardInput]
  K --> KT[KeyboardTypes]
  KT --> DP[DoublePinyin]
  KT --> WB[Wubi]
  K --> L[LayoutSettings]
  K --> F[FuzzyPinyin]
  K --> A[Association]
  K --> P[PredictionTypes]
  K --> KF[KeyFeedback]
  K --> Q[QuickFormat]
  K --> AX[AuxiliaryInput]
  H --> T[Tools]
  T --> ST[SuperTransfer]
  T --> CB[ClipboardSettings]
  T --> LX[LexiconManagement]
  H --> PR[Privacy]
  PR --> IM[InputMode]
  IM --> SI[SmartInput]
  PR --> SP[SystemPermissions]
  H --> M[More]
  M --> D[DesktopApp]
  M --> HF[HelpFeedback]
  M --> AB[About]
  H --> AC[Account]
  AC --> LG[Login]
  AC --> MC[MessageCenter]
  KB[Keyboard] --> TB[Toolbox]
  TB --> EM[Emoji / Stickers / Kaomoji]
  TB --> CL[Clipboard]
  TB --> CP[CommonPhrases]
  TB --> KS[KeyboardSwitcher]
  TB --> SO[SmartOrganize]
  TB --> CT[CustomToolbar]
  TB --> HL[HandwritingLookup]
  KB --> TR[Translate]
  KB --> OH[OneHand / Floating]
  KB --> KC[KeyboardAdjust]
  KB --> VO[VoiceOverlay]
  KB --> AI[AI Writing / Chat]
```

上图只列主路径；`KeyboardTypes` 的六张卡片、`LayoutSettings` 的符号编辑、`SuperTransfer` 的设备管理、`InputMode` 的协议页等二级/三级页面均在实现中。

---

## 4. 运行时页面证据

> 完整 61 张精选截图见 `reports/report.html` 的可筛选画廊；原始 122 张在 `evidence/runtime/screenshots/`（不提交公开仓库）。  
> 下列截图已优化到 `reports/assets/screens/`。

### 4.1 首次启动与输入法启用

| 引导 | 隐私/模式 | 输入法切换器 |
|---|---|---|
| ![引导](assets/screens/01_launcher.webp) | ![隐私](assets/screens/21_privacy.webp) | ![切换器](assets/screens/58_guide_step2.webp) |

观察：

- 首次启动进入 `ImeGuideActivity`，两步：启用 → 切换；点第一步会先弹隐私声明。
- 隐私声明强制二选一：**智能输入模式**（云端 AI/语音）或 **基础输入模式**（仅本地）。
- 第二步打开系统 IME Switcher，选择“豆包输入法”后进入设置；设置页与键盘共享状态。

### 4.2 主设置与子页

| 主设置 | 语音设置 | 键盘类型 |
|---|---|---|
| ![主设置](assets/screens/107_main_top2.webp) | ![语音](assets/screens/10_voice_settings.webp) | ![类型](assets/screens/12_keyboard_types.webp) |

| 布局与显示 | 模糊拼音 | 按键反馈 |
|---|---|---|
| ![布局](assets/screens/15_layout_top.webp) | ![模糊](assets/screens/75_fuzzy_on.webp) | ![反馈](assets/screens/85_key_feedback.webp) |

| 超级互传 | 输入模式 | 系统权限 |
|---|---|---|
| ![互传](assets/screens/92_super_transfer.webp) | ![模式](assets/screens/97_input_mode.webp) | ![权限](assets/screens/102_system_permissions.webp) |

| 账号 | 登录 | 关于 |
|---|---|---|
| ![账号](assets/screens/108_account.webp) | ![登录](assets/screens/109_login.webp) | ![关于](assets/screens/105_about.webp) |

### 4.3 键盘与浮层

| 26 键 | 9 键 | 手写 |
|---|---|---|
| ![26](assets/screens/26_keyboard_26_active.webp) | ![9](assets/screens/45_keyboard_9key.webp) | ![手写](assets/screens/51_handwriting_keyboard.webp) |

| 工具箱 | 表情 | 键盘选择 |
|---|---|---|
| ![工具箱](assets/screens/34_toolbox_open.webp) | ![表情](assets/screens/38_emoji_panel.webp) | ![切换](assets/screens/44_keyboard_switcher.webp) |

| 语音浮层 | 剪贴板授权 | 候选/工具条 |
|---|---|---|
| ![语音](assets/screens/53_voice_overlay.webp) | ![剪贴板](assets/screens/65_clipboard.webp) | ![候选](assets/screens/27_keyboard_typing.webp) |

> 语音浮层在模拟器上显示“正在倾听”，随后报“请连接网络后再试”；这是官方 ASR 会话建立失败，不是 UI 缺失。表情图 Tab 在无官方后端时显示空白占位；帮助/登录 WebView 停在加载中——三者共同证明云端依赖。

### 4.4 平板（Android pad）运行时行为

在 2560×1600 / density 320 的 Android 13" 平板上实测，官方 **不是**把手机键盘横向拉满，而是：

- 设置页仍是**居中单列**（大量左右留白），没有双栏/导航栏适配。
- 输入法默认以**悬浮紧凑键盘**出现在屏幕右侧（约 350×330 dp），带缩放/收起按钮、底部拖动条。
- 首次键盘类型选择、工具箱、键盘切换都以**右侧浮窗卡片**呈现；工具箱只有 8 个入口，`定制工具栏` 置灰。
- 26 键/9 键在浮窗内自适应，9 键压缩为 3 列数字键盘 + 左侧符号列。
- 说明官方 pad 版是“可用的手机布局 + 悬浮键盘”，不是真正的大屏信息架构。复刻版保留悬浮键盘行为，同时提供更合理的平板双栏/居中布局作为增强（见复刻规格）。

| 平板设置 | 首次键盘浮窗 | 26 键悬浮 |
|---|---|---|
| ![平板设置](assets/screens/tablet_03_settings.webp) | ![平板选择](assets/screens/tablet_05_keyboard.webp) | ![平板26](assets/screens/tablet_06_keyboard26.webp) |

| 悬浮工具箱 | 键盘切换 | 9 键悬浮 |
|---|---|---|
| ![平板工具箱](assets/screens/tablet_07_toolbox.webp) | ![平板切换](assets/screens/tablet_08_switcher.webp) | ![平板9键](assets/screens/tablet_09_9key.webp) |

---

## 5. 输入引擎与词库

### 5.1 资源

| 资源 | 大小 | 作用 |
|---|---:|---|
| `assets/dict` | 164 MB / 34 文件 | 拼音、联想、纠错、手写、五笔、离线 ASR 等二进制 |
| `assets/dict/asr` | 7 MB | 离线语音模型 |
| `assets/skin/default` | 1.3 MB | 键盘 XML 皮肤、字体、2x/3x/3.5x/横屏/深色/悬浮 |
| `assets/lottie` | 3.7 MB | 语音、引导、候选、文字整理动画 |
| `assets/symbol` | 64 KB | Emoji/颜文字/符号表 |

**不复制**：这些是字节跳动的私有资产；复刻只使用公开词频数据生成自己的词典，并用自有皮肤/图标。

### 5.2 复刻引擎

```mermaid
flowchart LR
  K[按键序列] --> S[拼音切分<br/>最大匹配/分隔符]
  S --> Q{模式}
  Q -->|全拼| F[全拼词条索引]
  Q -->|简拼| I[首字母索引]
  Q -->|T9| T[数字->字母组<br/>动态规划]
  F --> R[候选合并/排序]
  I --> R
  T --> R
  R --> M[MRU + 词频 + 长度 + 上下文]
  M --> C[候选栏]
  C -->|上屏| L[学习/持久化]
```

- 数据：`clones/shared/data/pinyin_dict.json`，33,500 条（jieba 词频 + pypinyin），1.3 MB。
- 排序：词频、长度、MRU、可选 bigram；候选首屏目标 <50 ms。
- 明确限制：不复制官方 164 MB 词典/云候选/纠错模型；排序不会与官方完全一致。

---

## 6. 语音与 AI

### 6.1 语音状态机

```mermaid
stateDiagram-v2
  [*] --> Idle
  Idle --> Listening: 点击/长按说话
  Listening --> Recognizing: 停止录音
  Listening --> Idle: 取消
  Recognizing --> Result: 成功
  Recognizing --> Error: 网络/服务/无语音
  Result --> Editing: 划选/长按
  Editing --> Committed: 上屏/发送
  Result --> Committed: 直接上屏
  Error --> Listening: 重试
  Committed --> Idle
```

能力：中英混输、多方言、离线语音、标点四策略、口水词正常/激进、智能文字整理、语音口令发送。运行时语音失败文案与设置项均已取证。

```mermaid
sequenceDiagram
  autonumber
  participant U as 用户
  participant IME as ImeService / AsrManager
  participant ASR as 语音服务
  participant E as 输入框
  U->>IME: 点击/长按“点击说话”
  IME->>IME: 申请麦克风，显示波形与计时
  IME->>ASR: 音频流 + 设备/账号上下文
  ASR-->>IME: 部分识别 / 最终识别
  IME->>IME: 标点、口水词、智能整理
  IME->>E: 提交文本 / 进入可编辑结果
  U->>IME: 划选修改 / 撤回 / 发送
```

### 6.2 AI 能力矩阵

| 能力 | 入口 | 请求 |
|---|---|---|
| AI 写作 | 工具箱/AI 面板 | `POST /api/v1/bot/rich_chat`；`scene/query/preceding_part/follows_below/format_query/output_format=3` |
| 场景聊天 | AI 聊天助手 | `POST /api/v1/bot/chat`；`bid/query` |
| 智能文字整理 | 语音结果/工具箱 | `POST /api/v2/ai/text_organization`；`scene/query/space_at_cn_en_nb/space_at_newline/stream` → `content/no_rewrite/code/msg/message` |
| 纠错 | 检查 | `POST /api/v1/rectify_text`；`text/rectify_type/grammar` |
| 翻译 | 工具栏 | `POST /api/v1/translate` |
| 话题/快捷回复 | 聊天助手 | `POST /api/v1/topic_make`；`GET /api/v1/quick_reply` |
| 表情推荐 | 候选/表情 | `/api/v2/emoticons/*` |

AI 写作操作：检查、重写、总结、关键点、列表、复制、替换、上一条/下一条、分享、展示原文。场景模板：写祝福、高赞动态、写评论、自我介绍、宴席邀请、写邮件、爆款文案。

```mermaid
sequenceDiagram
  autonumber
  participant U as 用户
  participant K as 键盘 / AiPanelView
  participant B as 可替换后端
  participant M as LLM
  U->>K: 选择文本 / 点击“写祝福/重写/总结”
  K->>B: POST /v1/ai/write {action,text,context}
  B->>M: Chat Completions（用户自己的 Key）
  M-->>B: 流式 token
  B-->>K: SSE / JSON
  K->>U: 结果卡片：替换 / 复制 / 重试 / 上一条
```

---

## 7. 官方后端：为什么拿不到、怎么替换

### 7.1 域名与接口

| 域名 | 说明 |
|---|---|
| `https://ime.doubao.com` | 主网关：账号、同步、AI、ASR 记录、剪贴板、表情、消息 |
| `https://ime-gw.oceancloudapi.com` | 海外/备用网关；本机 TLS 不稳定 |
| `https://ime.oceancloudapi.com` | 海外/备用；根路径 404 |
| `https://speech.bytedance.com` | 语音服务 |
| `https://is.snssdk.com` | 设备注册/风控 |

接口清单（节选，完整表见 `analysis/FINDINGS.md`）：

```text
POST /api/v1/asr/record                语音识别
POST /api/v1/asr/fmt                   识别结果格式化
POST /api/v1/bot/chat                  AI 场景聊天（流式）
POST /api/v1/bot/rich_chat             AI 写作（流式）
POST /api/v2/ai/text_organization      智能文字整理（SSE）
POST /api/v1/rectify_text              文本纠错
POST /api/v1/translate                 翻译
GET  /api/v1/quick_reply               快捷回复
POST /api/v1/topic_make                话题生成
POST /api/v2/auth/sync                 跨端认证
POST /api/v2/sync/settings             设置同步
POST /api/v2/clipboard/{config,pull,switch}
POST /api/v2/stream/clipboard/{text,rich}/copy
POST /api/v2/clipboard/image/token
GET  /api/v2/emoticons/{hot_list,query}
POST /api/v2/emoticons/{query_hit,commit_record}
POST /api/v2/im/message/{list,delete,read_reported}
POST /api/v3/context/ime/{login,logout,ner,modify_pair,user_words}
POST /api/v1/user/{get_config,check_auth}
```

### 7.2 不可获得性的证据

1. **域名可达 ≠ 接口可用**：`GET https://ime.doubao.com/api/v1/ip/info` 未登录返回 200；但业务接口需要 App 内设备 ID、安装 ID、签名、账号 token、灰度参数与 TTNet 加密。
2. **ASR 失败**：模拟器语音浮层直接提示“请连接网络后再试”，说明会话/鉴权未建立；`speech.bytedance.com` 根路径 404，无公开协议。
3. **AI 需要账号与风控**：`/api/v1/bot/*`、`/api/v2/ai/text_organization` 未登录/模拟器调用失败或进入风控。
4. **远程资源缺失**：表情图空白、登录 WebView“加载中…”、客服中心只加载出框架。
5. **跨端互传需要设备注册**：同一账号 + 设备关系 + 服务端消息，无法仅靠客户端复刻。
6. **iOS IPA 不可得**：App Store DRM/Apple ID 限制；本机未购买/未安装；无解密 IPA。

### 7.3 替换后端设计（复刻默认本地）

```http
POST /v1/asr            multipart audio -> {text, confidence, segments[]}
POST /v1/ai/organize    {text, mode} -> {text}
POST /v1/ai/write       {action, text, context} -> {text} 或 SSE
POST /v1/ai/translate   {text, from, to} -> {text}
POST /v1/clipboard/sync {deviceId, items[]} -> {items[]}
GET  /v1/config         -> {features, limits}
Authorization: Bearer <token>
```

客户端设置：`Base URL / Model / API Key`；默认空 = 纯本地；AI 可指向 `https://api.deepseek.com`（OpenAI 兼容）。**不把官方域名作为回退。**

---

## 8. iOS 版本可行性

| 项 | 结果 |
|---|---|
| App Store 元数据 | `com.bytedance.ios.doubaoime` 1.6.2，iOS 15+，iPhone-only，357 MB |
| IPA | 未取得；本机无已购账号/已安装 App |
| 二进制分析 | 未做；无法核验扩展 Info.plist、类/框架、网络栈 |
| 可做 | 公开元数据、截图/描述、iOS 键盘扩展公开架构、Android 行为对照 |
| 复刻 | SwiftUI 主 App + `UIInputViewController` 扩展；App Group/Keychain；iPhone/iPad 自适应 |
| 若要继续 | 需用户提供**有权下载该 App 的 Apple ID 的 IPA**，或已解密 IPA；之后可补 Mach-O/扩展分析 |


取证：`xcrun devicectl device info apps` 在已配对 iPhone 上未发现该 App；`itunes lookup` 可见 1.6.2 / 357 MB；本机无 `ipatool`、无已登录下载账号、无豆包输入法 IPA。未使用第三方解密 IPA，避免来源与法律风险。


iOS 键盘扩展约束：独立进程、内存限额、`RequestsOpenAccess` 才能联网/共享容器、扩展不能嵌入 Flutter 引擎、需要 App Group 共享词库/设置。

### 8.1 App Store 公开物料观察

App Store 的 6 张官方截图（公开营销物料，不随仓库分发）显示：

- iOS 与 Android 共用同一套视觉语言：浅蓝/白渐变背景、圆角白键、蓝色动作键、`点击说话` 胶囊、同款 26 键布局。
- iOS 动作键显示 `发送` / `搜索`；空格内是语音波形；底部有 `123`、逗号、`中/英`、地球/表情。
- iOS 独有卖点：`语音免跳转`（默认模式 / 待机模式）、`来自其他手机复制的图片`、`智能文字整理` 的分段结果卡片。
- 截图中的键盘是**系统键盘扩展**形态（无 App 边框），与 Android 的 IME 窗口一致；iOS 的 `待机模式` 是 Android 上没有直接对应的语音交互。

这些只能证明公开 UI/文案，不能替代二进制分析；iOS 的扩展类、网络栈、离线模型仍未验证。


---

## 9. 三端复刻

> 状态：**三端均已构建并实机/模拟器运行**；验证结果见第 10 节、`progress.md` 与各项目 README。

| 版本 | 目录 | 包名 | 关键点 |
|---|---|---|---|
| Flutter 通用 | `clones/flutter` | `com.huapohen.doubaoinput.flutter` | Android/iOS/平板；App 内完整键盘与全部设置；AI/语音；可选 Android 系统 IME |
| Android 原生 | `clones/android_native` | `com.huapohen.doubaoinput.android` | 真实 `InputMethodService`；Kotlin；手机/pad；全部设置与键盘面板 |
| iOS 原生 | `clones/ios_native` | `com.huapohen.doubaoinput.ios` | SwiftUI 主 App + UIKit 键盘扩展；iPhone/iPad |

### 9.1 设计对齐

- 主色 `#4F84FF`、页面浅蓝 `#F2F7FF`、键盘 `#EBEBEB`、白键、功能键 `#BDC2C8`。
- 卡片圆角 18、按键 10、胶囊 999；标题 20–24 semibold。
- 键盘：工具条 56 dp + 候选 48 dp + 主体 260–300 dp；平板最大宽度 960 dp。
- 全部页面可点击、可返回、状态持久化；不做死按钮。

### 9.1.1 使用方式

- **Flutter**：`cd clones/flutter && flutter run`（或 `flutter build apk --debug`）。App 内“键盘体验”提供完整键盘；设置页可改主题/键盘/语音/AI。
- **Android 原生**：安装 `app-debug.apk` → 系统设置启用“豆包输入法（原生复刻）” → 任意输入框切换。设置 App 与 IME 共享偏好。
- **iOS 原生**：运行模拟器/真机 App → 设置 → 通用 → 键盘 → 键盘 → 添加新键盘 → 选择复刻键盘；在 App 的键盘实验室或任意输入框调起。
- **AI**：设置 → AI 服务，填 Base URL / Model / Key；无 Key 时自动离线模板。参考后端 `backend/server.js` 可直接跑在本机。
- **平板**：同一安装包在 Android pad / iPad 上自适应；官方 pad 的“右侧悬浮键盘”行为在复刻规格中保留为可选模式。

### 9.1.2 iOS 原生复刻实机

iPhone 17（iOS 26.5）实际构建/安装/运行截图（完整 30 页在 HTML 画廊）：

| 设置首页 | 键盘实验室 | AI 写作 |
|---|---|---|
| ![iOS 首页](assets/clones/ios_03_home.webp) | ![iOS 键盘](assets/clones/ios_30_keyboard_demo.webp) | ![iOS AI](assets/clones/ios_27_ai_writing.webp) |

- 主 App 与键盘扩展共用 `Shared/` 下的引擎、主题、设置与词典。
- `pluginkit` 已识别扩展：`com.huapohen.doubaoinput.ios.keyboard(1.5.2)`。
- 键盘实验室支持 26/9/手写/双拼/五笔、候选、工具条、表情、剪切板、语音与 AI 面板。
- 来源：真实模拟器截图，不是设计稿；iPad 截图见后续更新。

iPad Pro 13（iOS 26.5）双栏布局与**系统键盘扩展实录**：左侧设置/右侧键盘测试，底部为真实系统键盘，候选“你好/你/泥/尼/拟/逆”：

![iPad 系统键盘](assets/clones/ios_ipad_01_home.webp)

- 这是通过系统键盘扩展真实输入的截图（非 App 内预览），证明 `UIInputViewController` 已可被系统调起并上屏。
- iPad 布局：左侧导航/内容 + 右侧键盘工作区；iPhone 为单列 + 底部键盘。
- 键盘扩展已通过 `pluginkit` 注册，可在设置中添加；真机需在“完全访问”后使用共享词典/剪贴板。


### 9.1.3 Android 原生与 Flutter 实机

Android 原生（Pixel 10 Pro XL API 36）——真实系统 IME，拼音 `ni'hao` → 候选「你好」→ 上屏：

| 系统 IME 候选 | 上屏结果 | 平板双栏 |
|---|---|---|
| ![Android 拼音](assets/clones/android_06_ime_pinyin.webp) | ![Android 上屏](assets/clones/android_07_ime_commit.webp) | ![Android 平板](assets/clones/android_android_tablet_02_main.webp) |

Flutter iOS（iPhone 17e）——App 内键盘、候选、工具箱与 AI 面板：

| 键盘与候选 | 工具箱 | AI 面板 |
|---|---|---|
| ![Flutter 键盘](assets/clones/flutter_ios_04_keyboard_26.webp) | ![Flutter 工具箱](assets/clones/flutter_ios_07_panel_toolbox.webp) | ![Flutter AI](assets/clones/flutter_ios_09_panel_ai.webp) |

- Android 原生：`ime list` 可见，设置中文输入在系统搜索框真实上屏；平板使用 NavigationRail + 居中内容。
- Flutter：iOS 10 张运行截图，本地词库 33,500 条，加载 139 ms / 查询 2.2 ms；Android APK 正在最后的构建修复。
- 三端均不使用官方 Key；AI Key 只在运行时输入。

Flutter 的 **Android 系统 IME** 也已实测：在“系统输入法测试”页调起复刻 IME，输入并上屏「通过」；iPad 引导页为自适应单列/居中布局。

| Flutter Android 系统 IME | Flutter iPad 引导 |
|---|---|
| ![Flutter IME](assets/clones/flutter_android_08_system_ime_typing.webp) | ![Flutter iPad](assets/clones/flutter_ipad_01_onboarding.webp) |


补充验证（Android 原生代理）：

- 29 个 Kotlin 源文件、30+ 路由，无 Text 占位页；真实 `InputMethodService` 在系统 Settings 搜索框提交「你好」。
- 语音：`RECORD_AUDIO` 权限流、波形浮层、`SpeechRecognizer`；模拟器网络错误显示“请连接网络后再试”，示例文本 → 结果面板。
- AI：本地 mock `http://10.0.2.2:8787/v1`，连接测试 HTTP 200，写作面板显示 `AI · mock-model`；真实 DeepSeek 内容质量未在手机端复测。
- 平板：2560×1600 NavigationRail + 居中内容；键盘最大 960 dp 居中。
- 截图：27 张（手机 17 + 平板 10）。


### 9.2 复刻边界

- **不复刻**：官方 APK/DEX/SO、皮肤 XML、MiSans/oimeui 字体、私有词典、官方图片/音频/Lottie、官方接口签名/风控。
- **复刻**：信息架构、页面布局、交互状态机、键盘行为、语音/文字整理/AI 写作流程、设置语义、平板适配。
- **引擎**：净室拼音引擎（公开数据），行为级兼容；候选排序不保证一致。
- **AI**：用户自己的 DeepSeek Key；无 Key 时本地模板；不调用官方 AI。
- **账号/互传**：复刻版为本地模拟；不接入官方账号，不伪造官方登录。

---

## 10. 验证与证据

> 下列为分析阶段已完成的验证；三端构建/运行结果见 `progress.md` 和各项目 README。

| 验证 | 结果 |
|---|---|
| APK 安装 / IME 注册 | [O] `ime list` 可见 `ImeService` |
| 首次引导 / 隐私 / 键盘类型 | [O] 截图 01/02/25/57/58 |
| 26 键 / 9 键 / 手写 | [O] 截图 26/45/51；真实键盘可显示 |
| 工具箱 / 表情 / 键盘切换 | [O] 截图 34/38/44 |
| 语音浮层 | [O] 出现“正在倾听”，随后网络错误 |
| 剪贴板首次授权 | [O] 截图 65；IME 窗口按钮注入触摸受限 [U] |
| 主设置全部子页 | [O] 截图 71–110 |
| 官方接口 | [O] `ip/info` 200；业务接口不可用 [I] |
| iOS IPA | [U] 未取得 |
| 参考后端（无 Key） | [O] `provider=local`，中文模板返回 |
| 参考后端（DeepSeek） | [O] `provider=deepseek`，模型 `deepseek-flash`，真实生成成功；Key 未记录/未入库 |
| Android 原生构建 | [O] `assembleDebug` 成功，APK 19.7 MB |
| Android 系统 IME | [O] `ime list` 可见；拼音 `ni'hao` → 候选「你好」→ 上屏 |
| Android 平板 | [O] NavigationRail + 居中内容，2560×1600 |
| Flutter iOS | [O] iPhone 17e 运行；10 张截图；本地词库 33,500 条 |
| Flutter Android | [O] debug APK 157 MB，安装并运行；9 键实验室候选/面板 |
| iOS 原生构建 | [O] `BUILD SUCCEEDED`；42 张 iPhone + 7 张 iPad |
| iOS 键盘扩展 | [O] `pluginkit` 注册；系统键盘输入「你好」成功 |
| iPad 双栏 | [O] 左设置/右键盘，系统键盘可调起 |



---

## 11. 已知限制

1. 官方候选排序、云词库、纠错、手写/五笔模型不可获得；复刻为净室近似。
2. 官方 ASR/AI/登录/表情图/客服/跨端互传依赖官方后端，复刻不接入。
3. iOS 未做二进制逆向；iOS 复刻基于公开架构与 Android 行为。
4. 手写识别在复刻中为演示级模板/有限字符集；五笔码表覆盖有限。
5. 字体/图标以系统/开源替代，视觉不会逐像素一致。
6. 运行时 IME 窗口的触摸注入在模拟器上受限，部分浮层按钮只能通过真机/手工验证；报告如实标注 `[U]`。
7. 官方 App 的隐私/合规文案仅作分析引用，复刻版使用自己的文案与协议占位。

---

## 12. 合规声明

本项目为**非官方、非商业的互操作性研究**。不包含官方 APK/IPA、反编译代码、私有词典/皮肤/字体/图片/音频，不绕过官方鉴权，不重放私有接口，不冒充官方账号。  
“豆包”“豆包输入法”商标归其权利人所有；复刻版明确标注“非官方复刻”。  
公开仓库仅包含自有实现、公开数据与报告截图；官方制品与提取资源保留在本地 `evidence/` 且不提交。

---

## 13. 附录

- 详细事实集：`analysis/FINDINGS.md`
- 复刻规格：`analysis/CLONE_SPEC.md`
- 截图清单：`reports/assets/screens.json`
- 进度：`progress.md` / `progress.html`
- 构建说明：各 `clones/*/README.md`
- 共享词库：`clones/shared/data/pinyin_dict.json`（MIT 数据生成）
