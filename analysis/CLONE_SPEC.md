# 豆包输入法复刻 — 共享规格与验收标准

> 三个实现并行：Flutter 通用版、Android 原生版、iOS 原生版。  
> 事实源：`analysis/FINDINGS.md`、`evidence/runtime/screenshots/`、`evidence/android/decoded/res/`。  
> 原则：净室实现；不复制官方 APK/DEX/SO/皮肤/字体/词典/图片；所有页面可点击、可返回、状态可持久化；无死按钮。

---

## 0. 交付目录

```text
clones/
  shared/
    data/pinyin_dict.json          # 开源数据生成，三端共用（若已生成）
    LICENSES.md                    # jieba / pypinyin / 字体 / 图标许可
  flutter/                         # Flutter 通用版（Android + iOS + 平板）
  android_native/                  # Android 原生版（手机 + pad）
  ios_native/                      # iOS 原生版（iPhone + iPad）
  screenshots/                     # 三端统一验收截图
```

每个子项目必须有 `README.md`：构建、运行、测试、已知限制、后端替换说明。  
每个子项目不得包含：官方 APK/IPA、反编译代码、官方皮肤/字体/词典、任何 API Key、`build/`/`.dart_tool/`/`DerivedData/` 等产物。

---

## 1. 身份与命名

| 版本 | applicationId / bundleId | App 名 | 最低系统 |
|---|---|---|---|
| Flutter | `com.huapohen.doubaoinput.flutter` | 豆包输入法（复刻） | Android 8 / iOS 15 |
| Android 原生 | `com.huapohen.doubaoinput.android` | 豆包输入法（原生复刻） | Android 8 (26) |
| iOS 原生 | `com.huapohen.doubaoinput.ios` | 豆包输入法（iOS 复刻） | iOS 15 |

- Android `targetSdk 36`，Kotlin，Java 17；Gradle wrapper 自带。
- iOS Swift 5.9+，SwiftUI 主 App + UIKit 键盘扩展；App Group `group.com.huapohen.doubaoinput`。
- Flutter 3.47 / Dart 3.13；`flutter create` 生成后改包名。
- 平板：同一安装包自适应，不另做 store 变体；Android 用 `sw600dp`/WindowSizeClass，iPad 用 size classes。

---

## 2. 设计系统（三端一致）

| 令牌 | 值 |
|---|---|
| `primary` | `#4F84FF` |
| `primaryPressed` | `#3051F2` |
| `pageBg` | `#F2F7FF` |
| `card` | `#FFFFFF` |
| `text` | `#111111` |
| `textSecondary` | `#666666` |
| `divider` | `#1A394C5A` |
| `keyboardBg` | `#EBEBEB` |
| `key` | `#FFFFFF` |
| `keyFunc` | `#BDC2C8` |
| `danger` | `#FF5353` |
| 圆角 | 卡片 18，按键 10，胶囊 999 |
| 间距 | 4/8/12/16/20/24 |
| 字体 | 系统字体（Android Roboto/Noto Sans SC，iOS SF/PingFang）；标题 20–24 semibold，正文 15–16，说明 13 |
| 动效 | 150–250 ms ease-out；键盘面板 220 ms slide/fade |

键盘比例（手机竖屏，参考 1344×2992）：
- 工具条 56 dp，候选栏 48 dp（含拼音行时 66 dp），键盘主体 260–300 dp。
- 26 键 4 行；9 键 4 行 + 左侧符号列；底部功能行 48 dp。
- 平板/横屏：键盘最大宽度 960 dp 居中，两侧留白；26 键可增加键宽；9 键可双栏。

---

## 3. 页面与导航（必须全部实现）

### 3.1 启动/引导

1. `Splash` → 首次运行进入 `Onboarding`；否则进入 `SettingsHome`。
2. `Onboarding` 两步：
   - 第一步“启用输入法”：Android 跳系统输入法设置；Flutter/iOS 显示启用指引 + 可点击“打开系统设置”。
   - 第二步“切换到输入法”：Android 弹 IME picker；iOS 指引“设置-通用-键盘-添加新键盘”。
   - 完成后进入 `PrivacyConsent`。
3. `PrivacyConsent`：
   - “同意并继续” → 智能输入模式（云端 AI 开关默认开）。
   - “拒绝” → 基础输入模式（仅本地；AI/语音/翻译显示“需开启智能输入模式”，但仍可进入设置）。
   - 底部协议链接可点开内置 WebView/文本页。
4. 首次进入键盘：`KeyboardTypePicker` 六卡片（9键/26键/手写/笔画/双拼/五笔）；选择后生效。

### 3.2 主设置 `SettingsHome`

Header：头像、`豆包输入法（复刻）`、右上账号按钮。
Banner 轮播（6 张，自动轮播，可点）：
1. 全场景语音精准识别 → 语音设置
2. 智能联想 → 联想设置
3. 智能文字整理 → 语音设置/智能整理
4. 离线语音 → 离线语音页
5. 超级互传 → 超级互传
6. 电脑桌面端 → 电脑版页

分组与逐项行为：

**语音输入**
- `语音转文字` → `VoiceSettings`

**键盘输入**
- `键盘类型` → `KeyboardTypes`（六卡片；双拼→`DoublePinyin`；五笔→`Wubi`）
- `布局与显示` → `LayoutSettings`
- `模糊拼音` → `FuzzyPinyin`
- `智能联想` → `AssociationSettings`（总开关）
- `输入预测类型` → `PredictionTypes`（Emoji/图片表情/颜文字 三组开关）
- `按键反馈` → `KeyFeedback`
- `快捷格式输入` → `QuickFormat`
- `辅助输入` → 开关（行内 switch，无子页）

**工具**
- `超级互传` → `SuperTransfer`
- `剪切板` → `ClipboardSettings`
- `验证码填充` → 开关 + 权限说明
- `导入通讯录人名` → 开关 + 权限说明
- `词库管理` → `LexiconManagement`

**隐私与权限**
- `输入模式与信息保护` → `InputMode`
- `加入体验改进计划` → 开关
- `系统权限设置` → `SystemPermissions`

**更多**
- `电脑版` → `DesktopApp`
- `帮助与反馈` → `HelpFeedback`（内置 FAQ + 反馈表单；离线可提交到本地）
- `关于` → `About`

所有行：点击有反馈、有目标页、可返回；switch 立即持久化并显示 toast。

### 3.3 设置子页（全部可交互）

| 路由 | 内容 | 必须可操作 |
|---|---|---|
| `VoiceSettings` | 智能文字整理；分段后空行/不空行；标点四选一；口水词正常/激进；联想候选栏语音键；离线语音下载（模拟进度/完成）；WiFi 弱切流量；耳机麦克风 | 每个开关/单选持久化；下载有进度与状态 |
| `VoiceAction` | 语音口令开关；五个口令多选；自定义口令 | 可增删、保存 |
| `KeyboardTypes` | 六卡片 + 预览；选择后返回并 toast | 切换后键盘 demo 立即变化 |
| `DoublePinyin` | 小鹤/自然码；9键双拼置灰“敬请期待” | 选择持久化 |
| `Wubi` | 86版；编码提示；拼音混输；四码唯一；第五码首选 | 开关持久化 |
| `LayoutSettings` | 候选字大小滑杆；拼音显示位置；26键数字符号合并/分开；逗句号分开；中英切换位置；外观三态；上滑数字符号；侧边栏自定义符号（9键/数字）；回车发送；键盘高度调节 | 滑杆实时预览；符号编辑可增删排序；外观切换全局立即生效 |
| `FuzzyPinyin` | 总开关；声母 6 项；韵母 9 项；音节 2 项 | 展开/收起；全选/清空；持久化 |
| `AssociationSettings` | 总开关 + 说明 | 持久化 |
| `PredictionTypes` | Emoji/图片/颜文字，每组开关 + 示例 | 持久化 |
| `KeyFeedback` | 响应速度（跟手/质量）；声音开关+音量；振动开关+强度；26键气泡 | 滑杆/单选持久化；试听/试振 |
| `QuickFormat` | 中英数空格；首字母大写；双击空格句号 | 开关持久化 |
| `ClipboardSettings` | 候选栏展示；历史记录；清空确认 | 开关；清空 toast |
| `LexiconManagement` | 个人词库列表（可增删）；通讯录词库导入（模拟）；清空确认 | 增删即时 |
| `InputMode` | 智能/基础二选一；更多设置；第三方共享/用户协议/隐私政策/权限清单（内置文本） | 切换模式影响 AI 可用性并提示 |
| `SmartInput` | 云端输入信息；云端个人词库 | 持久化 |
| `SystemPermissions` | 短信/通讯录/麦克风/相机/通知 五项；状态；去设置 | Android 打开系统权限页；iOS 打开系统设置；状态刷新 |
| `SuperTransfer` | 特性三卡；启用开关；设备列表；添加设备；使用须知 | 未登录→登录页；启用后显示“本机”与“添加设备”；复制示例文本 |
| `Account` | 未登录/已登录；消息中心；数据同步/个人词库/常用语开关；超级互传状态；退出登录 | 登录页返回后状态变化；退出确认 |
| `Login` | 豆包账号登录（复刻版：本地模拟登录）；扫码登录（展示二维码占位 + 扫描动画）；协议 | 一键登录/模拟扫码成功；不请求官方 |
| `MessageCenter` | 消息列表（本地示例）；已读/删除；空态 | 可操作 |
| `DesktopApp` | macOS/Windows 卡片；复制官网；二维码占位 | 复制 toast |
| `HelpFeedback` | FAQ 手风琴；反馈类型；文本；提交 | 本地保存反馈，显示成功 |
| `About` | 版本 1.5.2-clone；构建时间；DID（本地生成）；检查更新（模拟）；开源许可 | 可点 |
| `KeyboardDemo` | 输入框 + 完整键盘 + 所有面板 + 语音/AI | 见第 4 节 |

---

## 4. 键盘功能规格（三端必须一致）

### 4.1 26 键

- 布局：`q w e r t y u i o p` / `a s d f g h j k l` / `shift z x c v b n m backspace` / `123 , space 中/英 action`。
- 长按字母：显示气泡（大写/小写/数字/符号）；上滑：数字/符号（可开关）。
- 字母键上滑数字映射：q1 w2 e3 r4 t5 y6 u7 i8 o9 p0；a- s/ d： f； g（ h） j～ k“ l”；z@ x. c# v、 b？ n！ m，。
- `shift`：单击大小写，双击锁定（显示指示）。
- `backspace`：单击删一字，长按连续删；下滑撤回上次清空（复刻版提供“撤销” toast）。
- `space`：单击空格；长按/上滑进入语音；英文双击句号（可开关）。
- `中/英`：切换中文/英文；英文模式候选栏显示联想词。
- `action`：根据输入类型显示“搜索/发送/前往/完成”；点击提交。
- 候选栏：拼音串可点选分词；候选 8–9 个；左右翻页；点击上屏；长按候选可查看详情/删除词。
- 组合态：输入 `nihao` 显示 `你好`、`你号`、`尼好`…；空格上屏首选；`'` 分词。

### 4.2 9 键

- 2–9 键映射：`abc def ghi jkl mno pqrs tuv wxyz`；1 标点；0 空格；`*` 分词；`#` 符号。
- 左侧符号列：`，。？！` 可自定义。
- 候选栏：T9 数字串 → 多音节组合候选；支持简拼。
- `重输`：清空组合；`删除`：逐字。
- 长按数字键输入数字。

### 4.3 手写/笔画

- 手写：全屏画布，Pointer 采集点序列；显示笔迹；300 ms 静默后识别。
  - 识别策略（净室）：内置 30 个常用字/数字的简单模板 + 可选调用平台/本地模型；无法识别时显示“换个写法试试”，仍可清空/撤销。
  - 候选栏显示识别结果；点击上屏；支持“手写找字”面板（输入部件/拼音查字）。
- 笔画：横竖撇捺折五键 + 通配；按笔画序列匹配候选；显示笔画提示。

### 4.4 双拼/五笔

- 双拼：26 键布局，按小鹤/自然码映射解析；候选来自本地词典。
- 五笔：26 键布局，显示编码提示；支持拼音混输；四码唯一/第五码首选开关；内置少量五笔码表（演示级，标注覆盖范围）。

### 4.5 工具条/面板

默认工具条（可定制）：`logo/工具箱`、`点击说话`、`剪切板`、`翻译`、`表情`、`常用语`、`键盘选择`、`繁简`、`单手`、`手写找字`、`撤销删除`、`AI`、`收起`。
- 工具箱两页：语音输入、表情、键盘选择、智能整理、常用语、剪切板、定制工具栏、手写找字；第二页翻译、单手、键盘调节、更多设置、帮助与反馈。
- 定制工具栏：两页、左右吸附、拖拽排序、恢复默认、完成。
- 表情：Emoji（分类/最近）、表情图（本地生成的彩色占位卡片，可点插入 `[表情]`）、颜文字（分类）。
- 剪切板：历史列表（文本/图片占位）、点击插入、长按拆词、清空、跨设备 Tab。
- 常用语：列表、添加/编辑/删除、分类、插入。
- 翻译：中英互译；本地词典 + AI 可选；结果可替换/复制。
- 单手：左/右布局，键盘水平偏移；恢复。
- 悬浮：可拖动、缩放、贴边、恢复。
- 键盘调节：高度滑杆、底部间距、候选字号；实时预览；恢复默认。
- 繁简：简→繁/繁→简切换；本地映射表演示。
- 智能整理：选中文本/当前输入 → 结果面板（原文/整理后/替换/复制/重试）；离线启发式 + AI。
- AI 写作：菜单（写祝福、高赞动态、写评论、自我介绍、宴席邀请、写邮件、爆款文案）→ 结果流式；操作（重写、总结、关键点、列表、检查、复制、替换、上一条/下一条）。
- AI 聊天助手：模拟微信/QQ 会话上下文，快捷回复、百科快答；开关与场景管理。
- 语音：浮层（波形、计时、取消/完成）→ 识别中 → 结果编辑（划选修改、撤回、发送）；错误态；离线态。
- 候选详情/更多候选：分栏（全部/单字/手写找字）。
- 首次剪贴板授权弹窗；首次键盘类型选择；权限引导弹窗。

### 4.6 键盘尺寸/平板

- 手机竖屏键盘高度约屏高 38–42%；横屏约 50%；平板约 32–36%，最大宽度 960 dp。
- iPad：键盘扩展高度 320–420 pt；主 App 设置页双栏（左列表/右详情）或居中 720 pt。
- Android pad：设置页 `NavigationRail` + 内容区；键盘居中最大 960 dp。
- 分屏/悬浮窗：键盘宽度自适应，不溢出；工具条可横向滚动。

---

## 5. 本地输入引擎

### 5.1 数据

- `clones/shared/data/pinyin_dict.json`（若存在）：
  ```json
  {"version":1,"source":"jieba+pypinyin (MIT)","entries":[{"w":"你好","p":"ni hao","f":12345}, ...]}
  ```
- 至少 20,000 条词；常用单字 3,500；带频率；无声调、小写、空格分词。
- 三端各自复制到 assets（Flutter `assets/data/`，Android `app/src/main/assets/`，iOS 主 App + 扩展共享资源/框架）。
- 若文件未生成：内置 500 条常用词 + 单字，保证 demo；README 注明。

### 5.2 算法

1. 输入串按 `'` 或自动最大匹配切分为拼音音节。
2. 候选：
   - 完整拼音匹配词条（前缀/全拼）。
   - 简拼匹配（`nh`→你好）。
   - 单字按频率。
   - 英文模式：本地词表 + 前缀联想。
   - 9 键：数字串映射到多组字母，动态规划取 Top-K。
3. 排序：词频 × 长度加权 × 最近使用（MRU）× 上下文 boost（前词搭配可选用小 bigram 表）。
4. 学习：上屏词写入本地 MRU；删除词写入黑名单；个人词库优先。
5. 性能：首屏候选 < 50 ms（20k 词，内存索引）；输入延迟 < 30 ms；不在 UI 线程做全量扫描。

### 5.3 明确不做的部分

- 不复制官方 164 MB 私有词典/云候选/纠错模型。
- 不承诺与官方完全相同的候选排序；报告注明“行为级兼容、排序为净室实现”。

---

## 6. AI / 语音接入

### 6.1 配置

- 统一设置：`设置 → AI 服务`（复刻新增）：
  - Base URL（默认 `https://api.deepseek.com`）
  - Model（默认 `deepseek-chat`）
  - API Key（密码框；本地保存；不写入日志/仓库）
  - 测试连接按钮
- 构建时可通过环境变量/`--dart-define=DEEPSEEK_API_KEY=...` 注入；优先级：用户设置 > 构建注入 > 空。
- 无 Key：所有 AI 功能走本地模板/规则，并在 UI 标注“离线示例”。

### 6.2 调用

- OpenAI 兼容：`POST {base}/chat/completions`，`Authorization: Bearer`，`model`，`messages`，`stream:true`（可选）。
- 场景 system prompt 按功能区分（写作/整理/翻译/纠错/聊天）。
- 超时 20 s；错误映射：无网络/401/429/5xx；可重试。
- 不在客户端做密钥加密的虚假承诺；本地存储用平台安全存储（Android EncryptedSharedPreferences / iOS Keychain）。
- 语音：优先平台语音识别（Android `SpeechRecognizer`，iOS `SFSpeechRecognizer`）；无权限/不可用时使用演示文本并提示。录音 UI 必须真实请求权限。

### 6.3 可替换后端契约（写入 README 与报告）

```http
POST /v1/asr            multipart audio -> {text, confidence, segments[]}
POST /v1/ai/organize    {text, mode} -> {text}
POST /v1/ai/write       {action, text, context} -> {text} 或 SSE
POST /v1/ai/translate   {text, from, to} -> {text}
POST /v1/clipboard/sync {deviceId, items[]} -> {items[]}
GET  /v1/config         -> {features, limits}
Authorization: Bearer <token>
```

- 客户端 `ApiConfig.baseUrl` 可改；默认空 = 本地。
- 不得在代码中硬编码官方域名作为回退。

---

## 7. 状态与持久化

统一键（三端命名一致，便于对照）：
`onboarding_done`, `privacy_mode` (`smart`/`basic`), `keyboard_type`, `theme_mode`, `input_mode`, `fuzzy_enabled`, `fuzzy_initials`, `fuzzy_finals`, `fuzzy_syllables`, `association_enabled`, `prediction_emoji`, `prediction_image`, `prediction_kaomoji`, `key_sound`, `key_vibrate`, `key_vibrate_level`, `key_bubble`, `quick_space`, `quick_capitalize`, `quick_double_space_period`, `clipboard_candidate`, `clipboard_history`, `voice_smart_organize`, `voice_punctuation`, `voice_filler`, `voice_offline`, `voice_action_enabled`, `voice_actions`, `candidate_font_size`, `pinyin_location`, `enter_send`, `one_hand`, `floating`, `keyboard_height`, `custom_toolbar`, `common_phrases`, `personal_lexicon`, `clipboard_items`, `ai_base_url`, `ai_model`, `ai_key`, `account_logged_in`, `account_name`, `super_transfer_enabled`, `device_id`.

- 所有设置改动立即持久化；返回/重启保持。
- 首次运行有默认值（见 FINDINGS）；深色模式跟随系统。

---

## 8. 验收清单（必须逐项自测）

### 通用

- [ ] 全新安装 → 引导 → 隐私 → 主设置，全流程可完成。
- [ ] 主设置所有行可点、可返回；所有 switch 有反馈并持久化。
- [ ] 每个子页至少有一个可操作控件；无“空壳页”。
- [ ] 键盘 demo 可输入中文/英文/数字/符号；候选可上屏；删除/空格/回车工作。
- [ ] 26/9/手写/双拼/五笔 可切换；切换后立即可用。
- [ ] 工具箱 8+5 项全部可打开；每个面板可关闭回到键盘。
- [ ] 语音浮层可开始/取消/完成；权限拒绝有提示；无 AI Key 有离线结果。
- [ ] AI 写作/整理/翻译：有 Key 时真实调用；无 Key 时本地结果；错误可重试。
- [ ] 剪贴板/常用语/词库：增删改查可用。
- [ ] 主题浅色/深色/跟随系统切换即时生效。
- [ ] 单手/悬浮/键盘调节可恢复默认。
- [ ] 账号登录模拟、退出、消息中心可操作。
- [ ] 平板/横屏布局不溢出；键盘居中/最大宽度生效。
- [ ] 旋转屏幕不崩溃，状态保持。

### Android 原生

- [ ] `./gradlew assembleDebug` 成功。
- [ ] 安装后出现在系统输入法列表；启用/切换后可作为默认输入法。
- [ ] 在系统搜索框真实输入中文并上屏。
- [ ] 设置 App 与 IME 共享状态。
- [ ] pad AVD 截图。

### Flutter

- [ ] `flutter analyze` 无 error。
- [ ] `flutter build apk --debug` 成功；安装运行。
- [ ] `flutter build ios --simulator --no-codesign` 成功；iPhone 模拟器运行。
- [ ] 若实现 Android IME service：系统输入法列表可用；否则 README 明确说明“app 内键盘 demo + 后续接入说明”。
- [ ] iPad 模拟器布局截图。

### iOS 原生

- [ ] `xcodebuild` 模拟器构建成功。
- [ ] 主 App 在 iPhone 模拟器运行。
- [ ] 键盘扩展出现在“设置-通用-键盘-添加新键盘”；可在 App 内输入框调起。
- [ ] 键盘可输入中文并上屏（至少 26 键 + 候选）。
- [ ] iPad 模拟器布局截图。

### 证据

- 每个实现保存 `screenshots/01_onboarding.png` … `keyboard_*.png` 至少 15 张；
- 保存一次完整流程录屏或关键状态截图；
- README 写明已知限制（尤其：官方后端不可用、iOS 无官方 IPA、手写/五笔覆盖范围）。

---

## 9. 禁止事项

- 不提交官方 APK/IPA、反编译产物、官方资源、任何 Key。
- 不请求/绕过官方鉴权、不重放官方私有接口、不实现扫码登录官方账号。
- 不使用“豆包”官方 Logo/头像/字体作为自有商标；复刻版标注“非官方复刻”。
- 不伪造“已完成”的测试结果；未验证的功能在 README/报告中标注 `[未验证]`。
