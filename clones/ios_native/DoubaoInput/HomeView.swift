import SwiftUI
import Combine

struct HomeView: View {
    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var router: Router
    @Environment(\.horizontalSizeClass) private var sizeClass
    var isSidebar: Bool = false

    @State private var bannerIndex = 0
    @State private var autoScroll = true
    private let timer = Timer.publish(every: 4.5, on: .main, in: .common).autoconnect()

    private struct Banner: Identifiable {
        let id = UUID()
        let title: String
        let subtitle: String
        let icon: String
        let tint: Color
        let route: Route
        let action: String
    }

    private var banners: [Banner] {
        [
            Banner(title: "全场景语音精准识别", subtitle: "支持中文、英语与多方言 · 键盘内可体验离线示例", icon: "waveform", tint: AppTheme.primary, route: .voiceSettings, action: "语音设置"),
            Banner(title: "智能联想", subtitle: "根据上文推荐词语、Emoji 与颜文字", icon: "text.append", tint: Color(red: 0.36, green: 0.66, blue: 0.55), route: .association, action: "去设置"),
            Banner(title: "智能文字整理", subtitle: "去掉口水词、补标点，把口语变成书面表达", icon: "wand.and.stars", tint: Color(red: 0.55, green: 0.44, blue: 0.9), route: .smartOrganize, action: "试一试"),
            Banner(title: "离线语音", subtitle: "无网络也能体验离线识别流程（演示包）", icon: "arrow.down.circle", tint: Color(red: 0.95, green: 0.58, blue: 0.32), route: .voiceSettings, action: "查看"),
            Banner(title: "超级互传", subtitle: "手机与电脑互传文字与图片", icon: "arrow.left.arrow.right", tint: Color(red: 0.25, green: 0.6, blue: 0.9), route: .superTransfer, action: "了解"),
            Banner(title: "电脑桌面端", subtitle: "macOS 与 Windows 客户端，跨端同步更顺手", icon: "desktopcomputer", tint: Color(red: 0.42, green: 0.45, blue: 0.55), route: .desktop, action: "查看")
        ]
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                header
                bannerCarousel
                keyboardShortcut
                voiceSection
                keyboardSection
                toolsSection
                privacySection
                moreSection
                footer
            }
            .frame(maxWidth: isSidebar ? .infinity : 720)
            .padding(.horizontal, 16)
            .padding(.top, isSidebar ? 14 : 8)
            .frame(maxWidth: .infinity)
        }
        .background(AppTheme.pageBg.ignoresSafeArea())
        .onReceive(timer) { _ in
            guard autoScroll, !isSidebar else { return }
            withAnimation(.easeInOut(duration: 0.35)) {
                bannerIndex = (bannerIndex + 1) % banners.count
            }
        }
        .onAppear {
            if isSidebar { autoScroll = false }
        }
    }

    private var header: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(LinearGradient(colors: [AppTheme.primary.opacity(0.9), Color(red: 0.62, green: 0.75, blue: 1.0)], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 44, height: 44)
                Text("豆")
                    .font(.system(size: 21, weight: .semibold))
                    .foregroundColor(.white)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text("豆包输入法")
                    .font(.system(size: 23, weight: .semibold))
                    .foregroundColor(AppTheme.text)
                Text("iOS 净室复刻 · 非官方版本")
                    .font(.system(size: 11))
                    .foregroundColor(AppTheme.textSecondary)
            }
            Spacer()
            Button {
                router.push(.account)
            } label: {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: settings.accountLoggedIn ? "person.crop.circle.fill" : "person.crop.circle")
                        .font(.system(size: 26, weight: .light))
                        .foregroundColor(AppTheme.text)
                        .frame(width: 44, height: 44)
                    if settings.unreadMessageCount > 0 {
                        Text("\(min(settings.unreadMessageCount, 9))")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 16, height: 16)
                            .background(AppTheme.danger)
                            .clipShape(Circle())
                            .offset(x: -2, y: 2)
                    }
                }
            }
            .accessibilityLabel("账户")
        }
    }

    private var bannerCarousel: some View {
        VStack(spacing: 6) {
            TabView(selection: $bannerIndex) {
                ForEach(Array(banners.enumerated()), id: \.offset) { index, banner in
                    Button {
                        router.push(banner.route)
                    } label: {
                        ZStack(alignment: .bottomLeading) {
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .fill(LinearGradient(colors: [banner.tint.opacity(0.20), banner.tint.opacity(0.06)], startPoint: .topLeading, endPoint: .bottomTrailing))
                            HStack(alignment: .center, spacing: 14) {
                                VStack(alignment: .leading, spacing: 7) {
                                    Text(banner.title)
                                        .font(.system(size: 19, weight: .semibold))
                                        .foregroundColor(AppTheme.text)
                                    Text(banner.subtitle)
                                        .font(.system(size: 12))
                                        .foregroundColor(AppTheme.textSecondary)
                                        .lineLimit(2)
                                        .multilineTextAlignment(.leading)
                                    HStack(spacing: 4) {
                                        Text(banner.action)
                                        Image(systemName: "chevron.right").font(.system(size: 9, weight: .bold))
                                    }
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(banner.tint)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 5)
                                    .background(banner.tint.opacity(0.12))
                                    .clipShape(Capsule())
                                }
                                Spacer(minLength: 0)
                                ZStack {
                                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                                        .fill(banner.tint.opacity(0.16))
                                        .frame(width: 86, height: 86)
                                    Image(systemName: banner.icon)
                                        .font(.system(size: 38, weight: .light))
                                        .foregroundColor(banner.tint)
                                }
                            }
                            .padding(18)
                        }
                        .frame(height: isSidebar ? 132 : 142)
                    }
                    .buttonStyle(ScaleButtonStyle())
                    .tag(index)
                }
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            .frame(height: isSidebar ? 132 : 142)
            HStack(spacing: 5) {
                ForEach(0..<banners.count, id: \.self) { index in
                    Capsule()
                        .fill(index == bannerIndex ? AppTheme.primary : AppTheme.textSecondary.opacity(0.25))
                        .frame(width: index == bannerIndex ? 14 : 5, height: 5)
                        .animation(.easeOut(duration: 0.2), value: bannerIndex)
                }
            }
            .frame(maxWidth: .infinity)
        }
    }

    private var keyboardShortcut: some View {
        Button {
            router.push(.keyboardDemo)
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(AppTheme.primary)
                        .frame(width: 52, height: 52)
                    Image(systemName: "keyboard")
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(.white)
                }
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Text("键盘实验室")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(AppTheme.text)
                        Text("可输入")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(AppTheme.primary)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(AppTheme.accentSoft)
                            .clipShape(Capsule())
                    }
                    Text("26 键 / 9 键 / 手写 / 双拼 / 五笔 · 候选、语音、表情、剪切板")
                        .font(.system(size: 12))
                        .foregroundColor(AppTheme.textSecondary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(AppTheme.textSecondary.opacity(0.6))
            }
            .padding(14)
            .background(AppTheme.card)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .buttonStyle(ScaleButtonStyle())
    }

    private var voiceSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            SectionTitle(title: "语音输入", icon: "mic")
            SettingGroup {
                NavRow(title: "语音转文字", subtitle: "标点、口水词、离线语音、智能整理", icon: "waveform", isLast: true) {
                    router.push(.voiceSettings)
                }
            }
        }
    }

    private var keyboardSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            SectionTitle(title: "键盘输入", icon: "keyboard")
            SettingGroup {
                NavRow(title: "键盘类型", subtitle: "9键、26键、手写、双拼、五笔", icon: "square.grid.2x2", isLast: false) {
                    router.push(.keyboardTypes)
                }
                NavRow(title: "布局与显示", subtitle: "候选字号、外观、键盘高度", icon: "rectangle.3.group", isLast: false) {
                    router.push(.layout)
                }
                NavRow(title: "模糊拼音", subtitle: "例如 z=zh、in=ing、n=l", value: settings.fuzzyEnabled ? "已开启" : "已关闭", icon: "textformat.abc", isLast: false) {
                    router.push(.fuzzy)
                }
                NavRow(title: "智能联想", subtitle: "根据上文推荐词语、表情与符号", value: settings.associationEnabled ? "已开启" : "已关闭", icon: "text.append", isLast: false) {
                    router.push(.association)
                }
                NavRow(title: "输入预测类型", subtitle: "Emoji、图片表情、颜文字", icon: "face.smiling", isLast: false) {
                    router.push(.prediction)
                }
                NavRow(title: "按键反馈", subtitle: "声音、振动、气泡与响应速度", icon: "hand.tap", isLast: false) {
                    router.push(.keyFeedback)
                }
                NavRow(title: "快捷格式输入", subtitle: "中英数空格、首字母大写、双击空格句号", icon: "text.badge.checkmark", isLast: false) {
                    router.push(.quickFormat)
                }
                ToggleRow(title: "辅助输入", subtitle: "候选栏显示剪切板、验证码等辅助建议", isOn: $settings.auxiliaryInput, isLast: true) { on in
                    showToast(on ? "辅助输入已开启" : "辅助输入已关闭")
                }
            }
        }
    }

    private var toolsSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            SectionTitle(title: "工具", icon: "wrench.and.screwdriver")
            SettingGroup {
                NavRow(title: "超级互传", subtitle: settings.superTransferEnabled ? "已启用 · 本机可被发现" : "手机与电脑互传文字、图片", value: settings.superTransferEnabled ? "已启用" : "未启用", icon: "arrow.left.arrow.right", isLast: false) {
                    router.push(.superTransfer)
                }
                NavRow(title: "剪切板", subtitle: "候选栏展示、历史记录与清空", value: settings.clipboardItems.isEmpty ? nil : "\(settings.clipboardItems.count) 条", icon: "doc.on.clipboard", isLast: false) {
                    router.push(.clipboard)
                }
                ToggleRow(title: "验证码填充", subtitle: "在系统键盘中识别短信验证码（iOS 受系统限制，仅作说明）", isOn: $settings.verificationFill, isLast: false) { on in
                    showToast(on ? "已开启验证码辅助（受系统限制）" : "已关闭验证码辅助")
                }
                ToggleRow(title: "导入通讯录人名", subtitle: "仅在本地匹配联系人姓名，帮助你更快选中", isOn: $settings.contactsImport, isLast: false) { on in
                    showToast(on ? "已开启：仅本地匹配" : "已关闭通讯录人名导入")
                }
                NavRow(title: "词库管理", subtitle: "个人词库、通讯录词库与清空", value: "\(settings.personalLexicon.count)", icon: "books.vertical", isLast: false) {
                    router.push(.lexicon)
                }
                NavRow(title: "常用语", subtitle: "常用回复、分类与插入", value: "\(settings.commonPhrases.count)", icon: "text.bubble", isLast: true) {
                    router.push(.phrases)
                }
            }
        }
    }

    private var privacySection: some View {
        VStack(alignment: .leading, spacing: 6) {
            SectionTitle(title: "隐私与权限", icon: "lock.shield")
            SettingGroup {
                NavRow(title: "输入模式与信息保护", subtitle: settings.isSmartMode ? "智能输入模式 · 部分能力使用云端" : "基础输入模式 · 仅本地处理", value: settings.privacyMode == "smart" ? "智能" : "基础", icon: "checkmark.shield", isLast: false) {
                    router.push(.inputMode)
                }
                ToggleRow(title: "加入体验改进计划", subtitle: "匿名统计崩溃与性能数据（本地演示开关）", isOn: $settings.feedbackEnabled, isLast: false) { on in
                    showToast(on ? "已加入体验改进计划" : "已退出体验改进计划")
                }
                NavRow(title: "系统权限设置", subtitle: "麦克风、语音识别、通讯录、通知", icon: "hand.raised", isLast: true) {
                    router.push(.permissions)
                }
            }
        }
    }

    private var moreSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            SectionTitle(title: "更多", icon: "ellipsis.circle")
            SettingGroup {
                NavRow(title: "AI 服务", subtitle: "DeepSeek Base URL、模型与本地 Keychain Key", value: settings.aiKeyPresent ? "已配置" : "未配置", icon: "sparkles", isLast: false) {
                    router.push(.aiSettings)
                }
                NavRow(title: "AI 写作 / 整理 / 翻译", subtitle: "有 Key 时调用云端，无 Key 时使用本地示例", icon: "wand.and.stars", isLast: false) {
                    router.push(.aiWriting)
                }
                NavRow(title: "电脑版", subtitle: "macOS 与 Windows 客户端", icon: "desktopcomputer", isLast: false) {
                    router.push(.desktop)
                }
                NavRow(title: "帮助与反馈", subtitle: "常见问题、提交反馈与启用指引", icon: "questionmark.circle", isLast: false) {
                    router.push(.help)
                }
                NavRow(title: "关于", subtitle: "1.5.2-clone · 构建信息与开源许可", icon: "info.circle", isLast: true) {
                    router.push(.about)
                }
            }
        }
    }

    private var footer: some View {
        VStack(spacing: 4) {
            Text("豆包输入法（iOS 复刻）· 非官方净室实现")
                .font(.system(size: 11))
                .foregroundColor(AppTheme.textSecondary)
            Text("本应用不包含官方 APK/IPA、皮肤、字体或词典")
                .font(.system(size: 10))
                .foregroundColor(AppTheme.textSecondary.opacity(0.8))
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 8)
        .padding(.bottom, 24)
    }
}
