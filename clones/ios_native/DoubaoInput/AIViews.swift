import SwiftUI

struct AISettingsView: View {
    @EnvironmentObject private var settings: AppSettings
    @State private var baseURL = ""
    @State private var model = ""
    @State private var key = ""
    @State private var showKey = false
    @State private var testing = false
    @State private var testResult: String?
    @State private var testFailed = false
    @State private var saved = false

    var body: some View {
        PageScaffold(title: "AI 服务", subtitle: "DeepSeek Chat Completions · 密钥仅保存在本机 Keychain") {
            Card {
                HStack {
                    Image(systemName: settings.aiKeyPresent ? "checkmark.shield.fill" : "key.slash")
                        .foregroundColor(settings.aiKeyPresent ? AppTheme.primary : AppTheme.textSecondary)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(settings.aiKeyPresent ? "已配置 API Key" : "尚未配置 API Key")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(AppTheme.text)
                        Text("没有 Key 时，AI 写作/整理/翻译使用本地示例，并明确标注。")
                            .font(.system(size: 11))
                            .foregroundColor(AppTheme.textSecondary)
                    }
                    Spacer()
                }
            }

            Card {
                fieldLabel("Base URL")
                TextField("https://api.deepseek.com", text: $baseURL)
                    .keyboardType(.URL)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .font(.system(size: 14))
                    .padding(11)
                    .background(AppTheme.cardAlt)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                fieldLabel("Model")
                TextField("deepseek-chat", text: $model)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .font(.system(size: 14))
                    .padding(11)
                    .background(AppTheme.cardAlt)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                fieldLabel("API Key")
                HStack {
                    Group {
                        if showKey {
                            TextField("sk-…（仅保存在 Keychain）", text: $key)
                        } else {
                            SecureField("sk-…（仅保存在 Keychain）", text: $key)
                        }
                    }
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .font(.system(size: 14))
                    Button {
                        showKey.toggle()
                    } label: {
                        Image(systemName: showKey ? "eye.slash" : "eye")
                            .foregroundColor(AppTheme.textSecondary)
                    }
                }
                .padding(11)
                .background(AppTheme.cardAlt)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                Text("留空不会覆盖已保存的 Key。保存后写入 iOS Keychain，不写入 UserDefaults、日志或仓库。")
                    .font(.system(size: 10))
                    .foregroundColor(AppTheme.textSecondary)
                HStack(spacing: 10) {
                    PrimaryButton(title: "保存配置", icon: "tray.and.arrow.down") {
                        save()
                    }
                    SecondaryButton(title: testing ? "测试中…" : "测试连接", icon: "antenna.radiowaves.left.and.right") {
                        if testing { return }
                        testConnection()
                    }
                    .frame(width: 140)
                    .disabled(testing)
                }
                if settings.aiKeyPresent {
                    Button {
                        KeychainStore.delete()
                        settings.aiKeyPresent = false
                        key = ""
                        testResult = nil
                        showToast("已清除 API Key")
                    } label: {
                        Text("清除 Keychain 中的 API Key")
                            .font(.system(size: 11))
                            .foregroundColor(AppTheme.danger)
                    }
                }
                if let testResult {
                    HStack(alignment: .top, spacing: 6) {
                        Image(systemName: testFailed ? "xmark.circle.fill" : "checkmark.circle.fill")
                            .foregroundColor(testFailed ? AppTheme.danger : AppTheme.primary)
                        Text(testResult)
                            .font(.system(size: 11))
                            .foregroundColor(testFailed ? AppTheme.danger : AppTheme.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }

            Card {
                Text("请求契约")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(AppTheme.text)
                Text("POST {BaseURL}/chat/completions\nAuthorization: Bearer <key>\nContent-Type: application/json\n\n请求体包含 model、messages 与 stream:false；超时 20 秒。错误会映射为 401、429、5xx 与网络错误，可重试。")
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(AppTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                Text("构建时可通过环境变量 DEEPSEEK_API_KEY 注入；用户设置优先。仓库不包含任何 Key。")
                    .font(.system(size: 11))
                    .foregroundColor(AppTheme.textSecondary)
            }
            if !settings.isSmartMode {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill").foregroundColor(.orange)
                    Text("当前为基础输入模式，即使配置 Key 也不会发起网络请求。")
                        .font(.system(size: 12))
                        .foregroundColor(AppTheme.textSecondary)
                }
                .padding(12)
                .background(Color.orange.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .onAppear {
            baseURL = settings.aiBaseURL
            model = settings.aiModel
        }
    }

    private func fieldLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 11, weight: .medium))
            .foregroundColor(AppTheme.textSecondary)
    }

    private func save() {
        let trimmedBase = baseURL.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedModel = model.trimmingCharacters(in: .whitespacesAndNewlines)
        settings.aiBaseURL = trimmedBase.isEmpty ? "https://api.deepseek.com" : trimmedBase
        settings.aiModel = trimmedModel.isEmpty ? "deepseek-chat" : trimmedModel
        if !key.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            if KeychainStore.save(key) {
                settings.aiKeyPresent = true
                key = ""
                showToast("配置已保存，Key 已写入 Keychain")
            } else {
                showToast("Keychain 写入失败")
            }
        } else {
            showToast("配置已保存")
        }
        saved = true
    }

    private func testConnection() {
        let trimmed = key.trimmingCharacters(in: .whitespacesAndNewlines)
        let runtimeKey = trimmed.isEmpty ? KeychainStore.effectiveKey : trimmed
        guard let runtimeKey, !runtimeKey.isEmpty else {
            testFailed = true
            testResult = "请先输入或保存 API Key。"
            return
        }
        testing = true
        testResult = nil
        let client = DeepSeekClient(
            baseURL: baseURL.isEmpty ? settings.aiBaseURL : baseURL,
            model: model.isEmpty ? settings.aiModel : model,
            key: runtimeKey
        )
        client.test { result in
            DispatchQueue.main.async {
                testing = false
                switch result {
                case .success(let text):
                    testFailed = false
                    testResult = "连接成功，服务端返回：\(text.prefix(60))"
                case .failure(let error):
                    testFailed = true
                    testResult = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
                }
            }
        }
    }
}

struct AIWritingView: View {
    var body: some View { AIStudioView(initialMode: .writing) }
}

struct SmartOrganizeView: View {
    var body: some View { AIStudioView(initialMode: .organize) }
}

struct TranslateView: View {
    var body: some View { AIStudioView(initialMode: .translate) }
}

struct AIStudioView: View {
    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var router: Router
    @StateObject private var model = AIStudioModel()
    var initialMode: AIStudioMode

    @State private var mode: AIStudioMode
    @State private var action = "祝福"
    @State private var input = ""
    @State private var removeFillers = true
    @State private var punctuation = "smart"
    @State private var toEnglish = true

    private let actions = ["祝福", "高赞动态", "写评论", "自我介绍", "宴席邀请", "写邮件", "爆款文案"]

    init(initialMode: AIStudioMode) {
        self.initialMode = initialMode
        _mode = State(initialValue: initialMode)
    }

    var body: some View {
        PageScaffold(title: mode.title, subtitle: subtitle) {
            if !settings.isSmartMode {
                HStack(spacing: 8) {
                    Image(systemName: "lock.shield.fill").foregroundColor(.orange)
                    Text("基础输入模式：仅生成本地示例，不会上传输入。")
                        .font(.system(size: 12))
                        .foregroundColor(AppTheme.textSecondary)
                    Spacer()
                    Button("切换") { router.push(.inputMode) }
                        .font(.system(size: 11))
                        .foregroundColor(AppTheme.primary)
                }
                .padding(12)
                .background(Color.orange.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            HStack(spacing: 8) {
                ForEach(AIStudioMode.allCases) { item in
                    ChoiceChip(title: item.title, selected: mode == item) {
                        mode = item
                    }
                }
            }

            switch mode {
            case .writing:
                writingForm
            case .organize:
                organizeForm
            case .translate:
                translateForm
            }

            outputCard
            if !model.usedOffline && !model.output.isEmpty {
                Text("结果由你配置的 DeepSeek 服务生成。请自行核对事实与隐私内容。")
                    .font(.system(size: 10))
                    .foregroundColor(AppTheme.textSecondary)
            }
        }
    }

    private var subtitle: String {
        switch mode {
        case .writing: return "选择场景，输入参考信息；有 Key 时调用云端，否则本地示例"
        case .organize: return "去口水词、补标点、分段；本地规则与 AI 双路径"
        case .translate: return "中英互译；无 Key 时使用离线词典"
        }
    }

    private var writingForm: some View {
        VStack(alignment: .leading, spacing: 12) {
            Card {
                Text("写作场景")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(AppTheme.text)
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 86), spacing: 8)], spacing: 8) {
                    ForEach(actions, id: \.self) { item in
                        ChoiceChip(title: item, selected: action == item) { action = item }
                    }
                }
            }
            Card {
                HStack {
                    Text("参考信息（可选）")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(AppTheme.text)
                    Spacer()
                    Text("\(input.count) 字")
                        .font(.system(size: 10))
                        .foregroundColor(AppTheme.textSecondary)
                }
                TextEditor(text: $input)
                    .frame(minHeight: 100)
                    .font(.system(size: 14))
                    .padding(6)
                    .background(AppTheme.cardAlt)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                PrimaryButton(title: model.isLoading ? "生成中…" : "生成", icon: "sparkles") {
                    guard !model.isLoading else { return }
                    model.generate(AIStudioRequest(mode: .writing, action: action, input: input, toEnglish: toEnglish, punctuation: punctuation, removeFillers: removeFillers), settings: settings)
                }
            }
        }
    }

    private var organizeForm: some View {
        Card {
            HStack {
                Text("原文")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(AppTheme.text)
                Spacer()
                Button("载入示例") {
                    input = "嗯那个我们今天下午三点开个会，然后呢把键盘扩展的测试过一遍，就是说大家提前准备一下。"
                }
                .font(.system(size: 11))
                .foregroundColor(AppTheme.primary)
            }
            TextEditor(text: $input)
                .frame(minHeight: 120)
                .font(.system(size: 14))
                .padding(6)
                .background(AppTheme.cardAlt)
                .clipShape(RoundedRectangle(cornerRadius: 10))
            Toggle("去除口水词", isOn: $removeFillers)
                .tint(AppTheme.primary)
                .font(.system(size: 13))
            HStack(spacing: 8) {
                ForEach(PunctuationStyle.allCases) { style in
                    ChoiceChip(title: style.rawValue, selected: punctuation == style.key) {
                        punctuation = style.key
                    }
                }
            }
            PrimaryButton(title: model.isLoading ? "整理中…" : "开始整理", icon: "wand.and.stars") {
                guard !model.isLoading, !input.trimmingCharacters(in: .whitespaces).isEmpty else {
                    showToast("请输入要整理的文本")
                    return
                }
                model.generate(AIStudioRequest(mode: .organize, action: "整理", input: input, toEnglish: toEnglish, punctuation: punctuation, removeFillers: removeFillers), settings: settings)
            }
        }
    }

    private var translateForm: some View {
        Card {
            HStack {
                Text("翻译方向")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(AppTheme.text)
                Spacer()
                ChoiceChip(title: "中 → 英", selected: toEnglish) { toEnglish = true }
                ChoiceChip(title: "英 → 中", selected: !toEnglish) { toEnglish = false }
            }
            TextEditor(text: $input)
                .frame(minHeight: 110)
                .font(.system(size: 14))
                .padding(6)
                .background(AppTheme.cardAlt)
                .clipShape(RoundedRectangle(cornerRadius: 10))
            HStack {
                Button("载入示例") {
                    input = toEnglish ? "今天天气很好，我们下午一起喝杯咖啡吧。" : "It's a beautiful day. Let's grab a coffee this afternoon."
                }
                .font(.system(size: 11))
                .foregroundColor(AppTheme.primary)
                Spacer()
                Text("无 Key 时使用离线词库，可能仅覆盖常见短语")
                    .font(.system(size: 10))
                    .foregroundColor(AppTheme.textSecondary)
            }
            PrimaryButton(title: model.isLoading ? "翻译中…" : "翻译", icon: "character.bubble") {
                guard !model.isLoading, !input.trimmingCharacters(in: .whitespaces).isEmpty else {
                    showToast("请输入要翻译的文字")
                    return
                }
                model.generate(AIStudioRequest(mode: .translate, action: "翻译", input: input, toEnglish: toEnglish, punctuation: punctuation, removeFillers: removeFillers), settings: settings)
            }
        }
    }

    private var outputCard: some View {
        Card {
            HStack {
                Text("结果")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(AppTheme.text)
                if model.usedOffline {
                    Text("离线示例")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundColor(AppTheme.primary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(AppTheme.accentSoft)
                        .clipShape(Capsule())
                }
                Spacer()
                if model.isLoading {
                    ProgressView().scaleEffect(0.8)
                }
            }
            if let error = model.errorText {
                HStack(alignment: .top, spacing: 6) {
                    Image(systemName: "exclamationmark.circle.fill").foregroundColor(model.usedOffline ? .orange : AppTheme.danger)
                    Text(error)
                        .font(.system(size: 11))
                        .foregroundColor(model.usedOffline ? AppTheme.textSecondary : AppTheme.danger)
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer()
                }
            }
            if model.output.isEmpty {
                Text("生成结果会显示在这里")
                    .font(.system(size: 13))
                    .foregroundColor(AppTheme.textSecondary)
                    .frame(maxWidth: .infinity, minHeight: 70, alignment: .topLeading)
            } else {
                Text(model.output)
                    .font(.system(size: 15))
                    .foregroundColor(AppTheme.text)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .textSelection(.enabled)
            }
            HStack(spacing: 8) {
                SecondaryButton(title: "复制", icon: "doc.on.doc") {
                    UIPasteboard.general.string = model.output
                    showToast("已复制结果")
                }
                SecondaryButton(title: "替换输入", icon: "arrow.turn.down.left") {
                    guard !model.output.isEmpty else { return }
                    input = model.output
                    showToast("已替换输入内容")
                }
                SecondaryButton(title: "重试", icon: "arrow.clockwise") {
                    model.retry(settings: settings)
                }
            }
            if !settings.aiKeyPresent {
                Button {
                    router.push(.aiSettings)
                } label: {
                    Text("配置 AI 服务以获取完整生成 →")
                        .font(.system(size: 11))
                        .foregroundColor(AppTheme.primary)
                }
            }
        }
    }
}
