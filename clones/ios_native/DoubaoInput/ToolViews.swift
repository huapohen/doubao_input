import SwiftUI
import AVFoundation
import Speech
import Contacts
import UserNotifications
import CoreImage.CIFilterBuiltins

// MARK: - Clipboard

struct ClipboardSettingsView: View {
    @EnvironmentObject private var settings: AppSettings
    @State private var showClearConfirm = false

    var body: some View {
        PageScaffold(title: "剪切板", subtitle: "候选栏展示与本地历史记录") {
            SettingGroup {
                ToggleRow(title: "候选栏展示剪切板", subtitle: "复制文字后，候选栏出现最近内容", isOn: $settings.clipboardCandidate, isLast: false)
                ToggleRow(title: "历史记录", subtitle: "最多保存 50 条文本", isOn: $settings.clipboardHistory, isLast: true) { on in
                    showToast(on ? "已开启剪切板历史" : "已关闭，现有记录不会被删除")
                }
            }
            HStack(spacing: 10) {
                SecondaryButton(title: "从系统剪贴板添加", icon: "plus.square.on.square") {
                    guard let text = UIPasteboard.general.string, !text.isEmpty else {
                        showToast("系统剪贴板为空")
                        return
                    }
                    settings.addClipboard(text)
                    showToast("已添加一条剪切板记录")
                }
                SecondaryButton(title: "清空历史", icon: "trash") {
                    showClearConfirm = true
                }
                .frame(width: 130)
            }
            if settings.clipboardItems.isEmpty {
                Card {
                    EmptyStateView(icon: "doc.on.clipboard", title: "暂无剪切板历史", message: "在任意 App 复制文字，或点击上方按钮从系统剪贴板添加。")
                }
            } else {
                Card {
                    HStack {
                        Text("历史记录")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(AppTheme.text)
                        Spacer()
                        Text("\(settings.clipboardItems.count) 条")
                            .font(.system(size: 11))
                            .foregroundColor(AppTheme.textSecondary)
                    }
                    ForEach(Array(settings.clipboardItems.enumerated()), id: \.element.id) { index, item in
                        HStack(alignment: .top, spacing: 10) {
                            Image(systemName: item.kind == "image" ? "photo" : "text.alignleft")
                                .font(.system(size: 15))
                                .foregroundColor(AppTheme.primary)
                                .frame(width: 24)
                            VStack(alignment: .leading, spacing: 3) {
                                Text(item.text)
                                    .font(.system(size: 14))
                                    .foregroundColor(AppTheme.text)
                                    .lineLimit(3)
                                Text(item.displayTime)
                                    .font(.system(size: 10))
                                    .foregroundColor(AppTheme.textSecondary)
                            }
                            Spacer()
                            VStack(spacing: 8) {
                                Button {
                                    UIPasteboard.general.string = item.text
                                    showToast("已复制")
                                } label: {
                                    Image(systemName: "doc.on.doc").font(.system(size: 13))
                                }
                                Button {
                                    settings.deleteClipboard(item)
                                    showToast("已删除")
                                } label: {
                                    Image(systemName: "trash").font(.system(size: 13)).foregroundColor(AppTheme.danger)
                                }
                            }
                        }
                        .padding(.vertical, 10)
                        .overlay(alignment: .bottom) {
                            if index < settings.clipboardItems.count - 1 {
                                Rectangle().fill(AppTheme.divider).frame(height: 0.5)
                            }
                        }
                    }
                }
            }
            Card {
                Text("说明")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(AppTheme.text)
                Text("剪切板历史保存在 App Group 中，键盘扩展需在系统设置中允许“完全访问”才能读取。首次读取系统剪贴板时，iOS 可能显示粘贴授权提示。")
                    .font(.system(size: 12))
                    .foregroundColor(AppTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .alert("清空剪切板历史？", isPresented: $showClearConfirm) {
            Button("取消", role: .cancel) {}
            Button("清空", role: .destructive) {
                settings.clearClipboard()
                showToast("已清空剪切板历史")
            }
        } message: {
            Text("此操作不可撤销，只会删除本机记录。")
        }
    }
}

// MARK: - Lexicon

struct LexiconManagementView: View {
    @EnvironmentObject private var settings: AppSettings
    @State private var newWord = ""
    @State private var newPinyin = ""
    @State private var showAdd = false
    @State private var showClearPersonal = false
    @State private var showClearContacts = false
    @State private var search = ""

    private var filtered: [LexiconEntry] {
        let list = settings.personalLexicon
        guard !search.isEmpty else { return list }
        return list.filter { $0.word.contains(search) || $0.pinyin.contains(search.lowercased()) }
    }

    var body: some View {
        PageScaffold(title: "词库管理", subtitle: "个人词库优先参与候选排序") {
            HStack(spacing: 10) {
                HStack(spacing: 6) {
                    Image(systemName: "magnifyingglass").foregroundColor(AppTheme.textSecondary)
                    TextField("搜索词条", text: $search)
                        .font(.system(size: 14))
                }
                .padding(.horizontal, 10)
                .frame(height: 40)
                .background(AppTheme.card)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                Button {
                    showAdd = true
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 40, height: 40)
                        .background(AppTheme.primary)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }

            Card {
                HStack {
                    Text("个人词库")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(AppTheme.text)
                    Spacer()
                    Text("\(settings.personalLexicon.count) 条")
                        .font(.system(size: 11))
                        .foregroundColor(AppTheme.textSecondary)
                }
                if filtered.isEmpty {
                    EmptyStateView(icon: "books.vertical", title: search.isEmpty ? "还没有个人词条" : "没有匹配词条", message: search.isEmpty ? "添加姓名、专业词或常用组合，候选栏会优先展示。" : "换个关键词试试。")
                } else {
                    ForEach(Array(filtered.enumerated()), id: \.element.id) { index, entry in
                        HStack(spacing: 10) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(entry.word)
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundColor(AppTheme.text)
                                Text(entry.pinyin.isEmpty ? "未填写拼音" : entry.pinyin)
                                    .font(.system(size: 11))
                                    .foregroundColor(AppTheme.textSecondary)
                            }
                            Text(entry.source)
                                .font(.system(size: 9))
                                .foregroundColor(AppTheme.primary)
                                .padding(.horizontal, 5)
                                .padding(.vertical, 2)
                                .background(AppTheme.accentSoft)
                                .clipShape(Capsule())
                            Spacer()
                            Button {
                                settings.deleteLexicon(entry)
                                showToast("已删除“\(entry.word)”")
                            } label: {
                                Image(systemName: "trash").font(.system(size: 13)).foregroundColor(AppTheme.danger)
                            }
                        }
                        .padding(.vertical, 9)
                        .overlay(alignment: .bottom) {
                            if index < filtered.count - 1 { Rectangle().fill(AppTheme.divider).frame(height: 0.5) }
                        }
                    }
                }
            }

            Card {
                HStack {
                    Text("通讯录词库")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(AppTheme.text)
                    Spacer()
                    Text("\(settings.personalLexicon.filter { $0.source == "通讯录" }.count) 条")
                        .font(.system(size: 11))
                        .foregroundColor(AppTheme.textSecondary)
                }
                Text("开启“导入通讯录人名”后，可在本地匹配联系人姓名。复刻版使用模拟联系人生成演示词条，不读取真实通讯录。")
                    .font(.system(size: 11))
                    .foregroundColor(AppTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                HStack(spacing: 10) {
                    SecondaryButton(title: "模拟导入联系人", icon: "person.2") {
                        settings.contactsImport = true
                        let names = [("王小雨", "wang xiao yu"), ("陈明远", "chen ming yuan"), ("赵一诺", "zhao yi nuo")]
                        for (name, pinyin) in names {
                            if !settings.personalLexicon.contains(where: { $0.word == name }) {
                                settings.personalLexicon.append(LexiconEntry(word: name, pinyin: pinyin, source: "通讯录"))
                            }
                        }
                        showToast("已模拟导入 3 个联系人姓名")
                    }
                    SecondaryButton(title: "清空通讯录词库", icon: "trash") {
                        showClearContacts = true
                    }
                }
            }

            SettingGroup {
                ActionRow(title: "清空个人词库", destructive: true, icon: "trash", isLast: true) {
                    showClearPersonal = true
                }
            }
            Text("个人词库保存在本机并优先于系统词典参与候选排序；删除后立即生效。")
                .font(.system(size: 11))
                .foregroundColor(AppTheme.textSecondary)
                .padding(.horizontal, 4)
        }
        .alert("添加词条", isPresented: $showAdd) {
            TextField("词条，例如：林小满", text: $newWord)
            TextField("拼音（可选），例如：lin xiao man", text: $newPinyin)
            Button("取消", role: .cancel) {}
            Button("保存") {
                let word = newWord.trimmingCharacters(in: .whitespaces)
                guard !word.isEmpty else { return }
                settings.addLexicon(word: word, pinyin: newPinyin.lowercased())
                newWord = ""
                newPinyin = ""
                showToast("已添加词条")
            }
        }
        .alert("清空个人词库？", isPresented: $showClearPersonal) {
            Button("取消", role: .cancel) {}
            Button("清空", role: .destructive) {
                settings.personalLexicon = []
                showToast("个人词库已清空")
            }
        }
        .alert("清空通讯录词库？", isPresented: $showClearContacts) {
            Button("取消", role: .cancel) {}
            Button("清空", role: .destructive) {
                settings.personalLexicon.removeAll { $0.source == "通讯录" }
                showToast("通讯录词库已清空")
            }
        }
    }
}

// MARK: - Phrases

struct PhraseManagementView: View {
    @EnvironmentObject private var settings: AppSettings
    @State private var showAdd = false
    @State private var newText = ""
    @State private var newCategory = "通用"
    @State private var editing: Phrase?
    @State private var editingText = ""
    @State private var deleteTarget: Phrase?

    private var categories: [String] {
        Array(Set(settings.commonPhrases.map { $0.category })).sorted()
    }

    var body: some View {
        PageScaffold(title: "常用语", subtitle: "分类管理并在键盘面板中快速插入") {
            HStack {
                Text("共 \(settings.commonPhrases.count) 条 · \(categories.count) 个分类")
                    .font(.system(size: 12))
                    .foregroundColor(AppTheme.textSecondary)
                Spacer()
                Button {
                    newText = ""
                    newCategory = categories.first ?? "通用"
                    showAdd = true
                } label: {
                    Label("添加", systemImage: "plus")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(AppTheme.primary)
                        .clipShape(Capsule())
                }
            }
            ForEach(categories, id: \.self) { category in
                Card {
                    Text(category)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(AppTheme.textSecondary)
                    let phrases = settings.commonPhrases.filter { $0.category == category }
                    ForEach(Array(phrases.enumerated()), id: \.element.id) { index, phrase in
                        HStack(alignment: .top, spacing: 8) {
                            VStack(alignment: .leading, spacing: 3) {
                                Text(phrase.text)
                                    .font(.system(size: 14))
                                    .foregroundColor(AppTheme.text)
                                Text("使用 \(phrase.useCount) 次")
                                    .font(.system(size: 10))
                                    .foregroundColor(AppTheme.textSecondary)
                            }
                            Spacer()
                            Button {
                                UIPasteboard.general.string = phrase.text
                                settings.usePhrase(phrase)
                                showToast("已复制常用语")
                            } label: {
                                Image(systemName: "doc.on.doc").font(.system(size: 13))
                            }
                            Button {
                                editing = phrase
                                editingText = phrase.text
                            } label: {
                                Image(systemName: "pencil").font(.system(size: 13))
                            }
                            Button {
                                deleteTarget = phrase
                            } label: {
                                Image(systemName: "trash").font(.system(size: 13)).foregroundColor(AppTheme.danger)
                            }
                        }
                        .padding(.vertical, 8)
                        if index < phrases.count - 1 {
                            Rectangle().fill(AppTheme.divider).frame(height: 0.5)
                        }
                    }
                }
            }
            if settings.commonPhrases.isEmpty {
                Card {
                    EmptyStateView(icon: "text.bubble", title: "还没有常用语", message: "添加“收到，谢谢”等常用回复，键盘面板可一键插入。")
                }
            }
            Text("常用语保存在 App Group，键盘“常用语”面板会读取同一份数据。")
                .font(.system(size: 11))
                .foregroundColor(AppTheme.textSecondary)
                .padding(.horizontal, 4)
        }
        .alert("添加常用语", isPresented: $showAdd) {
            TextField("内容", text: $newText)
            TextField("分类", text: $newCategory)
            Button("取消", role: .cancel) {}
            Button("保存") {
                settings.addPhrase(text: newText, category: newCategory.isEmpty ? "通用" : newCategory)
                showToast("已添加常用语")
            }
        }
        .alert("编辑常用语", isPresented: Binding(get: { editing != nil }, set: { if !$0 { editing = nil } })) {
            TextField("内容", text: $editingText)
            Button("取消", role: .cancel) { editing = nil }
            Button("保存") {
                if let editing, let index = settings.commonPhrases.firstIndex(where: { $0.id == editing.id }) {
                    settings.commonPhrases[index].text = editingText
                    showToast("已保存")
                }
                editing = nil
            }
        }
        .alert("删除常用语？", isPresented: Binding(get: { deleteTarget != nil }, set: { if !$0 { deleteTarget = nil } })) {
            Button("取消", role: .cancel) { deleteTarget = nil }
            Button("删除", role: .destructive) {
                if let target = deleteTarget {
                    settings.deletePhrase(target)
                    showToast("已删除")
                }
                deleteTarget = nil
            }
        }
    }
}

// MARK: - Input mode

struct InputModeView: View {
    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var router: Router
    @State private var showPermissionList = false
    @State private var confirmBasic = false

    var body: some View {
        PageScaffold(title: "输入模式与信息保护", subtitle: "切换模式会立即影响 AI、语音与翻译的可用性") {
            SettingGroup(title: "输入模式") {
                OptionRow(title: "智能输入模式", subtitle: "使用云端 AI 写作、整理、翻译与云端联想", selected: settings.privacyMode == "smart" && settings.inputMode == "smart", isLast: false) {
                    settings.privacyMode = "smart"
                    settings.inputMode = "smart"
                    showToast("已切换到智能输入模式")
                }
                OptionRow(title: "基础输入模式", subtitle: "仅本地输入；AI/语音/翻译需开启智能模式", selected: settings.privacyMode == "basic" || settings.inputMode == "basic", isLast: true) {
                    confirmBasic = true
                }
            }
            if !settings.isSmartMode {
                HStack(spacing: 10) {
                    Image(systemName: "info.circle.fill").foregroundColor(.orange)
                    Text("当前为基础输入模式：AI 写作、智能整理、翻译与语音云端识别不可用，仍可查看本地示例。")
                        .font(.system(size: 12))
                        .foregroundColor(AppTheme.textSecondary)
                    Spacer()
                }
                .padding(12)
                .background(Color.orange.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            SettingGroup(title: "云端能力") {
                NavRow(title: "智能输入设置", subtitle: "云端输入信息与云端个人词库", icon: "cloud", isLast: false) {
                    router.push(.smartInput)
                }
                NavRow(title: "AI 服务", subtitle: "Base URL、模型与 Keychain 密钥", value: settings.aiKeyPresent ? "已配置" : "未配置", icon: "sparkles", isLast: true) {
                    router.push(.aiSettings)
                }
            }
            SettingGroup(title: "协议与清单") {
                NavRow(title: "用户协议", icon: "doc.text", isLast: false) { router.push(.agreement) }
                NavRow(title: "隐私政策", icon: "hand.raised", isLast: false) { router.push(.privacyPolicy) }
                NavRow(title: "第三方共享清单", subtitle: "本复刻版默认不包含第三方 SDK；仅可选 DeepSeek", icon: "list.bullet.rectangle", isLast: false) {
                    showToast("本复刻版无官方 SDK，仅可配置第三方 AI")
                }
                NavRow(title: "权限清单", icon: "checklist", isLast: true) { showPermissionList = true }
            }
            Card {
                Text("数据说明")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(AppTheme.text)
                Text("本复刻版不上传默认输入、不接入官方后端。若你配置了第三方 AI，请求仅发送到你填写的 Base URL；API Key 只保存在 Keychain。")
                    .font(.system(size: 12))
                    .foregroundColor(AppTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .alert("切换到基础输入模式？", isPresented: $confirmBasic) {
            Button("取消", role: .cancel) {}
            Button("切换", role: .destructive) {
                settings.privacyMode = "basic"
                settings.inputMode = "basic"
                showToast("已切换基础输入模式，仅本地处理")
            }
        } message: {
            Text("AI 写作、智能整理、翻译和云端语音将不可用，你仍可进入相关页面查看本地示例。")
        }
        .sheet(isPresented: $showPermissionList) {
            NavigationView { PermissionListSheet() }
        }
    }
}

struct SmartInputView: View {
    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var router: Router

    var body: some View {
        PageScaffold(title: "智能输入设置", subtitle: "控制云端使用的输入信息范围") {
            if !settings.isSmartMode {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.circle.fill").foregroundColor(.orange)
                    Text("当前为基础输入模式，以下开关不会上传数据。")
                        .font(.system(size: 12))
                        .foregroundColor(AppTheme.textSecondary)
                    Spacer()
                }
                .padding(12)
                .background(Color.orange.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            SettingGroup {
                ToggleRow(title: "云端使用部分输入信息", subtitle: "仅发送当前请求所需文本，用于 AI 写作、整理与翻译", isOn: $settings.smartCloudInput, isLast: false)
                ToggleRow(title: "云端使用个人词库", subtitle: "将个人词条用于云端候选排序（本复刻版仅本地）", isOn: $settings.smartCloudLexicon, isLast: true)
            }
            Card {
                Text("AI 服务配置")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(AppTheme.text)
                Text(settings.aiKeyPresent ? "已检测到 Keychain 中的 API Key。所有请求仅发往你设置的 Base URL。" : "尚未配置 API Key。AI 功能会使用本地模板，并明确标注“离线示例”。")
                    .font(.system(size: 12))
                    .foregroundColor(AppTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                SecondaryButton(title: "配置 AI 服务", icon: "gearshape") { router.push(.aiSettings) }
            }
        }
    }
}

// MARK: - Permissions

struct SystemPermissionsView: View {
    @EnvironmentObject private var settings: AppSettings
    @State private var micStatus = "检查中"
    @State private var speechStatus = "检查中"
    @State private var contactsStatus = "检查中"
    @State private var cameraStatus = "检查中"
    @State private var notificationStatus = "检查中"

    var body: some View {
        PageScaffold(title: "系统权限设置", subtitle: "状态读取自 iOS；授权后请返回本页刷新") {
            HStack {
                Text("权限状态")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(AppTheme.textSecondary)
                Spacer()
                Button("刷新") { refresh() }
                    .font(.system(size: 13))
                    .foregroundColor(AppTheme.primary)
            }
            Card {
                permissionRow(icon: "mic", title: "麦克风", status: micStatus, note: "语音输入时录音", request: requestMic)
                Divider().background(AppTheme.divider)
                permissionRow(icon: "waveform", title: "语音识别", status: speechStatus, note: "系统 Speech 框架转写", request: requestSpeech)
                Divider().background(AppTheme.divider)
                permissionRow(icon: "person.2", title: "通讯录", status: contactsStatus, note: "仅用于导入姓名（默认模拟）", request: requestContacts)
                Divider().background(AppTheme.divider)
                permissionRow(icon: "camera", title: "相机", status: cameraStatus, note: "扫码登录演示与头像", request: requestCamera)
                Divider().background(AppTheme.divider)
                permissionRow(icon: "bell", title: "通知", status: notificationStatus, note: "消息中心本地通知", request: requestNotifications)
                Divider().background(AppTheme.divider)
                HStack {
                    Image(systemName: "message").foregroundColor(AppTheme.textSecondary).frame(width: 24)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("短信").font(.system(size: 15)).foregroundColor(AppTheme.text)
                        Text("iOS 不允许第三方键盘读取短信。验证码填充仅能依赖系统建议。")
                            .font(.system(size: 10)).foregroundColor(AppTheme.textSecondary)
                    }
                    Spacer()
                    Text("系统限制").font(.system(size: 11)).foregroundColor(AppTheme.textSecondary)
                }
                .padding(.vertical, 10)
            }
            Card {
                Text("键盘扩展的权限")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(AppTheme.text)
                Text("键盘扩展不能直接请求麦克风/通讯录权限。请先在 App 中授权；若需要在键盘内共享剪切板与词库，请在“设置 → 通用 → 键盘 → 键盘 → 豆包输入法”中允许完全访问。")
                    .font(.system(size: 12))
                    .foregroundColor(AppTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Button {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            } label: {
                Label("打开系统设置", systemImage: "gear")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 46)
                    .background(AppTheme.primary)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .buttonStyle(ScaleButtonStyle())
        }
        .onAppear(perform: refresh)
    }

    private func permissionRow(icon: String, title: String, status: String, note: String, request: @escaping () -> Void) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .foregroundColor(AppTheme.textSecondary)
                .frame(width: 24)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.system(size: 15)).foregroundColor(AppTheme.text)
                Text(note).font(.system(size: 10)).foregroundColor(AppTheme.textSecondary)
            }
            Spacer()
            Text(status)
                .font(.system(size: 11))
                .foregroundColor(status == "已授权" ? AppTheme.primary : AppTheme.textSecondary)
            if status != "已授权" {
                Button("请求") { request() }
                    .font(.system(size: 11))
                    .foregroundColor(AppTheme.primary)
            }
        }
        .padding(.vertical, 10)
    }

    private func refresh() {
        switch AVAudioSession.sharedInstance().recordPermission {
        case .granted: micStatus = "已授权"
        case .denied: micStatus = "已拒绝"
        default: micStatus = "未请求"
        }
        switch SFSpeechRecognizer.authorizationStatus() {
        case .authorized: speechStatus = "已授权"
        case .denied: speechStatus = "已拒绝"
        case .restricted: speechStatus = "受限"
        default: speechStatus = "未请求"
        }
        switch CNContactStore.authorizationStatus(for: .contacts) {
        case .authorized: contactsStatus = "已授权"
        case .denied: contactsStatus = "已拒绝"
        case .restricted: contactsStatus = "受限"
        default: contactsStatus = "未请求"
        }
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized: cameraStatus = "已授权"
        case .denied: cameraStatus = "已拒绝"
        case .restricted: cameraStatus = "受限"
        default: cameraStatus = "未请求"
        }
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                switch settings.authorizationStatus {
                case .authorized, .provisional, .ephemeral: notificationStatus = "已授权"
                case .denied: notificationStatus = "已拒绝"
                default: notificationStatus = "未请求"
                }
            }
        }
    }

    private func requestMic() {
        AVAudioSession.sharedInstance().requestRecordPermission { granted in
            DispatchQueue.main.async {
                micStatus = granted ? "已授权" : "已拒绝"
                showToast(granted ? "麦克风已授权" : "麦克风被拒绝，请去系统设置开启")
            }
        }
    }

    private func requestSpeech() {
        SFSpeechRecognizer.requestAuthorization { status in
            DispatchQueue.main.async {
                speechStatus = status == .authorized ? "已授权" : "已拒绝"
                showToast(status == .authorized ? "语音识别已授权" : "语音识别被拒绝")
            }
        }
    }

    private func requestContacts() {
        CNContactStore().requestAccess(for: .contacts) { granted, _ in
            DispatchQueue.main.async {
                contactsStatus = granted ? "已授权" : "已拒绝"
                showToast(granted ? "通讯录已授权（仍不会上传）" : "通讯录权限被拒绝")
            }
        }
    }

    private func requestCamera() {
        AVCaptureDevice.requestAccess(for: .video) { granted in
            DispatchQueue.main.async {
                cameraStatus = granted ? "已授权" : "已拒绝"
                showToast(granted ? "相机已授权" : "相机权限被拒绝")
            }
        }
    }

    private func requestNotifications() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, _ in
            DispatchQueue.main.async {
                notificationStatus = granted ? "已授权" : "已拒绝"
                showToast(granted ? "通知已授权" : "通知权限被拒绝")
            }
        }
    }
}

// MARK: - Super transfer

struct SuperTransferView: View {
    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var router: Router
    @State private var newDeviceName = ""
    @State private var showAdd = false

    var body: some View {
        PageScaffold(title: "超级互传", subtitle: "同一账号下，手机与电脑互传文字和图片（本地演示）") {
            HStack(spacing: 8) {
                featureCard(icon: "text.alignleft", title: "无损长文本", text: "完整保留换行与格式")
                featureCard(icon: "photo", title: "多格式图片", text: "图片占位与文字互传")
                featureCard(icon: "bolt", title: "低延迟", text: "局域网优先，即时到达")
            }
            Card {
                Toggle(isOn: Binding(
                    get: { settings.superTransferEnabled },
                    set: { value in
                        if value && !settings.accountLoggedIn {
                            showToast("请先登录豆包账号")
                            router.push(.login)
                            return
                        }
                        settings.superTransferEnabled = value
                        if value && settings.devices.isEmpty {
                            settings.devices = [DeviceRecord(name: "本机 · \(UIDevice.current.name)", kind: UIDevice.current.userInterfaceIdiom == .pad ? "iPad" : "iPhone", lastSeen: "刚刚")]
                        }
                        showToast(value ? "超级互传已启用" : "超级互传已关闭")
                    })) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("启用超级互传").font(.system(size: 16, weight: .medium)).foregroundColor(AppTheme.text)
                        Text(settings.accountLoggedIn ? "账号：\(settings.accountName)" : "未登录，启用前需要登录")
                            .font(.system(size: 12)).foregroundColor(AppTheme.textSecondary)
                    }
                }
                .tint(AppTheme.primary)
            }
            if !settings.accountLoggedIn {
                Card {
                    HStack(spacing: 12) {
                        Image(systemName: "person.crop.circle.badge.exclamationmark")
                            .font(.system(size: 28))
                            .foregroundColor(AppTheme.primary)
                        VStack(alignment: .leading, spacing: 3) {
                            Text("还未登录").font(.system(size: 15, weight: .medium)).foregroundColor(AppTheme.text)
                            Text("登录后可管理设备并同步剪切板。").font(.system(size: 12)).foregroundColor(AppTheme.textSecondary)
                        }
                        Spacer()
                        Button("去登录") { router.push(.login) }
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 7)
                            .background(AppTheme.primary)
                            .clipShape(Capsule())
                    }
                }
            }
            if settings.superTransferEnabled {
                Card {
                    HStack {
                        Text("我的设备").font(.system(size: 14, weight: .medium)).foregroundColor(AppTheme.text)
                        Spacer()
                        Button {
                            newDeviceName = ""
                            showAdd = true
                        } label: {
                            Label("添加设备", systemImage: "plus")
                                .font(.system(size: 12))
                                .foregroundColor(AppTheme.primary)
                        }
                    }
                    ForEach(Array(settings.devices.enumerated()), id: \.element.id) { index, device in
                        HStack {
                            Image(systemName: device.kind == "iPad" ? "ipad" : (device.kind == "Mac" ? "laptopcomputer" : "iphone"))
                                .foregroundColor(AppTheme.primary)
                                .frame(width: 26)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(device.name).font(.system(size: 14)).foregroundColor(AppTheme.text)
                                Text("\(device.kind) · \(device.lastSeen)").font(.system(size: 10)).foregroundColor(AppTheme.textSecondary)
                            }
                            Spacer()
                            if index > 0 {
                                Button {
                                    settings.devices.remove(at: index)
                                    showToast("已移除设备")
                                } label: {
                                    Image(systemName: "trash").font(.system(size: 12)).foregroundColor(AppTheme.danger)
                                }
                            } else {
                                Text("本机").font(.system(size: 10)).foregroundColor(AppTheme.primary)
                            }
                        }
                        .padding(.vertical, 9)
                        if index < settings.devices.count - 1 { Rectangle().fill(AppTheme.divider).frame(height: 0.5) }
                    }
                }
            }
            Card {
                Text("使用须知")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(AppTheme.text)
                ForEach(["需要登录同一豆包账号（复刻版为本地模拟登录）。", "复刻版不连接官方服务器，互传为本地设备列表与示例文本。", "剪贴板历史最多保存 50 条，可随时清空。"], id: \.self) { line in
                    HStack(alignment: .top, spacing: 6) {
                        Circle().fill(AppTheme.primary.opacity(0.5)).frame(width: 4, height: 4).padding(.top, 5)
                        Text(line).font(.system(size: 12)).foregroundColor(AppTheme.textSecondary)
                    }
                }
                SecondaryButton(title: "复制示例文本", icon: "doc.on.doc") {
                    UIPasteboard.general.string = "来自豆包输入法（iOS 复刻）的超级互传示例"
                    showToast("已复制示例文本")
                }
            }
        }
        .alert("添加设备", isPresented: $showAdd) {
            TextField("设备名称，例如：MacBook Pro", text: $newDeviceName)
            Button("取消", role: .cancel) {}
            Button("添加") {
                let name = newDeviceName.isEmpty ? "新设备" : newDeviceName
                settings.addDevice(name, kind: name.lowercased().contains("mac") ? "Mac" : "设备")
                showToast("已添加设备")
            }
        }
    }

    private func featureCard(icon: String, title: String, text: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Image(systemName: icon).font(.system(size: 20)).foregroundColor(AppTheme.primary)
            Text(title).font(.system(size: 12, weight: .semibold)).foregroundColor(AppTheme.text)
            Text(text).font(.system(size: 9)).foregroundColor(AppTheme.textSecondary).fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(AppTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

// MARK: - Desktop

struct DesktopAppView: View {
    @EnvironmentObject private var settings: AppSettings
    @State private var showQR = false

    var body: some View {
        PageScaffold(title: "电脑版", subtitle: "在 macOS 与 Windows 上使用同一套输入习惯") {
            HStack(spacing: 12) {
                platformCard(icon: "laptopcomputer", title: "macOS", detail: "支持 Apple 芯片与 Intel")
                platformCard(icon: "pc", title: "Windows", detail: "Windows 10 / 11")
            }
            Card {
                HStack(spacing: 14) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(AppTheme.cardAlt)
                            .frame(width: 92, height: 92)
                        Image(systemName: "qrcode")
                            .font(.system(size: 54, weight: .light))
                            .foregroundColor(AppTheme.text)
                    }
                    VStack(alignment: .leading, spacing: 5) {
                        Text("扫码在电脑上打开下载页")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(AppTheme.text)
                        Text("复刻版不提供官方安装包；二维码为演示占位，不链接官方后端。")
                            .font(.system(size: 11))
                            .foregroundColor(AppTheme.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                        Button("查看二维码") { showQR = true }
                            .font(.system(size: 12))
                            .foregroundColor(AppTheme.primary)
                    }
                }
            }
            SettingGroup {
                ActionRow(title: "复制官网地址", icon: "doc.on.doc", isLast: false) {
                    UIPasteboard.general.string = "https://shurufa.doubao.com/pc"
                    showToast("已复制电脑版页面地址")
                }
                ActionRow(title: "打开电脑版页面", icon: "safari", isLast: false) {
                    if let url = URL(string: "https://shurufa.doubao.com/pc") {
                        UIApplication.shared.open(url)
                    }
                }
                ActionRow(title: "跨端设置同步", subtitle: settings.syncSettings ? "已开启" : "已关闭", icon: "arrow.triangle.2.circlepath", isLast: true) {
                    settings.syncSettings.toggle()
                    showToast(settings.syncSettings ? "已开启跨端设置同步" : "已关闭跨端设置同步")
                }
            }
            Card {
                Text("说明")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(AppTheme.text)
                Text("电脑版为官方独立客户端，本复刻版仅做下载引导与二维码占位，不包含官方安装包。复制地址不涉及密钥或账号。")
                    .font(.system(size: 12))
                    .foregroundColor(AppTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .sheet(isPresented: $showQR) {
            VStack(spacing: 16) {
                Text("电脑版下载（演示二维码）")
                    .font(.system(size: 17, weight: .semibold))
                QRCodeView(text: "https://shurufa.doubao.com/pc")
                    .frame(width: 220, height: 220)
                Text("该二维码由本地 CoreImage 生成，仅指向公开下载页。")
                    .font(.system(size: 11))
                    .foregroundColor(AppTheme.textSecondary)
                Button("关闭") { showQR = false }
                    .foregroundColor(AppTheme.primary)
            }
            .padding(24)
            .background(AppTheme.pageBg.ignoresSafeArea())
        }
    }

    private func platformCard(icon: String, title: String, detail: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon).font(.system(size: 30, weight: .light)).foregroundColor(AppTheme.primary)
            Text(title).font(.system(size: 16, weight: .semibold)).foregroundColor(AppTheme.text)
            Text(detail).font(.system(size: 11)).foregroundColor(AppTheme.textSecondary)
            Button {
                showToast("复刻版不提供安装包，请访问官网")
            } label: {
                Text("了解详情")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(AppTheme.primary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(AppTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

struct QRCodeView: View {
    var text: String
    var body: some View {
        if let image = QRCodeGenerator.image(text) {
            Image(uiImage: image)
                .interpolation(.none)
                .resizable()
                .scaledToFit()
                .padding(8)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
        } else {
            RoundedRectangle(cornerRadius: 12).fill(AppTheme.cardAlt)
                .overlay(Image(systemName: "qrcode").font(.system(size: 50)).foregroundColor(AppTheme.textSecondary))
        }
    }
}

enum QRCodeGenerator {
    static func image(_ text: String) -> UIImage? {
        let context = CIContext()
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(text.utf8)
        filter.correctionLevel = "M"
        guard let output = filter.outputImage?.transformed(by: CGAffineTransform(scaleX: 10, y: 10)),
              let cg = context.createCGImage(output, from: output.extent) else { return nil }
        return UIImage(cgImage: cg)
    }
}
