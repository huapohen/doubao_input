import SwiftUI

enum Route: String, CaseIterable, Identifiable {
    case onboarding
    case privacy
    case keyboardPicker
    case home
    case voiceSettings
    case voiceAction
    case keyboardTypes
    case doublePinyin
    case wubi
    case layout
    case fuzzy
    case association
    case prediction
    case keyFeedback
    case quickFormat
    case clipboard
    case lexicon
    case inputMode
    case smartInput
    case permissions
    case superTransfer
    case account
    case login
    case messages
    case desktop
    case help
    case about
    case keyboardDemo
    case systemKeyboardTest
    case aiSettings
    case phrases
    case aiWriting
    case smartOrganize
    case translate
    case agreement
    case privacyPolicy

    var id: String { rawValue }

    var title: String {
        switch self {
        case .onboarding: return "启用输入法"
        case .privacy: return "隐私保护指引"
        case .keyboardPicker: return "选择键盘"
        case .home: return "设置"
        case .voiceSettings: return "语音转文字"
        case .voiceAction: return "语音口令"
        case .keyboardTypes: return "键盘类型"
        case .doublePinyin: return "双拼设置"
        case .wubi: return "五笔设置"
        case .layout: return "布局与显示"
        case .fuzzy: return "模糊拼音"
        case .association: return "智能联想"
        case .prediction: return "输入预测类型"
        case .keyFeedback: return "按键反馈"
        case .quickFormat: return "快捷格式输入"
        case .clipboard: return "剪切板"
        case .lexicon: return "词库管理"
        case .inputMode: return "输入模式与信息保护"
        case .smartInput: return "智能输入设置"
        case .permissions: return "系统权限设置"
        case .superTransfer: return "超级互传"
        case .account: return "账户"
        case .login: return "登录"
        case .messages: return "消息中心"
        case .desktop: return "电脑版"
        case .help: return "帮助与反馈"
        case .about: return "关于"
        case .keyboardDemo: return "键盘实验室"
        case .systemKeyboardTest: return "系统键盘测试"
        case .aiSettings: return "AI 服务"
        case .phrases: return "常用语"
        case .aiWriting: return "AI 写作"
        case .smartOrganize: return "智能整理"
        case .translate: return "翻译"
        case .agreement: return "用户协议"
        case .privacyPolicy: return "隐私政策"
        }
    }
}

final class Router: ObservableObject {
    @Published var path: [Route] = []

    func push(_ route: Route) {
        guard route != .home else { path = []; return }
        path.append(route)
    }

    func pop() {
        if !path.isEmpty { path.removeLast() }
    }

    func reset(to route: Route? = nil) {
        path = route.map { [$0] } ?? []
    }
}

struct LaunchConfig {
    static var route: Route? {
        guard let raw = UserDefaults.standard.string(forKey: "route") else { return nil }
        return Route(rawValue: raw)
    }

    static var isScreenshot: Bool {
        ProcessInfo.processInfo.arguments.contains("-screenshot") || route != nil
    }
}

@main
struct DoubaoInputApp: App {
    @StateObject private var settings = AppSettings.shared
    @StateObject private var router = Router()
    @StateObject private var toasts = ToastCenter.shared

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(settings)
                .environmentObject(router)
                .environmentObject(toasts)
                .preferredColorScheme(colorScheme)
        }
    }

    private var colorScheme: ColorScheme? {
        switch settings.themeMode {
        case "light": return .light
        case "dark": return .dark
        default: return nil
        }
    }
}

struct RootView: View {
    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var router: Router
    @State private var launched = false
    @State private var showSplash = !LaunchConfig.isScreenshot

    var body: some View {
        ZStack {
            AppTheme.pageBg.ignoresSafeArea()
            if !settings.onboardingDone && !settings.privacyAccepted {
                OnboardingFlowView(initialStage: forcedStage)
            } else if !settings.privacyAccepted {
                PrivacyConsentView()
            } else if !settings.keyboardTypePicked {
                KeyboardTypePickerView(firstRun: true)
            } else {
                MainShell()
            }
            if showSplash {
                SplashView()
                    .transition(.opacity)
                    .zIndex(10)
            }
            ToastOverlay().zIndex(20)
        }
        .onAppear {
            prepareLaunch()
            guard showSplash else { return }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
                withAnimation(.easeOut(duration: 0.3)) { showSplash = false }
            }
        }
    }

    private var forcedStage: Int? {
        switch LaunchConfig.route {
        case .onboarding: return 0
        case .privacy: return 2
        case .keyboardPicker: return 3
        default: return nil
        }
    }

    private func prepareLaunch() {
        guard !launched else { return }
        launched = true
        guard let route = LaunchConfig.route else { return }
        if ![.onboarding, .privacy, .keyboardPicker].contains(route) {
            settings.onboardingDone = true
            settings.privacyAccepted = true
            settings.keyboardTypePicked = true
            seedDemoDataIfNeeded()
            router.reset(to: route == .home ? nil : route)
        }
    }

    private func seedDemoDataIfNeeded() {
        if settings.clipboardItems.isEmpty {
            settings.clipboardItems = [
                ClipboardItem(text: "豆包输入法（iOS 复刻）键盘扩展测试文本", date: Date().addingTimeInterval(-90)),
                ClipboardItem(text: "https://example.com/doubao-input-clone", date: Date().addingTimeInterval(-3600)),
                ClipboardItem(text: "会议纪要：周四下午三点，产品评审。", date: Date().addingTimeInterval(-7000))
            ]
        }
        if settings.personalLexicon.isEmpty {
            settings.personalLexicon = [
                LexiconEntry(word: "豆包输入法", pinyin: "dou bao shu ru fa", source: "个人"),
                LexiconEntry(word: "净室复刻", pinyin: "jing shi fu ke", source: "个人"),
                LexiconEntry(word: "林小满", pinyin: "lin xiao man", source: "通讯录")
            ]
        }
        if settings.devices.isEmpty && settings.superTransferEnabled {
            settings.devices = [DeviceRecord(name: "本机 · iPhone 17", kind: "iPhone", lastSeen: "刚刚")]
        }
    }
}

struct SplashView: View {
    @State private var appeared = false

    var body: some View {
        ZStack {
            LinearGradient(colors: [AppTheme.pageBg, AppTheme.primary.opacity(0.12)], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
            VStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(LinearGradient(colors: [AppTheme.primary, Color(red: 0.6, green: 0.76, blue: 1.0)], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 88, height: 88)
                    Text("豆")
                        .font(.system(size: 42, weight: .semibold))
                        .foregroundColor(.white)
                }
                .scaleEffect(appeared ? 1 : 0.86)
                .opacity(appeared ? 1 : 0)
                Text("豆包输入法")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(AppTheme.text)
                Text("iOS 净室复刻 · 非官方")
                    .font(.system(size: 11))
                    .foregroundColor(AppTheme.textSecondary)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.35)) { appeared = true }
        }
    }
}

struct MainShell: View {
    @EnvironmentObject private var router: Router
    @Environment(\.horizontalSizeClass) private var sizeClass

    var body: some View {
        if sizeClass == .regular {
            HStack(spacing: 0) {
                HomeView(isSidebar: true)
                    .frame(width: 390)
                    .background(AppTheme.pageBg)
                Rectangle().fill(AppTheme.divider).frame(width: 0.5)
                ZStack {
                    AppTheme.pageBg.ignoresSafeArea()
                    if let route = router.path.last {
                        destination(for: route)
                            .transition(.opacity)
                    } else {
                        VStack(spacing: 12) {
                            Image(systemName: "keyboard")
                                .font(.system(size: 46, weight: .light))
                                .foregroundColor(AppTheme.primary.opacity(0.5))
                            Text("豆包输入法（iOS 复刻）")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(AppTheme.text)
                            Text("从左侧选择设置项，或在手机端使用底部导航。")
                                .font(.system(size: 14))
                                .foregroundColor(AppTheme.textSecondary)
                        }
                    }
                }
            }
        } else {
            ZStack {
                if let route = router.path.last {
                    destination(for: route)
                        .transition(.move(edge: .trailing))
                } else {
                    HomeView(isSidebar: false)
                }
            }
        }
    }

    @ViewBuilder
    func destination(for route: Route) -> some View {
        switch route {
        case .voiceSettings: VoiceSettingsView()
        case .voiceAction: VoiceActionView()
        case .keyboardTypes: KeyboardTypesView()
        case .doublePinyin: DoublePinyinView()
        case .wubi: WubiView()
        case .layout: LayoutSettingsView()
        case .fuzzy: FuzzyPinyinView()
        case .association: AssociationSettingsView()
        case .prediction: PredictionTypesView()
        case .keyFeedback: KeyFeedbackView()
        case .quickFormat: QuickFormatView()
        case .clipboard: ClipboardSettingsView()
        case .lexicon: LexiconManagementView()
        case .inputMode: InputModeView()
        case .smartInput: SmartInputView()
        case .permissions: SystemPermissionsView()
        case .superTransfer: SuperTransferView()
        case .account: AccountView()
        case .login: LoginView()
        case .messages: MessageCenterView()
        case .desktop: DesktopAppView()
        case .help: HelpFeedbackView()
        case .about: AboutView()
        case .keyboardDemo: KeyboardDemoView()
        case .systemKeyboardTest: SystemKeyboardTestView()
        case .aiSettings: AISettingsView()
        case .phrases: PhraseManagementView()
        case .aiWriting: AIWritingView()
        case .smartOrganize: SmartOrganizeView()
        case .translate: TranslateView()
        case .agreement: LegalTextView(kind: .agreement)
        case .privacyPolicy: LegalTextView(kind: .privacy)
        case .home, .onboarding, .privacy, .keyboardPicker:
            HomeView(isSidebar: false)
        }
    }
}

// MARK: - Page scaffold

struct PageScaffold<Content: View>: View {
    @EnvironmentObject private var router: Router
    var title: String
    var subtitle: String? = nil
    var showsBack: Bool = true
    var maxWidth: CGFloat = 720
    @ViewBuilder var content: Content

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if let subtitle {
                    Text(subtitle)
                        .font(.system(size: 13))
                        .foregroundColor(AppTheme.textSecondary)
                        .padding(.horizontal, 4)
                }
                content
                Color.clear.frame(height: 24)
            }
            .frame(maxWidth: maxWidth)
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity)
        }
        .background(AppTheme.pageBg.ignoresSafeArea())
        .safeAreaInset(edge: .top, spacing: 0) {
            HStack {
                if showsBack {
                    Button {
                        router.pop()
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(AppTheme.text)
                            .frame(width: 40, height: 40)
                            .contentShape(Rectangle())
                    }
                } else {
                    Spacer().frame(width: 40)
                }
                Spacer()
                Text(title)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(AppTheme.text)
                    .lineLimit(1)
                Spacer()
                Spacer().frame(width: 40)
            }
            .frame(height: 52)
            .padding(.horizontal, 6)
            .background(AppTheme.pageBg.opacity(0.98))
            .overlay(alignment: .bottom) {
                Rectangle().fill(AppTheme.divider).frame(height: 0.5)
            }
        }
        .navigationBarHidden(true)
    }
}

struct SettingGroup<Content: View>: View {
    var title: String? = nil
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            if let title {
                Text(title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(AppTheme.textSecondary)
                    .padding(.horizontal, 4)
            }
            VStack(spacing: 0) {
                content
            }
            .padding(.horizontal, 14)
            .background(AppTheme.card)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
    }
}
