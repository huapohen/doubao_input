import SwiftUI

struct OnboardingFlowView: View {
    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var router: Router
    var initialStage: Int? = nil

    @State private var stage: Int = 0
    @State private var didSetInitial = false

    var body: some View {
        ZStack {
            AppTheme.pageBg.ignoresSafeArea()
            VStack(spacing: 0) {
                HStack {
                    Text("豆包输入法（iOS 复刻）")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(AppTheme.textSecondary)
                    Spacer()
                    Text("非官方复刻")
                        .font(.system(size: 11))
                        .foregroundColor(AppTheme.textSecondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(AppTheme.card)
                        .clipShape(Capsule())
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)

                if stage == 0 {
                    EnableKeyboardStep {
                        withAnimation(.easeInOut(duration: 0.25)) { stage = 1 }
                    }
                } else if stage == 1 {
                    SwitchKeyboardStep {
                        withAnimation(.easeInOut(duration: 0.25)) { stage = 2 }
                    } onBack: {
                        withAnimation(.easeInOut(duration: 0.25)) { stage = 0 }
                    }
                } else if stage == 2 {
                    PrivacyConsentView(isOnboarding: true) {
                        withAnimation(.easeInOut(duration: 0.25)) { stage = 3 }
                    }
                } else {
                    KeyboardTypePickerView(firstRun: true) {
                        settings.keyboardTypePicked = true
                        settings.completeOnboarding()
                        router.reset()
                    }
                }
            }
        }
        .onAppear {
            if !didSetInitial {
                stage = initialStage ?? 0
                didSetInitial = true
            }
        }
    }
}

struct EnableKeyboardStep: View {
    @Environment(\.horizontalSizeClass) private var sizeClass
    @State private var showDetail = false
    var onNext: () -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 22) {
                Spacer(minLength: 24)
                ZStack {
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .fill(LinearGradient(colors: [AppTheme.primary.opacity(0.18), AppTheme.primary.opacity(0.04)], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 210, height: 160)
                    VStack(spacing: 8) {
                        Image(systemName: "keyboard")
                            .font(.system(size: 54, weight: .light))
                            .foregroundColor(AppTheme.primary)
                        HStack(spacing: 5) {
                            ForEach(0..<5) { i in
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(AppTheme.primary.opacity(0.3 + Double(i) * 0.1))
                                    .frame(width: 18, height: 10)
                            }
                        }
                    }
                }
                VStack(spacing: 8) {
                    Text("启用豆包输入法")
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundColor(AppTheme.text)
                    Text("在系统设置中添加键盘，即可在任意 App 中使用 26 键、9 键、手写与双拼。")
                        .font(.system(size: 14))
                        .foregroundColor(AppTheme.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 28)
                }

                VStack(alignment: .leading, spacing: 12) {
                    StepLine(number: 1, text: "打开“设置 → 通用 → 键盘 → 键盘”")
                    StepLine(number: 2, text: "点击“添加新键盘”")
                    StepLine(number: 3, text: "选择“豆包输入法（iOS 复刻）”")
                }
                .padding(18)
                .frame(maxWidth: 560, alignment: .leading)
                .background(AppTheme.card)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .padding(.horizontal, 20)

                VStack(spacing: 10) {
                    PrimaryButton(title: "打开系统设置", icon: "gear") {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                        showToast("已打开系统设置")
                    }
                    Button {
                        showDetail = true
                    } label: {
                        Text("查看图文启用指引")
                            .font(.system(size: 13))
                            .foregroundColor(AppTheme.primary)
                    }
                }
                .frame(maxWidth: 520)
                .padding(.horizontal, 24)

                Button(action: onNext) {
                    HStack(spacing: 4) {
                        Text("下一步")
                        Image(systemName: "arrow.right")
                    }
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(AppTheme.textSecondary)
                    .padding(.vertical, 10)
                }
                Spacer(minLength: 20)
            }
            .frame(maxWidth: 720)
            .frame(maxWidth: .infinity)
        }
        .sheet(isPresented: $showDetail) {
            EnableKeyboardGuide()
        }
    }
}

struct SwitchKeyboardStep: View {
    @State private var acknowledged = false
    var onNext: () -> Void
    var onBack: () -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 22) {
                Spacer(minLength: 20)
                ZStack {
                    RoundedRectangle(cornerRadius: 26, style: .continuous)
                        .fill(AppTheme.card)
                        .frame(width: 240, height: 150)
                    HStack(spacing: 10) {
                        globeIcon
                        Image(systemName: "arrow.right")
                            .foregroundColor(AppTheme.primary)
                        VStack(spacing: 5) {
                            ForEach(0..<2) { i in
                                HStack(spacing: 4) {
                                    ForEach(0..<4) { j in
                                        RoundedRectangle(cornerRadius: 3)
                                            .fill(i == 0 ? AppTheme.primary.opacity(0.5) : AppTheme.textSecondary.opacity(0.22))
                                            .frame(width: 22, height: 16)
                                    }
                                }
                            }
                            Text("豆包输入法")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(AppTheme.text)
                        }
                    }
                }
                Text("切换到豆包输入法")
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundColor(AppTheme.text)
                Text("在任意输入框中长按地球键，选择“豆包输入法（iOS 复刻）”。")
                    .font(.system(size: 14))
                    .foregroundColor(AppTheme.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)

                VStack(alignment: .leading, spacing: 14) {
                    StepLine(number: 1, text: "点击任意输入框，调起键盘")
                    StepLine(number: 2, text: "长按左下角地球键")
                    StepLine(number: 3, text: "选择“豆包输入法（iOS 复刻）”")
                }
                .padding(18)
                .frame(maxWidth: 560, alignment: .leading)
                .background(AppTheme.card)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .padding(.horizontal, 20)

                Toggle(isOn: $acknowledged) {
                    Text("我已添加并切换到豆包输入法")
                        .font(.system(size: 14))
                        .foregroundColor(AppTheme.text)
                }
                .tint(AppTheme.primary)
                .padding(.horizontal, 30)

                PrimaryButton(title: "继续", icon: "arrow.right", enabled: true) {
                    onNext()
                }
                .frame(maxWidth: 520)
                .padding(.horizontal, 24)
                Button("上一步", action: onBack)
                    .font(.system(size: 13))
                    .foregroundColor(AppTheme.textSecondary)
                Spacer(minLength: 20)
            }
            .frame(maxWidth: 720)
            .frame(maxWidth: .infinity)
        }
    }

    private var globeIcon: some View {
        ZStack {
            Circle().fill(AppTheme.primary.opacity(0.12)).frame(width: 58, height: 58)
            Image(systemName: "globe")
                .font(.system(size: 27, weight: .light))
                .foregroundColor(AppTheme.primary)
        }
    }
}

struct StepLine: View {
    var number: Int
    var text: String

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Text("\(number)")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.white)
                .frame(width: 22, height: 22)
                .background(AppTheme.primary)
                .clipShape(Circle())
            Text(text)
                .font(.system(size: 14))
                .foregroundColor(AppTheme.text)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
    }
}

struct PrivacyConsentView: View {
    @EnvironmentObject private var settings: AppSettings
    var isOnboarding: Bool = false
    var onComplete: (() -> Void)? = nil
    @State private var legalKind: LegalTextView.Kind?
    @State private var showPermissions = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                if !isOnboarding {
                    Text("隐私保护指引")
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundColor(AppTheme.text)
                        .padding(.top, 24)
                } else {
                    Text("隐私保护指引")
                        .font(.system(size: 26, weight: .semibold))
                        .foregroundColor(AppTheme.text)
                        .padding(.top, 8)
                }
                Text("请选择输入模式。你可以随时在“输入模式与信息保护”中更改。")
                    .font(.system(size: 14))
                    .foregroundColor(AppTheme.textSecondary)

                modeCard(
                    icon: "sparkles",
                    title: "智能输入模式",
                    badge: "推荐",
                    details: [
                        "使用云端 AI 进行写作、整理、翻译与智能联想",
                        "语音识别可使用系统服务",
                        "输入内容仅在请求时上传，不用于训练",
                        "可在设置中关闭云端能力"
                    ],
                    selected: settings.privacyMode == "smart"
                ) {
                    settings.privacyMode = "smart"
                    settings.inputMode = "smart"
                }

                modeCard(
                    icon: "lock.shield",
                    title: "基础输入模式",
                    badge: "仅本地",
                    details: [
                        "拼音、9键、手写、双拼、五笔完全本地运行",
                        "不使用云端 AI、语音或翻译",
                        "相关入口仍可进入，但会提示需开启智能输入模式",
                        "适合对隐私要求极高的场景"
                    ],
                    selected: settings.privacyMode == "basic"
                ) {
                    settings.privacyMode = "basic"
                    settings.inputMode = "basic"
                }

                VStack(spacing: 10) {
                    PrimaryButton(title: "同意并继续", icon: "checkmark") {
                        accept(mode: "smart")
                    }
                    SecondaryButton(title: "拒绝并进入基础模式", icon: "lock") {
                        accept(mode: "basic")
                    }
                }
                .padding(.top, 4)

                HStack(spacing: 14) {
                    Button("用户协议") { legalKind = .agreement }
                    Button("隐私政策") { legalKind = .privacy }
                    Button("权限清单") { showPermissions = true }
                }
                .font(.system(size: 12))
                .foregroundColor(AppTheme.primary)
                .frame(maxWidth: .infinity)

                Text("点击同意即表示你已阅读并理解上述协议。本复刻版不连接豆包官方服务器，不在代码或仓库中保存任何 API Key。")
                    .font(.system(size: 11))
                    .foregroundColor(AppTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 20)
            }
            .frame(maxWidth: 620)
            .padding(.horizontal, 20)
            .frame(maxWidth: .infinity)
        }
        .sheet(item: $legalKind) { kind in
            NavigationView {
                LegalTextView(kind: kind, showsClose: true)
            }
        }
        .sheet(isPresented: $showPermissions) {
            NavigationView {
                PermissionListSheet()
            }
        }
    }

    private func accept(mode: String) {
        settings.privacyMode = mode
        settings.inputMode = mode
        settings.privacyAccepted = true
        if let onComplete {
            onComplete()
        } else {
            settings.completeOnboarding()
        }
        showToast(mode == "smart" ? "已启用智能输入模式" : "已进入基础输入模式")
    }

    private func modeCard(icon: String, title: String, badge: String, details: [String], selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(AppTheme.primary)
                    Text(title)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(AppTheme.text)
                    Text(badge)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(AppTheme.primary)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 2)
                        .background(AppTheme.accentSoft)
                        .clipShape(Capsule())
                    Spacer()
                    RadioCircle(selected: selected)
                }
                ForEach(details, id: \.self) { item in
                    HStack(alignment: .top, spacing: 6) {
                        Circle().fill(AppTheme.primary.opacity(0.45)).frame(width: 4, height: 4).padding(.top, 6)
                        Text(item)
                            .font(.system(size: 12))
                            .foregroundColor(AppTheme.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
            .padding(16)
            .background(AppTheme.card)
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(selected ? AppTheme.primary : AppTheme.divider, lineWidth: selected ? 1.5 : 0.5)
            )
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

struct KeyboardTypePickerView: View {
    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var router: Router
    var firstRun: Bool = false
    var onFinish: (() -> Void)? = nil
    @State private var selection: KeyboardKind = .pinyin26

    private let columns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if !firstRun {
                    HStack {
                        Button {
                            router.pop()
                        } label: {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(AppTheme.text)
                                .frame(width: 40, height: 40)
                        }
                        Spacer()
                        Text("键盘类型")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(AppTheme.text)
                        Spacer()
                        Spacer().frame(width: 40)
                    }
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text(firstRun ? "选择你的主键盘" : "主键盘选择")
                        .font(.system(size: firstRun ? 26 : 20, weight: .semibold))
                        .foregroundColor(AppTheme.text)
                    Text("选择后立即生效，并同步到键盘扩展。双拼与五笔为演示级编码覆盖。")
                        .font(.system(size: 12))
                        .foregroundColor(AppTheme.textSecondary)
                }
                .padding(.top, firstRun ? 16 : 0)

                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(KeyboardKind.allCases) { kind in
                        keyboardCard(kind)
                    }
                }

                if selection == .shuangpin {
                    Card {
                        Text("双拼方案")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(AppTheme.text)
                        HStack(spacing: 8) {
                            ChoiceChip(title: "小鹤双拼", selected: settings.doublePinyinScheme == "xiaohe") {
                                settings.doublePinyinScheme = "xiaohe"
                                showToast("已选择小鹤双拼")
                            }
                            ChoiceChip(title: "自然码", selected: settings.doublePinyinScheme == "natural") {
                                settings.doublePinyinScheme = "natural"
                                showToast("已选择自然码")
                            }
                        }
                    }
                }
                if selection == .wubi {
                    Card {
                        Text("五笔为演示级码表（约 250 个常用字），支持拼音混输。完整设置见五笔页。")
                            .font(.system(size: 12))
                            .foregroundColor(AppTheme.textSecondary)
                        SecondaryButton(title: "打开五笔设置") {
                            router.push(.wubi)
                        }
                    }
                }

                if firstRun {
                    PrimaryButton(title: "开始使用", icon: "arrow.right") {
                        settings.keyboardType = selection
                        settings.keyboardTypePicked = true
                        showToast("已选择\(selection.title)")
                        onFinish?()
                    }
                    .padding(.top, 4)
                } else {
                    PrimaryButton(title: "完成", icon: "checkmark") {
                        settings.keyboardType = selection
                        settings.keyboardTypePicked = true
                        showToast("已切换为\(selection.title)")
                        router.pop()
                    }
                }
                Spacer(minLength: 20)
            }
            .frame(maxWidth: 720)
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity)
        }
        .background(AppTheme.pageBg.ignoresSafeArea())
        .onAppear { selection = settings.keyboardType }
        .onChange(of: settings.keyboardType) { newValue in selection = newValue }
        .navigationBarHidden(true)
    }

    private func keyboardCard(_ kind: KeyboardKind) -> some View {
        let selected = selection == kind
        return Button {
            selection = kind
            settings.keyboardType = kind
            settings.keyboardTypePicked = true
            showToast("已选择\(kind.title)")
        } label: {
            VStack(alignment: .leading, spacing: 10) {
                KeyboardPreview(kind: kind, selected: selected)
                    .frame(height: 100)
                HStack(spacing: 8) {
                    RadioCircle(selected: selected)
                    Text(kind.title)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(selected ? AppTheme.primary : AppTheme.text)
                    Spacer()
                    if kind == .shuangpin || kind == .wubi {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(AppTheme.textSecondary)
                    }
                }
            }
            .padding(12)
            .background(AppTheme.card)
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(selected ? AppTheme.primary : AppTheme.divider, lineWidth: selected ? 1.5 : 0.5)
            )
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .buttonStyle(ScaleButtonStyle())
        .simultaneousGesture(TapGesture().onEnded {
            if (kind == .shuangpin || kind == .wubi) && selected {
                router.push(kind == .shuangpin ? .doublePinyin : .wubi)
            }
        })
    }
}

struct KeyboardPreview: View {
    var kind: KeyboardKind
    var selected: Bool

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(selected ? AppTheme.primary.opacity(0.08) : AppTheme.cardAlt)
            switch kind {
            case .pinyin9:
                t9Preview
            case .handwriting:
                handwritingPreview
            case .stroke:
                strokePreview
            default:
                qwertyPreview
            }
        }
    }

    private var qwertyPreview: some View {
        VStack(spacing: 3) {
            ForEach(0..<3) { row in
                HStack(spacing: 3) {
                    ForEach(Array(0..<(row == 2 ? 7 : 9)), id: \.self) { _ in
                        RoundedRectangle(cornerRadius: 2)
                            .fill(AppTheme.card)
                            .frame(height: 15)
                    }
                }
            }
            HStack(spacing: 3) {
                RoundedRectangle(cornerRadius: 2).fill(AppTheme.keyFunctionPreview).frame(width: 20, height: 15)
                RoundedRectangle(cornerRadius: 2).fill(AppTheme.card).frame(height: 15)
                RoundedRectangle(cornerRadius: 2).fill(AppTheme.keyFunctionPreview).frame(width: 20, height: 15)
            }
        }
        .padding(8)
    }

    private var t9Preview: some View {
        HStack(spacing: 4) {
            VStack(spacing: 3) {
                ForEach(0..<4) { _ in
                    RoundedRectangle(cornerRadius: 2).fill(AppTheme.keyFunctionPreview).frame(width: 12, height: 16)
                }
            }
            VStack(spacing: 3) {
                ForEach(0..<4) { row in
                    HStack(spacing: 3) {
                        ForEach(0..<3) { _ in
                            RoundedRectangle(cornerRadius: 2).fill(AppTheme.card).frame(width: 20, height: 16)
                        }
                    }
                }
            }
            VStack(spacing: 3) {
                RoundedRectangle(cornerRadius: 2).fill(AppTheme.keyFunctionPreview).frame(width: 18, height: 16)
                RoundedRectangle(cornerRadius: 2).fill(AppTheme.keyFunctionPreview).frame(width: 18, height: 16)
                RoundedRectangle(cornerRadius: 2).fill(AppTheme.primary.opacity(0.5)).frame(width: 18, height: 34)
            }
        }
        .padding(6)
    }

    private var handwritingPreview: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 6).fill(AppTheme.card).frame(width: 100, height: 66)
            Text("好")
                .font(.system(size: 38, weight: .light))
                .foregroundColor(AppTheme.text.opacity(0.7))
        }
    }

    private var strokePreview: some View {
        HStack(spacing: 5) {
            ForEach(["一", "丨", "丿", "丶", "乙"], id: \.self) { glyph in
                VStack(spacing: 3) {
                    Text(glyph)
                        .font(.system(size: 15))
                        .foregroundColor(AppTheme.text)
                        .frame(width: 22, height: 26)
                        .background(AppTheme.card)
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                    RoundedRectangle(cornerRadius: 2).fill(AppTheme.keyFunctionPreview).frame(width: 22, height: 12)
                }
            }
        }
        .padding(6)
    }
}

extension AppTheme {
    static let keyFunctionPreview = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(white: 0.35, alpha: 1)
            : UIColor(red: 0.76, green: 0.78, blue: 0.8, alpha: 1)
    })
}

struct EnableKeyboardGuide: View {
    @Environment(\.presentationMode) private var presentation
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    guideImage(icon: "gearshape", title: "第一步", text: "打开系统“设置”，进入“通用”。")
                    guideImage(icon: "keyboard", title: "第二步", text: "进入“键盘 → 键盘 → 添加新键盘”。")
                    guideImage(icon: "checkmark.seal", title: "第三步", text: "选择“豆包输入法（iOS 复刻）”。建议允许“完全访问”，以便与 App 共享剪切板和词库。")
                    guideImage(icon: "globe", title: "第四步", text: "在任意输入框长按地球键，切换到豆包输入法。")
                    Text("如果列表中没有出现，请先在模拟器/设备上打开一次本 App，确认扩展已随 App 安装。")
                        .font(.system(size: 12))
                        .foregroundColor(AppTheme.textSecondary)
                }
                .padding(20)
            }
            .background(AppTheme.pageBg.ignoresSafeArea())
            .navigationTitle("启用指引")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("关闭") { presentation.wrappedValue.dismiss() }
                }
            }
        }
    }

    private func guideImage(icon: String, title: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 22))
                .foregroundColor(AppTheme.primary)
                .frame(width: 44, height: 44)
                .background(AppTheme.accentSoft)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.system(size: 13, weight: .semibold)).foregroundColor(AppTheme.primary)
                Text(text).font(.system(size: 14)).foregroundColor(AppTheme.text).fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

struct PermissionListSheet: View {
    @Environment(\.presentationMode) private var presentation
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                Text("本复刻版会请求或使用以下权限：")
                    .font(.system(size: 14))
                    .foregroundColor(AppTheme.text)
                ForEach([
                    ("麦克风", "仅在你主动使用语音输入时录音。"),
                    ("语音识别", "将语音转换为文字；模拟器可能不可用，会显示离线示例。"),
                    ("通讯录", "仅在你开启“导入通讯录人名”后读取姓名，本地处理。"),
                    ("相机", "登录页扫码演示与头像拍摄，不用于后台采集。"),
                    ("通知", "消息中心本地通知演示。")
                ], id: \.0) { item in
                    Card {
                        Text(item.0).font(.system(size: 14, weight: .semibold)).foregroundColor(AppTheme.text)
                        Text(item.1).font(.system(size: 12)).foregroundColor(AppTheme.textSecondary)
                    }
                }
                Text("键盘扩展只有在系统设置中允许“完全访问”后，才能读取与 App 共享的剪切板。")
                    .font(.system(size: 12))
                    .foregroundColor(AppTheme.textSecondary)
            }
            .padding(20)
        }
        .background(AppTheme.pageBg.ignoresSafeArea())
        .navigationTitle("权限清单")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("关闭") { presentation.wrappedValue.dismiss() }
            }
        }
    }
}

// MARK: - Legal text

struct LegalTextView: View, Identifiable {
    enum Kind: String, Identifiable {
        case agreement, privacy
        var id: String { rawValue }
        var title: String { self == .agreement ? "用户协议" : "隐私政策" }
    }

    let kind: Kind
    var id: String { kind.id }
    var showsClose: Bool = false
    @Environment(\.presentationMode) private var presentation
    @EnvironmentObject private var router: Router

    var body: some View {
        VStack(spacing: 0) {
            if !showsClose {
                HStack {
                    Button {
                        router.pop()
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(AppTheme.text)
                            .frame(width: 40, height: 40)
                    }
                    Spacer()
                    Text(kind.title)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(AppTheme.text)
                    Spacer()
                    Spacer().frame(width: 40)
                }
                .frame(height: 52)
                .background(AppTheme.pageBg)
                .overlay(alignment: .bottom) { Rectangle().fill(AppTheme.divider).frame(height: 0.5) }
            }
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text(kind.title)
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(AppTheme.text)
                    Text("生效日期：2026 年 10 月 20 日 · 复刻版示例文本")
                        .font(.system(size: 11))
                        .foregroundColor(AppTheme.textSecondary)
                    ForEach(Array(sections.enumerated()), id: \.offset) { _, section in
                        VStack(alignment: .leading, spacing: 6) {
                            Text(section.0).font(.system(size: 16, weight: .semibold)).foregroundColor(AppTheme.text)
                            Text(section.1).font(.system(size: 14)).foregroundColor(AppTheme.textSecondary).fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
                .frame(maxWidth: 720)
                .padding(20)
                .frame(maxWidth: .infinity)
            }
        }
        .background(AppTheme.pageBg.ignoresSafeArea())
        .navigationTitle(kind.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if showsClose {
                ToolbarItem(placement: .cancellationAction) {
                    Button("关闭") { presentation.wrappedValue.dismiss() }
                }
            }
        }
    }

    private var sections: [(String, String)] {
        if kind == .agreement {
            return [
                ("1. 关于本应用", "豆包输入法（iOS 复刻）是独立的净室实现，与豆包官方无隶属关系，不包含官方 APK/IPA、皮肤、字体、词典或源代码。"),
                ("2. 使用许可", "你可以自由安装与测试本复刻版。应用内所有界面、引擎与素材均为本项目原创或使用 MIT 等开源许可数据。"),
                ("3. 本地数据", "设置、词库、常用语、剪切板历史保存在本机 App Group 容器中。你可以随时在设置中清空。"),
                ("4. AI 服务", "只有在你主动配置第三方 AI 服务密钥并启用智能输入模式时，输入文本才会发送到所配置的服务端点。密钥保存在 iOS Keychain，不写入日志或代码仓库。"),
                ("5. 免责声明", "本应用为学习与研究用途，不承诺与官方产品完全一致的排序或功能。请勿用于冒充官方服务。")
            ]
        }
        return [
            ("1. 我们收集什么", "默认不上传输入内容。键盘扩展的拼音、手写识别与候选排序均在本机完成。"),
            ("2. 语音", "使用语音时，会请求麦克风与语音识别权限。识别由系统语音框架处理；模拟器不可用时展示离线示例。"),
            ("3. 剪切板", "仅在开启剪切板历史后保存最近文本，最多 50 条，可随时清空。键盘扩展读取需系统“完全访问”。"),
            ("4. 通讯录", "导入通讯录人名默认关闭。开启后仅在本地读取姓名建立词库，不上传。"),
            ("5. 第三方 AI", "若你配置 DeepSeek 等服务，请求会发送至你填写的 Base URL。请自行阅读其隐私条款。"),
            ("6. 你的控制权", "可切换基础输入模式、关闭体验改进计划、清空词库与剪切板，或在系统设置中撤销权限。")
        ]
    }
}
