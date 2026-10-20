import SwiftUI

struct HelpFeedbackView: View {
    @EnvironmentObject private var settings: AppSettings
    @State private var kind = "功能建议"
    @State private var text = ""
    @State private var contact = ""
    @State private var showGuide = false
    @State private var expandedFAQ: String?
    @State private var submitted = false

    private let kinds = ["功能建议", "问题反馈", "键盘扩展", "隐私相关", "其他"]
    private let faqs: [(String, String)] = [
        ("如何启用键盘扩展？", "打开系统“设置 → 通用 → 键盘 → 键盘 → 添加新键盘”，选择“豆包输入法（iOS 复刻）”。随后在输入框中长按地球键切换。"),
        ("键盘为什么没有候选？", "请确认 App 已安装且扩展随 App 一起安装；词典随扩展打包，无需联网。若仍无候选，尝试重新打开输入框。"),
        ("为什么语音在键盘里是示例？", "iOS 键盘扩展不适合直接采集长时音频。完整语音在 App 的“语音转文字 → 试说一段”中使用系统 Speech 框架；键盘内提供离线示例与状态流程。"),
        ("如何切换 9 键？", "在 App → 键盘类型选择拼音9键，或在键盘工具箱 → 键盘选择中切换，立即生效。"),
        ("剪切板历史为什么为空？", "需要开启剪切板历史，并允许键盘“完全访问”以读取 App Group 数据。iOS 首次粘贴还会弹出系统授权。"),
        ("AI 功能提示离线示例？", "未配置 DeepSeek API Key，或当前处于基础输入模式。可在 App → AI 服务中配置 Key 并切换智能输入模式。"),
        ("如何调整键盘高度？", "键盘工具栏“调节”，或 App → 布局与显示。模拟器与设备上的系统键盘高度受系统限制。"),
        ("复刻版会连接官方服务吗？", "不会。所有后端均为本地或你自行填写的第三方 AI 地址；不包含官方鉴权、私有接口或 SDK。")
    ]

    var body: some View {
        PageScaffold(title: "帮助与反馈", subtitle: "常见问题、启用指引与本地反馈") {
            Card {
                HStack(spacing: 12) {
                    Image(systemName: "keyboard")
                        .font(.system(size: 24))
                        .foregroundColor(AppTheme.primary)
                    VStack(alignment: .leading, spacing: 3) {
                        Text("键盘扩展启用指引").font(.system(size: 15, weight: .medium)).foregroundColor(AppTheme.text)
                        Text("设置 → 通用 → 键盘 → 键盘 → 添加新键盘").font(.system(size: 11)).foregroundColor(AppTheme.textSecondary)
                    }
                    Spacer()
                    Button("查看") { showGuide = true }
                        .font(.system(size: 12))
                        .foregroundColor(AppTheme.primary)
                }
            }

            Card {
                Text("常见问题")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(AppTheme.text)
                ForEach(Array(faqs.enumerated()), id: \.offset) { index, faq in
                    let open = expandedFAQ == faq.0
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            expandedFAQ = open ? nil : faq.0
                        }
                    } label: {
                        HStack(alignment: .top, spacing: 8) {
                            Text(faq.0)
                                .font(.system(size: 14))
                                .foregroundColor(AppTheme.text)
                                .multilineTextAlignment(.leading)
                            Spacer()
                            Image(systemName: open ? "chevron.up" : "chevron.down")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundColor(AppTheme.textSecondary)
                        }
                        .padding(.vertical, 10)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(RowButtonStyle())
                    if open {
                        Text(faq.1)
                            .font(.system(size: 12))
                            .foregroundColor(AppTheme.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.bottom, 10)
                    }
                    if index < faqs.count - 1 { Rectangle().fill(AppTheme.divider).frame(height: 0.5) }
                }
            }

            Card {
                Text("提交反馈")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(AppTheme.text)
                HStack(spacing: 8) {
                    ForEach(kinds, id: \.self) { item in
                        ChoiceChip(title: item, selected: kind == item) { kind = item }
                    }
                }
                TextEditor(text: $text)
                    .frame(minHeight: 100)
                    .font(.system(size: 14))
                    .padding(6)
                    .background(AppTheme.cardAlt)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .overlay(alignment: .topLeading) {
                        if text.isEmpty {
                            Text("请描述问题或建议…")
                                .font(.system(size: 13))
                                .foregroundColor(AppTheme.textSecondary)
                                .padding(12)
                                .allowsHitTesting(false)
                        }
                    }
                TextField("联系方式（可选）", text: $contact)
                    .font(.system(size: 13))
                    .padding(10)
                    .background(AppTheme.cardAlt)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                PrimaryButton(title: "提交反馈（保存到本机）", icon: "paperplane") {
                    submit()
                }
                if submitted {
                    Text("已保存到本机反馈列表，不会上传服务器。")
                        .font(.system(size: 11))
                        .foregroundColor(AppTheme.primary)
                }
            }

            if !settings.feedbacks.isEmpty {
                Card {
                    HStack {
                        Text("历史反馈")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(AppTheme.text)
                        Spacer()
                        Text("\(settings.feedbacks.count) 条")
                            .font(.system(size: 11))
                            .foregroundColor(AppTheme.textSecondary)
                    }
                    ForEach(Array(settings.feedbacks.prefix(5).enumerated()), id: \.element.id) { index, entry in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(entry.kind)
                                    .font(.system(size: 10))
                                    .foregroundColor(AppTheme.primary)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(AppTheme.accentSoft)
                                    .clipShape(Capsule())
                                Spacer()
                                Text(shortDate(entry.date))
                                    .font(.system(size: 9))
                                    .foregroundColor(AppTheme.textSecondary)
                                Button {
                                    settings.feedbacks.removeAll { $0.id == entry.id }
                                    showToast("已删除反馈")
                                } label: {
                                    Image(systemName: "trash").font(.system(size: 11)).foregroundColor(AppTheme.danger)
                                }
                            }
                            Text(entry.text)
                                .font(.system(size: 12))
                                .foregroundColor(AppTheme.text)
                                .lineLimit(3)
                        }
                        .padding(.vertical, 8)
                        if index < min(settings.feedbacks.count, 5) - 1 {
                            Rectangle().fill(AppTheme.divider).frame(height: 0.5)
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showGuide) {
            EnableKeyboardGuide()
        }
    }

    private func submit() {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            showToast("请先填写反馈内容")
            return
        }
        settings.feedbacks.insert(FeedbackEntry(kind: kind, text: trimmed, contact: contact), at: 0)
        text = ""
        contact = ""
        submitted = true
        showToast("反馈已保存到本机")
    }

    private func shortDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "MM-dd HH:mm"
        return f.string(from: date)
    }
}

struct AboutView: View {
    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var router: Router
    @State private var checking = false
    @State private var showLicenses = false
    @State private var did = UserDefaults.standard.string(forKey: "clone_did") ?? ""
    @State private var copiedDID = false

    var body: some View {
        PageScaffold(title: "关于", subtitle: "版本、构建、设备标识与开源许可") {
            VStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(LinearGradient(colors: [AppTheme.primary, Color(red: 0.58, green: 0.74, blue: 1.0)], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 92, height: 92)
                    Text("豆")
                        .font(.system(size: 44, weight: .semibold))
                        .foregroundColor(.white)
                }
                Text("豆包输入法（iOS 复刻）")
                    .font(.system(size: 21, weight: .semibold))
                    .foregroundColor(AppTheme.text)
                Text("1.5.2-clone (20261020)")
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundColor(AppTheme.textSecondary)
                Text("非官方净室复刻 · 不包含官方 APK/IPA、皮肤、字体或词典")
                    .font(.system(size: 11))
                    .foregroundColor(AppTheme.textSecondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)

            SettingGroup {
                HStack {
                    Text("构建时间").font(.system(size: 15)).foregroundColor(AppTheme.text)
                    Spacer()
                    Text("2026-10-20 20:00").font(.system(size: 12, design: .monospaced)).foregroundColor(AppTheme.textSecondary)
                }
                .padding(.vertical, 12)
                Rectangle().fill(AppTheme.divider).frame(height: 0.5)
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("设备标识 DID").font(.system(size: 15)).foregroundColor(AppTheme.text)
                        Text(did.isEmpty ? "生成中…" : did).font(.system(size: 10, design: .monospaced)).foregroundColor(AppTheme.textSecondary)
                    }
                    Spacer()
                    Button {
                        UIPasteboard.general.string = did
                        copiedDID = true
                        showToast("已复制 DID")
                    } label: {
                        Image(systemName: copiedDID ? "checkmark" : "doc.on.doc")
                            .foregroundColor(AppTheme.primary)
                    }
                }
                .padding(.vertical, 12)
                Rectangle().fill(AppTheme.divider).frame(height: 0.5)
                HStack {
                    Text("键盘扩展").font(.system(size: 15)).foregroundColor(AppTheme.text)
                    Spacer()
                    Text("随 App 安装").font(.system(size: 12)).foregroundColor(AppTheme.textSecondary)
                }
                .padding(.vertical, 12)
            }

            SettingGroup {
                ActionRow(title: checking ? "检查更新中…" : "检查更新", subtitle: "当前渠道为本地复刻版", icon: "arrow.triangle.2.circlepath", isLast: false) {
                    guard !checking else { return }
                    checking = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                        checking = false
                        showToast("已是最新版本 1.5.2-clone")
                    }
                }
                ActionRow(title: "开源许可", subtitle: "jieba / pypinyin（MIT）、系统 SF Symbols", icon: "doc.text", isLast: false) {
                    showLicenses = true
                }
                ActionRow(title: "AI 服务", subtitle: settings.aiKeyPresent ? "已配置 Keychain Key" : "未配置", icon: "sparkles", isLast: true) {
                    router.push(.aiSettings)
                }
            }

            Card {
                Text("复刻说明")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(AppTheme.text)
                Text("本项目基于公开可见的行为与截图进行净室实现。界面、键盘、拼音引擎、手写识别与本地 AI 模板均为原创代码。拼音词典来自 jieba + pypinyin 的 MIT 许可数据（33,500 条）。未使用官方图片、音频、Lottie 或私有词典。")
                    .font(.system(size: 12))
                    .foregroundColor(AppTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                Text("“豆包”名称仅用于说明复刻对象，不代表官方认可。")
                    .font(.system(size: 11))
                    .foregroundColor(AppTheme.textSecondary)
            }

            VStack(spacing: 4) {
                Text("Made as a clean-room study")
                    .font(.system(size: 10))
                    .foregroundColor(AppTheme.textSecondary)
                Text("© 2026 复刻项目 · 不使用官方商标作为自有标识")
                    .font(.system(size: 10))
                    .foregroundColor(AppTheme.textSecondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
        }
        .onAppear {
            if did.isEmpty {
                did = "DID-" + UUID().uuidString.replacingOccurrences(of: "-", with: "").prefix(16).uppercased()
                UserDefaults.standard.set(did, forKey: "clone_did")
            }
        }
        .sheet(isPresented: $showLicenses) {
            NavigationView { LicenseListView() }
        }
    }
}

struct LicenseListView: View {
    @Environment(\.presentationMode) private var presentation
    private let licenses: [(String, String, String)] = [
        ("jieba", "MIT License", "中文分词数据，用于生成共享拼音词表。"),
        ("pypinyin", "MIT License", "汉字拼音数据，用于生成拼音词条。"),
        ("Swift / SwiftUI / UIKit", "Apple Platform SDK", "界面与键盘使用系统框架。"),
        ("SF Symbols", "Apple Symbol Library", "工具栏与设置图标；仅在 Apple 平台使用。"),
        ("pinyin_dict.json", "MIT-derived data", "33,500 条词条，含词、拼音与频率；项目内再分发。"),
        ("本复刻版代码", "Original clean-room implementation", "未复制官方 APK、DEX、SO、皮肤、字体、图片、音频、Lottie 或私有词典。")
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                ForEach(Array(licenses.enumerated()), id: \.offset) { _, item in
                    Card {
                        Text(item.0).font(.system(size: 15, weight: .semibold)).foregroundColor(AppTheme.text)
                        Text(item.1).font(.system(size: 11, design: .monospaced)).foregroundColor(AppTheme.primary)
                        Text(item.2).font(.system(size: 12)).foregroundColor(AppTheme.textSecondary)
                    }
                }
                Text("完整许可文本见 clones/shared/LICENSES.md。")
                    .font(.system(size: 11))
                    .foregroundColor(AppTheme.textSecondary)
            }
            .padding(16)
        }
        .background(AppTheme.pageBg.ignoresSafeArea())
        .navigationTitle("开源许可")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("关闭") { presentation.wrappedValue.dismiss() }
            }
        }
    }
}
