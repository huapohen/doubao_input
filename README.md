# 豆包输入法 1.5.2 · REA 逆向分析与三端复刻

> 非官方、非商业的互操作性研究 + 净室复刻。  
> 目标：`com.bytedance.android.doubaoime` 1.5.2（versionCode `100502008`，官方 arm64 APK）。  
> 复刻：Flutter 通用版（Android/iOS/平板）、Android 原生版（真实系统 IME）、iOS 原生版（SwiftUI + 键盘扩展）。

**这不是官方项目，也不包含官方 APK/IPA、反编译代码、私有词典/皮肤/字体/图片/音频。**  
“豆包”“豆包输入法”商标归其权利人所有；本项目仅用于学习、互操作性与界面/交互研究。

---

## 先看什么

| 内容 | 链接 |
|---|---|
| 正式报告（推荐，带可筛选截图画廊/架构图/API 表） | [`reports/report.html`](reports/report.html) |
| 正式报告 Markdown | [`reports/REPORT.md`](reports/REPORT.md) |
| 实时进度 | [`progress.md`](progress.md) · [`progress.html`](progress.html) |
| 逆向事实集（详细证据/端点/组件） | [`analysis/FINDINGS.md`](analysis/FINDINGS.md) |
| 三端复刻规格/验收 | [`analysis/CLONE_SPEC.md`](analysis/CLONE_SPEC.md) |
| 可替换后端参考实现 | [`backend/README.md`](backend/README.md) |
| 共享词库（MIT 数据生成） | [`clones/shared/data/pinyin_dict.json`](clones/shared/data/pinyin_dict.json) |

---

## 目标与结论

- 官方 APK：170 MB、4 DEX、23,039 类、3,367 资源、70 Activity、72 Service、41 权限。
- 键盘 UI 由 APK 内 XML 皮肤 + `libkeyboard.so`（C++/JNI）驱动；离线词典 164 MB；离线语音约 7 MB。
- 功能面：9/26/手写/笔画/双拼/五笔、语音（在线/离线/标点/口水词/智能整理/口令）、AI 写作/改写/总结/要点/列表/检查/翻译/聊天助手、剪贴板、常用语、超级互传、账号同步、动态皮肤、单手/悬浮/平板。
- **官方后端不可直接复用**：域名可达，但业务接口需要设备指纹、安装 ID、签名/风控、账号 token 与 TTNet 加密；ASR/AI/表情图/登录/客服/跨端互传均依赖官方服务。
- **iOS 二进制逆向未完成**：App Store 1.6.2 存在，但本机没有授权 IPA；iOS 复刻按公开键盘扩展架构 + Android 行为实现。详见报告第 8 节。
- **复刻边界**：信息架构、页面、交互状态机、键盘行为、AI/语音流程、平板适配；引擎为净室实现（公开词频数据），候选排序不保证与官方一致。

---

## 验证结果（实机/模拟器）

| 版本 | 构建 | 运行/输入 | 截图 |
|---|---|---|---|
| Android 原生 | `assembleDebug` 成功，APK 19.7 MB | 系统 IME 启用；`ni'hao` → 候选「你好」→ 上屏 | 27 张（手机 + 平板） |
| Flutter | Android debug APK 157 MB（3 ABI）；iOS 构建/运行 | Android 9 键实验室候选 + 系统 IME「通过」；iOS 键盘 33,500 词、查询 2.2 ms | Android 11 + iPhone 15 + iPad 3 |
| iOS 原生 | `BUILD SUCCEEDED`；键盘扩展已注册 | 系统键盘扩展输入「你好」成功；iPad 双栏 + 系统键盘 | 49 张（42 iPhone + 7 iPad） |
| 参考后端 | Node 零依赖 | 无 Key 本地模板；有 Key `deepseek-flash` 真实生成 | — |

> 详细证据/命令见 `progress.md`、`reports/REPORT.md` 与各 clone 的 README。所有截图都是实际运行，不是设计稿。

---
---

## 目录

```text
rea/doubao_input/
├── analysis/
│   ├── FINDINGS.md              # 逆向事实集（组件/端点/UI/限制）
│   └── CLONE_SPEC.md            # 三端复刻规格与验收
├── evidence/                    # 本地证据（APK/反编译/原始截图，不提交）
│   ├── android/
│   ├── runtime/
│   └── ios/
├── reports/
│   ├── REPORT.md
│   ├── report.html              # 交互式报告 + 截图画廊
│   └── assets/screens/          # 67 张精选 WebP
├── progress.md / progress.html  # 实时进度
├── clones/
│   ├── shared/data/pinyin_dict.json
│   ├── flutter/                 # Flutter 通用版
│   ├── android_native/          # Android 原生版
│   └── ios_native/              # iOS 原生版
├── backend/                     # 可替换后端参考实现（Node，零依赖）
├── scripts/                     # 画廊/报告/词库生成脚本
└── README.md
```

---

## 三端复刻

### Flutter 通用版

- 目录：[`clones/flutter/`](clones/flutter/)
- 目标：Android/iOS/平板；完整设置导航；26/9/手写/双拼/五笔键盘；工具箱/表情/剪贴板/常用语；语音；AI 写作/整理/翻译；可选 Android 系统 IME。
- 构建：

```bash
cd clones/flutter
/Users/lwblx/development/flutter/bin/flutter pub get
/Users/lwblx/development/flutter/bin/flutter build apk --debug
/Users/lwblx/development/flutter/bin/flutter build ios --simulator --no-codesign
```

### Android 原生版

- 目录：[`clones/android_native/`](clones/android_native/)
- 真实 `InputMethodService`，可在系统输入法列表启用；Kotlin；手机/pad。
- 构建：

```bash
cd clones/android_native
./gradlew assembleDebug
adb install -r app/build/outputs/apk/debug/app-debug.apk
```

启用：设置 → 系统 → 语言和输入法 → 屏幕键盘 → 启用“豆包输入法（原生复刻）” → 切换。

### iOS 原生版

- 目录：[`clones/ios_native/`](clones/ios_native/)
- SwiftUI 主 App + `UIInputViewController` 键盘扩展；iPhone/iPad。
- 构建：

```bash
cd clones/ios_native
xcodebuild -project DoubaoInput.xcodeproj -scheme DoubaoInput \
  -sdk iphonesimulator -configuration Debug \
  -destination 'platform=iOS Simulator,id=6BBA0111-7B13-4830-9DB1-D651664F4381' build
```

启用键盘扩展：设置 → 通用 → 键盘 → 键盘 → 添加新键盘 → “豆包输入法（iOS 复刻）”。

> 具体可用的 scheme/路径以各项目 `README.md` 为准；构建结果与截图见 `progress.md`。

---

## AI / 后端

- 复刻默认**本地可用**；AI 通过用户自己的 OpenAI 兼容服务（可用 DeepSeek）接入。
- 设置项：`Base URL / Model / API Key`；无 Key 时所有 AI 功能返回本地模板并标注“离线示例”。
- 参考后端：

```bash
cd backend
node server.js
# 可选：DEEPSEEK_API_KEY / DEEPSEEK_BASE_URL / DEEPSEEK_MODEL
```

- 已实测：无 Key 本地模板；有 Key / `deepseek-flash` 真实生成成功（未记录 Key）。
- 接口契约见 [`backend/README.md`](backend/README.md)；后续可替换为自有服务。

**仓库不包含任何 API Key。** 不要把 Key 写入代码、`.env`（提交）、日志或截图。

---

## 复现分析

```bash
# 1) 官方下载
curl 'https://shurufa.doubao.com/api/v1/app/download_url?platform=android'

# 2) REA 包检查（需要 JADX headless MCP JAR）
export REA_JADX_MCP_JAR=/path/to/jadx-headless-mcp-0.7.1-all.jar
npx rea-agents inspect-android-package doubaoime.apk --json > inspect.json

# 3) 资源/源码
java -jar apktool.jar d -f -o decoded doubaoime.apk
jadx -d jadx_out --no-res doubaoime.apk

# 4) 运行时（Pixel 10 Pro XL API 36）
adb install -r doubaoime.apk
adb shell ime enable com.bytedance.android.doubaoime/.ImeService
adb shell ime set com.bytedance.android.doubaoime/.ImeService
```

APK SHA-256：`dd96dd84fd8e09fc98b46e71ee8df9d1a44ec8b1bfaa3e1ce1e49ddb6e56c08f`。  
分析证据与原始截图保留在本地 `evidence/`，不随公开仓库分发。

---

## 已知限制

1. 官方候选排序、云词库、纠错、手写/五笔模型不可获得；复刻为净室近似。
2. 官方 ASR/AI/登录/表情图/客服/跨端互传依赖官方后端，复刻不接入。
3. iOS 未做二进制逆向；iOS 复刻基于公开架构与 Android 行为。
4. 手写识别为演示级模板/有限字符集；五笔码表覆盖有限。
5. 字体/图标以系统/开源替代，视觉不保证逐像素一致。
6. 部分 IME 浮层按钮在模拟器上无法注入触摸，报告中如实标注 `[U]`。

---

## 合规

- 不包含/不分发官方 APK、IPA、DEX、SO、皮肤 XML、字体、词典二进制、图片、音频、Lottie。
- 不绕过官方鉴权、不重放官方私有接口、不伪造官方账号。
- 复刻版标注“非官方复刻”；仅用于学习与研究。

---

## License

自有代码：MIT（见 `LICENSE`）。  
共享词库由 jieba + pypinyin 生成（均 MIT），详见 `clones/shared/LICENSES.md`。  
系统字体/图标遵循各自许可。
