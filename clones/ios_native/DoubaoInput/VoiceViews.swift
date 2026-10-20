import SwiftUI
import Combine
import AVFoundation
import Speech

struct VoiceSettingsView: View {
    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var router: Router
    @State private var downloading = false
    @State private var downloadError: String?

    private let ticker = Timer.publish(every: 0.12, on: .main, in: .common).autoconnect()

    var body: some View {
        PageScaffold(title: "语音转文字", subtitle: "语音识别、智能整理与离线包设置") {
            SettingGroup(title: "识别与整理") {
                ToggleRow(title: "智能文字整理", subtitle: "自动去口水词、补标点、分段", isOn: $settings.voiceSmartOrganize, isLast: false)
                ToggleRow(title: "分段后空行", subtitle: "整理结果段落之间保留空行", isOn: $settings.voiceParagraphBlank, isLast: false)
                ToggleRow(title: "耳机麦克风", subtitle: "连接耳机时优先使用耳机麦克风", isOn: $settings.voiceEarphone, isLast: true)
            }

            Card {
                Text("标点展示")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(AppTheme.text)
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                    ForEach(PunctuationStyle.allCases) { style in
                        Button {
                            settings.voicePunctuationStyle = style.key
                            showToast("已选择\(style.rawValue)")
                        } label: {
                            HStack {
                                RadioCircle(selected: settings.voicePunctuationStyle == style.key)
                                Text(style.rawValue)
                                    .font(.system(size: 13))
                                    .foregroundColor(AppTheme.text)
                                Spacer()
                            }
                            .padding(10)
                            .background(AppTheme.cardAlt)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                        .buttonStyle(ScaleButtonStyle())
                    }
                }
            }

            Card {
                Text("口水词处理")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(AppTheme.text)
                HStack(spacing: 8) {
                    ChoiceChip(title: "正常", selected: settings.voiceFiller == "normal") {
                        settings.voiceFiller = "normal"
                        showToast("已选择正常去口水词")
                    }
                    ChoiceChip(title: "激进", selected: settings.voiceFiller == "aggressive") {
                        settings.voiceFiller = "aggressive"
                        showToast("已选择激进去口水词")
                    }
                }
                Text("示例：嗯那个我们今天就是说…… → 我们今天……")
                    .font(.system(size: 11))
                    .foregroundColor(AppTheme.textSecondary)
            }

            SettingGroup(title: "语音入口") {
                NavRow(title: "语音口令", subtitle: settings.voiceActionEnabled ? "已开启 · \(settings.voiceActions.count) 个口令" : "已关闭", icon: "mic.badge.plus", isLast: false) {
                    router.push(.voiceAction)
                }
                NavRow(title: "试说一段", subtitle: "请求麦克风与语音识别权限，实时转写", icon: "waveform", isLast: true) {
                    voiceTest = true
                }
            }

            Card {
                HStack {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("离线语音")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(AppTheme.text)
                        Text(settings.voiceOffline ? "离线示例包已就绪（演示）" : "模拟下载离线语音包，约 177 MB")
                            .font(.system(size: 11))
                            .foregroundColor(AppTheme.textSecondary)
                    }
                    Spacer()
                    if settings.voiceOffline {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(AppTheme.primary)
                    }
                }
                if downloading || (settings.voiceOfflineProgress > 0 && settings.voiceOfflineProgress < 1) {
                    ProgressView(value: settings.voiceOfflineProgress)
                        .tint(AppTheme.primary)
                    HStack {
                        Text("正在下载 \(Int(settings.voiceOfflineProgress * 100))%")
                            .font(.system(size: 11))
                            .foregroundColor(AppTheme.textSecondary)
                        Spacer()
                        Button("取消") {
                            downloading = false
                            settings.voiceOfflineProgress = 0
                            showToast("已取消下载")
                        }
                        .font(.system(size: 11))
                        .foregroundColor(AppTheme.textSecondary)
                    }
                } else if settings.voiceOffline {
                    HStack {
                        Text("已完成（模拟）")
                            .font(.system(size: 11))
                            .foregroundColor(AppTheme.textSecondary)
                        Spacer()
                        Button("删除离线包") {
                            settings.voiceOffline = false
                            settings.voiceOfflineProgress = 0
                            showToast("已删除离线语音包")
                        }
                        .font(.system(size: 11))
                        .foregroundColor(AppTheme.danger)
                    }
                } else {
                    PrimaryButton(title: "下载离线语音包（模拟）", icon: "arrow.down.circle") {
                        downloading = true
                        settings.voiceOfflineProgress = 0.01
                        showToast("开始模拟下载")
                    }
                }
                if let downloadError {
                    Text(downloadError).font(.system(size: 11)).foregroundColor(AppTheme.danger)
                }
                Text("说明：该复刻版不包含官方 177 MB 离线模型，此处的下载仅模拟进度与状态。")
                    .font(.system(size: 11))
                    .foregroundColor(AppTheme.textSecondary)
            }

            SettingGroup(title: "网络") {
                ToggleRow(title: "WiFi 弱时切换流量", subtitle: "网络质量差时允许使用蜂窝网络", isOn: $settings.voiceWeakNetwork, isLast: true)
            }

            SecondaryButton(title: "打开语音试说", icon: "mic.fill") {
                voiceTest = true
            }

            Card {
                Text("隐私")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(AppTheme.text)
                Text("语音识别调用 iOS Speech 框架。首次使用会请求麦克风与语音识别权限；拒绝后仍可查看离线示例。音频不会保存到应用内。")
                    .font(.system(size: 12))
                    .foregroundColor(AppTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .onReceive(ticker) { _ in
            guard downloading else { return }
            settings.voiceOfflineProgress = min(1, settings.voiceOfflineProgress + 0.035)
            if settings.voiceOfflineProgress >= 1 {
                downloading = false
                settings.voiceOffline = true
                showToast("离线语音包已就绪（模拟）")
            }
        }
        .sheet(isPresented: $voiceTest) {
            NavigationView {
                VoiceTestView()
                    .environmentObject(settings)
            }
        }
    }

    @State private var voiceTest = false
}

struct VoiceActionView: View {
    @EnvironmentObject private var settings: AppSettings
    @State private var newAction = ""
    @State private var showAdd = false

    private let presets = ["帮我发送", "我说完了", "立即发送", "发送发送", "overover"]

    var body: some View {
        PageScaffold(title: "语音口令", subtitle: "说出指定口令即可自动发送或结束输入") {
            Card {
                Toggle(isOn: $settings.voiceActionEnabled) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("语音口令").font(.system(size: 16, weight: .medium)).foregroundColor(AppTheme.text)
                        Text("识别到口令后执行“发送”或“完成”").font(.system(size: 12)).foregroundColor(AppTheme.textSecondary)
                    }
                }
                .tint(AppTheme.primary)
                .onChange(of: settings.voiceActionEnabled) { on in
                    showToast(on ? "语音口令已开启" : "语音口令已关闭")
                }
            }
            SettingGroup(title: "内置口令（可多选）") {
                ForEach(Array(presets.enumerated()), id: \.offset) { index, action in
                    let selected = settings.voiceActions.contains(action)
                    Button {
                        var list = settings.voiceActions
                        if selected { list.removeAll { $0 == action } } else { list.append(action) }
                        settings.voiceActions = list
                        showToast(selected ? "已移除口令" : "已添加口令")
                    } label: {
                        HStack {
                            Text(action).font(.system(size: 15)).foregroundColor(AppTheme.text)
                            Spacer()
                            Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(selected ? AppTheme.primary : AppTheme.textSecondary.opacity(0.5))
                        }
                        .padding(.vertical, 12)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(RowButtonStyle())
                    .overlay(alignment: .bottom) {
                        if index < presets.count - 1 { Rectangle().fill(AppTheme.divider).frame(height: 0.5) }
                    }
                }
            }
            if !settings.customVoiceActions.isEmpty {
                SettingGroup(title: "自定义口令") {
                    ForEach(Array(settings.customVoiceActions.enumerated()), id: \.offset) { index, action in
                        HStack {
                            Text(action).font(.system(size: 15)).foregroundColor(AppTheme.text)
                            Spacer()
                            Button {
                                settings.removeVoiceAction(action)
                                showToast("已删除自定义口令")
                            } label: {
                                Image(systemName: "trash")
                                    .foregroundColor(AppTheme.danger)
                            }
                        }
                        .padding(.vertical, 11)
                        .overlay(alignment: .bottom) {
                            if index < settings.customVoiceActions.count - 1 { Rectangle().fill(AppTheme.divider).frame(height: 0.5) }
                        }
                    }
                }
            }
            SecondaryButton(title: "添加自定义口令", icon: "plus") {
                showAdd = true
            }
            Card {
                Text("口令在本地匹配，命中后由键盘扩展或语音结果页执行发送。示例：“帮我发送”“我说完了”。")
                    .font(.system(size: 12))
                    .foregroundColor(AppTheme.textSecondary)
            }
        }
        .alert("添加自定义口令", isPresented: $showAdd) {
            TextField("例如：发出去", text: $newAction)
            Button("取消", role: .cancel) {}
            Button("保存") {
                settings.addVoiceAction(newAction)
                newAction = ""
                showToast("已保存自定义口令")
            }
        }
    }
}

// MARK: - Speech recognizer

final class VoiceRecognizer: NSObject, ObservableObject {
    @Published var transcript: String = ""
    @Published var isRecording = false
    @Published var statusText = "点击开始说话"
    @Published var errorText: String?
    @Published var usedFallback = false
    @Published var level: CGFloat = 0.2

    private let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "zh-CN"))
    private let audioEngine = AVAudioEngine()
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var task: SFSpeechRecognitionTask?
    private var levelTimer: Timer?

    func start() {
        errorText = nil
        usedFallback = false
        transcript = ""
        SFSpeechRecognizer.requestAuthorization { [weak self] status in
            DispatchQueue.main.async {
                guard let self else { return }
                guard status == .authorized else {
                    self.errorText = self.mapSpeechAuth(status)
                    self.statusText = "无语音识别权限"
                    return
                }
                AVAudioSession.sharedInstance().requestRecordPermission { granted in
                    DispatchQueue.main.async {
                        guard granted else {
                            self.errorText = "麦克风权限被拒绝，请在系统设置中开启。"
                            self.statusText = "无麦克风权限"
                            return
                        }
                        self.beginRecording()
                    }
                }
            }
        }
    }

    private func beginRecording() {
        guard let recognizer, recognizer.isAvailable else {
            errorText = "当前设备或模拟器暂不支持中文语音识别，可使用下方离线示例。"
            statusText = "语音识别不可用"
            return
        }
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.record, mode: .measurement, options: .duckOthers)
            try session.setActive(true, options: .notifyOthersOnDeactivation)
            request = SFSpeechAudioBufferRecognitionRequest()
            guard let request else { return }
            request.shouldReportPartialResults = true
            if recognizer.supportsOnDeviceRecognition {
                request.requiresOnDeviceRecognition = false
            }
            let input = audioEngine.inputNode
            let format = input.outputFormat(forBus: 0)
            input.removeTap(onBus: 0)
            input.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak self] buffer, _ in
                self?.request?.append(buffer)
                let power = buffer.floatChannelData?[0].pointee ?? 0
                DispatchQueue.main.async {
                    self?.level = min(1, max(0.12, CGFloat(abs(power)) * 12))
                }
            }
            audioEngine.prepare()
            try audioEngine.start()
            isRecording = true
            statusText = "正在倾听…"
            task = recognizer.recognitionTask(with: request) { [weak self] result, error in
                guard let self else { return }
                if let result {
                    DispatchQueue.main.async {
                        self.transcript = result.bestTranscription.formattedString
                        self.statusText = "识别中…"
                    }
                }
                if error != nil {
                    DispatchQueue.main.async {
                        if self.transcript.isEmpty {
                            self.errorText = "没听清，请重试或使用离线示例。"
                        }
                        self.stop()
                    }
                }
            }
            levelTimer = Timer.scheduledTimer(withTimeInterval: 0.15, repeats: true) { [weak self] _ in
                guard let self, self.isRecording else { return }
                if Int.random(in: 0...3) == 0 {
                    self.level = CGFloat.random(in: 0.2...0.9)
                }
            }
        } catch {
            errorText = "无法启动录音：\(error.localizedDescription)"
            statusText = "录音失败"
            stop()
        }
    }

    func stop() {
        isRecording = false
        if audioEngine.isRunning {
            audioEngine.stop()
            audioEngine.inputNode.removeTap(onBus: 0)
        }
        request?.endAudio()
        task?.cancel()
        task = nil
        request = nil
        levelTimer?.invalidate()
        levelTimer = nil
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        if transcript.isEmpty {
            statusText = "未识别到语音"
        } else {
            statusText = "识别完成"
        }
    }

    func useOfflineExample() {
        let text = "嗯那个我们今天下午三点开个会，然后呢把键盘扩展的测试过一遍。"
        transcript = LocalIntelligence.organize(text, removeFillers: true, blankLineParagraphs: false, punctuation: "smart")
        usedFallback = true
        statusText = "离线示例"
        errorText = nil
    }

    private func mapSpeechAuth(_ status: SFSpeechRecognizerAuthorizationStatus) -> String {
        switch status {
        case .denied: return "语音识别权限被拒绝，请在系统设置中开启。"
        case .restricted: return "系统限制了语音识别。"
        case .notDetermined: return "尚未授权语音识别。"
        default: return "语音识别不可用。"
        }
    }
}

struct VoiceTestView: View {
    @EnvironmentObject private var settings: AppSettings
    @Environment(\.presentationMode) private var presentation
    @StateObject private var recognizer = VoiceRecognizer()
    @State private var seconds = 0
    @State private var showOrganized = false

    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                ZStack {
                    Circle()
                        .fill(AppTheme.primary.opacity(0.10))
                        .frame(width: 160, height: 160)
                    Circle()
                        .fill(AppTheme.primary.opacity(0.18))
                        .frame(width: 120, height: 120)
                    Image(systemName: recognizer.isRecording ? "waveform" : "mic.fill")
                        .font(.system(size: 44, weight: .light))
                        .foregroundColor(AppTheme.primary)
                }
                Text(recognizer.isRecording ? "正在倾听" : recognizer.statusText)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(AppTheme.text)
                Text(String(format: "%02d:%02d", seconds / 60, seconds % 60))
                    .font(.system(size: 13, weight: .regular, design: .monospaced))
                    .foregroundColor(AppTheme.textSecondary)
                HStack(spacing: 4) {
                    ForEach(0..<9) { index in
                        Capsule()
                            .fill(AppTheme.primary.opacity(0.4 + Double(index % 3) * 0.2))
                            .frame(width: 4, height: recognizer.isRecording ? 8 + CGFloat(index % 4) * 6 * recognizer.level : 8)
                    }
                }
                .frame(height: 36)
                .animation(.easeInOut(duration: 0.2), value: recognizer.level)

                if let error = recognizer.errorText {
                    Text(error)
                        .font(.system(size: 12))
                        .foregroundColor(AppTheme.danger)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                }

                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("识别结果")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(AppTheme.textSecondary)
                        Spacer()
                        if recognizer.usedFallback {
                            Text("离线示例")
                                .font(.system(size: 10))
                                .foregroundColor(AppTheme.primary)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(AppTheme.accentSoft)
                                .clipShape(Capsule())
                        }
                    }
                    TextEditor(text: $recognizer.transcript)
                        .font(.system(size: 15))
                        .frame(minHeight: 110)
                        .padding(8)
                        .background(AppTheme.cardAlt)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }

                HStack(spacing: 10) {
                    PrimaryButton(title: recognizer.isRecording ? "结束" : "开始说话", icon: recognizer.isRecording ? "stop.fill" : "mic.fill") {
                        if recognizer.isRecording {
                            recognizer.stop()
                        } else {
                            seconds = 0
                            recognizer.start()
                        }
                    }
                    SecondaryButton(title: "离线示例", icon: "icloud.slash") {
                        recognizer.useOfflineExample()
                    }
                    .frame(width: 130)
                }

                HStack(spacing: 10) {
                    SecondaryButton(title: "智能整理", icon: "wand.and.stars") {
                        let result = LocalIntelligence.organize(recognizer.transcript, removeFillers: settings.voiceFiller == "aggressive", blankLineParagraphs: settings.voiceParagraphBlank, punctuation: settings.voicePunctuationStyle)
                        recognizer.transcript = result
                        showOrganized = true
                        showToast("已本地整理")
                    }
                    SecondaryButton(title: "复制", icon: "doc.on.doc") {
                        UIPasteboard.general.string = recognizer.transcript
                        showToast("已复制识别结果")
                    }
                }
                Text("语音识别由系统 Speech 框架提供；模拟器或无权限时会给出明确错误，可点击“离线示例”。整理使用本地规则。")
                    .font(.system(size: 11))
                    .foregroundColor(AppTheme.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
            }
            .padding(20)
        }
        .background(AppTheme.pageBg.ignoresSafeArea())
        .navigationTitle("语音试说")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("关闭") {
                    if recognizer.isRecording { recognizer.stop() }
                    presentation.wrappedValue.dismiss()
                }
            }
        }
        .onReceive(timer) { _ in
            if recognizer.isRecording { seconds += 1 }
        }
        .onDisappear {
            if recognizer.isRecording { recognizer.stop() }
        }
        .alert("已应用智能整理", isPresented: $showOrganized) {
            Button("好", role: .cancel) {}
        } message: {
            Text("已根据语音设置去口水词、补标点并分段。")
        }
    }
}
