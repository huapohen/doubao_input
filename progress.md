# 项目进度 · 豆包输入法逆向与三端复刻

> 最后更新：2026-10-20 21:00（Asia/Shanghai）  
> 总目录：`rea/doubao_input/`  
> 报告：[`reports/REPORT.md`](reports/REPORT.md) · [`reports/report.html`](reports/report.html)  
> 事实集：[`analysis/FINDINGS.md`](analysis/FINDINGS.md) · 规格：[`analysis/CLONE_SPEC.md`](analysis/CLONE_SPEC.md)

---

## 总览

| 阶段 | 状态 | 进度 | 产物 |
|---|---|---:|---|
| 1. 官方 APK 获取与身份 | 完成 | 100% | `evidence/android/*.apk`、`rea_inspect.json` |
| 2. Android 静态逆向 | 完成 | 100% | `decoded/`、`jadx_out/`、`FINDINGS.md` |
| 3. Android 运行时取证 | 完成 | 95% | 122 张截图、UI 层级、关键浮层 |
| 4. iOS 可行性 | 完成（受限） | 100% | App Store 元数据 + 限制说明 |
| 5. 报告（MD/HTML） | 初稿完成 | 75% | `reports/REPORT.md`、`reports/report.html` |
| 6. Flutter 复刻 | 已构建 | 95% | `clones/flutter/` APK + iOS 10 截图 + Android 8 截图 |
| 7. Android 原生复刻 | 已验证 | 100% | `clones/android_native/` 真实 IME + 27 截图 + 平板 + AI mock |
| 8. iOS 原生复刻 | 已构建 | 100% | 49 截图（42 iPhone + 7 iPad），系统键盘扩展已验证 |
| 9. 平板/横屏适配 | 完成 | 90% | Android tablet + iPad 双栏/系统键盘 |
| 10. 端到端验证 | 进行中 | 80% | 输入/构建/截图已验证；AI 真调待 Key |
| 11. 公开仓库推送 | 完成 | 100% | https://github.com/huapohen/doubao_input |

---

## 已完成的关键事实

- 官方 APK：`1.5.2` / `100502008` / arm64 / 170 MB / SHA-256 `dd96dd84…e56c08f`。
- 23,039 个类、3,367 个资源、70 Activity、72 Service、41 权限。
- 键盘 UI 由 `assets/skin/default/*.xml` + `libkeyboard.so` 驱动；`KeyboardJni` 暴露 50+ 功能键。
- 离线资源：`assets/dict` 164 MB（34 文件）、`assets/skin` 1.3 MB、`assets/lottie` 3.7 MB。
- 已逐页截图：主设置、语音设置、键盘类型、双拼、五笔、布局、模糊拼音、按键反馈、输入预测、超级互传、剪切板、词库、输入模式、系统权限、账号、登录、帮助、关于、电脑版、26/9/手写键盘、工具箱、表情、语音浮层、剪贴板授权。
- 后端：`ime.doubao.com` / `ime-gw.oceancloudapi.com` / `speech.bytedance.com`；业务接口需要签名/账号/设备绑定，不可直接复用。
- iOS：App Store 1.6.2 存在；本机无授权 IPA，二进制逆向未做；复刻按公开键盘扩展架构实现。
- 复刻词库：`clones/shared/data/pinyin_dict.json`，33,500 条，1.3 MB，来自 jieba + pypinyin（MIT）。

---

## 当前进行中

### Flutter 通用版（已构建）
- 目录：`clones/flutter/`
- Android APK：`build/app/outputs/flutter-apk/app-debug.apk`（157 MB debug，含 3 ABI）。
- iOS：iPhone 17e 已运行；15 张截图 + iPad 3 张；本地词库 33,500 条，加载 111–139 ms。
- Android：已安装 emulator-5560；11 张截图（系统 IME「通过」、9 键实验室、设置）；修复 overflow。
- 系统 IME：`android/app/src/main/kotlin/.../DoubaoImeService.kt` 已加入；Kotlin 编译通过。

### Android 原生版
- 目录：`clones/android_native/`
- 目标：真实 `InputMethodService`；Kotlin；系统输入法可选中；全部设置页；手机/pad。
- 验收：`assembleDebug`、安装到 emulator-5556、启用 IME、在系统搜索框输入中文、截图 ≥15 张 + 平板 ≥5 张。

### iOS 原生版（已验证）
- 目录：`clones/ios_native/`
- `BUILD SUCCEEDED`；49 张截图（42 iPhone + 7 iPad）。
- 系统键盘扩展已注册；系统键盘输入「你好」并上屏；iPad 双栏 + 系统键盘可调起。
- 已知限制：手写/五笔/双拼为演示级；真实云端 AI 需用户 Key。

---

## 最近操作日志

| 时间 | 操作 | 结果 |
|---|---|---|
| 19:43 | 建立 `rea/doubao_input` 目录 | 完成 |
| 19:44 | 官方 APK 下载 | 170 MB，SHA-256 记录 |
| 19:45 | apktool / JADX / REA 分析 | 完成 |
| 19:50 | 首次运行时引导/隐私截图 | 完成 |
| 20:00 | 26/9/手写键盘、工具箱、表情、剪贴板、语音浮层 | 完成 |
| 20:04 | 创建专用 AVD `Doubao_IME_API_36` | 完成 |
| 20:05 | 生成复刻词库 | 33,500 条 |
| 20:06 | 三端复刻子代理启动 | 进行中 |
| 20:09 | 报告 MD/HTML 初稿 + 61 张精选截图 | 完成 |
| 20:10 | Android tablet AVD 启动 | 进行中 |
| 20:20 | 平板 6 张运行时截图（设置/悬浮键盘/工具箱/9键） | 完成 |
| 20:24 | 参考后端本地/DeepSeek 双模式验证 | 完成（Key 未入库） |
| 20:28 | HTML 报告画廊/筛选/灯箱/7 张 Mermaid 图 | 完成 |
| 20:22 | iOS 构建成功（app + 键盘扩展已注册） | 完成 |
| 20:23 | iOS 30 张页面截图 | 完成（iPhone） |
| 20:24 | Android APK 首次产出（UI 编译迭代中） | 进行中 |
| 20:25 | Flutter 键盘 demo 页面/路由补齐 | 构建中 |
| 20:26 | 专用 iPhone 17e 分配给 Flutter，避免模拟器抢占 | 完成 |
| 21:03 | Android 原生真实 IME 中文上屏 + 平板 | 完成 |
| 21:04 | Flutter Android 系统 IME 输入「通过」 | 完成 |
| 21:05 | iOS 系统键盘扩展输入「你好」+ iPad 双栏 | 完成 |
| 21:06 | 推送公开仓库 | 完成 |

---

## 待办

- [ ] 三端 clone 构建成功并产出截图（子代理进行中）
- [ ] Android tablet AVD 上复刻版/官方版 pad 截图
- [ ] iPad 模拟器上 Flutter/iOS 复刻版截图
- [ ] 端到端输入测试：26 键中文、9 键、手写、候选上屏、AI 调用
- [ ] 更新报告中的 clone 状态与验证结果
- [ ] 清理构建产物/密钥，检查 `.gitignore`
- [ ] 初始化 Git 仓库并推送到 `https://github.com/huapohen/doubao_input`
- [ ] 公开仓库最终校验（无 APK/IPA/Key/反编译产物）

---

## 证据计数

| 类型 | 数量 |
|---|---:|
| 运行时原始截图 | 122 |
| HTML 精选截图 | 61 |
| 设置页截图 | 33 |
| 键盘/浮层截图 | 22 |
| 引导截图 | 6 |
| API 端点（观察） | 35+ |
| JADX Java 文件 | 23,092 |
| 官方类总数 | 23,039 |
