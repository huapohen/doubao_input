import SwiftUI

struct AccountView: View {
    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var router: Router
    @State private var showLogout = false

    var body: some View {
        PageScaffold(title: "账户", subtitle: "登录状态、同步与超级互传") {
            Card {
                HStack(spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(LinearGradient(colors: [AppTheme.primary.opacity(0.85), Color(red: 0.55, green: 0.72, blue: 1.0)], startPoint: .topLeading, endPoint: .bottomTrailing))
                            .frame(width: 62, height: 62)
                        Text(settings.accountLoggedIn ? String(settings.accountName.prefix(1)) : "豆")
                            .font(.system(size: 26, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    VStack(alignment: .leading, spacing: 4) {
                        Text(settings.accountLoggedIn ? settings.accountName : "未登录")
                            .font(.system(size: 19, weight: .semibold))
                            .foregroundColor(AppTheme.text)
                        Text(settings.accountLoggedIn ? "本地模拟账号 · 未连接豆包官方" : "登录后可同步设置、词库与常用语")
                            .font(.system(size: 11))
                            .foregroundColor(AppTheme.textSecondary)
                    }
                    Spacer()
                    if !settings.accountLoggedIn {
                        Button {
                            router.push(.login)
                        } label: {
                            Text("登录")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.white)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(AppTheme.primary)
                                .clipShape(Capsule())
                        }
                    }
                }
            }

            SettingGroup {
                NavRow(title: "消息中心", subtitle: "功能通知与隐私提示", value: settings.unreadMessageCount > 0 ? "\(settings.unreadMessageCount) 条未读" : nil, icon: "bell", isLast: false) {
                    router.push(.messages)
                }
                NavRow(title: "超级互传", subtitle: settings.superTransferEnabled ? "已启用" : "未启用", value: settings.superTransferEnabled ? "已启用" : "去启用", icon: "arrow.left.arrow.right", isLast: false) {
                    router.push(.superTransfer)
                }
                NavRow(title: "电脑版", subtitle: "macOS / Windows", icon: "desktopcomputer", isLast: true) {
                    router.push(.desktop)
                }
            }

            SettingGroup(title: "数据同步") {
                ToggleRow(title: "同步设置", subtitle: "键盘布局、外观与输入偏好", isOn: $settings.syncSettings, isLast: false) { on in
                    showToast(on ? "设置同步已开启" : "设置同步已关闭")
                }
                ToggleRow(title: "同步个人词库", subtitle: "个人词条与通讯录词库", isOn: $settings.syncLexicon, isLast: false)
                ToggleRow(title: "同步常用语", subtitle: "分类与使用次数", isOn: $settings.syncPhrases, isLast: true)
            }

            if settings.accountLoggedIn {
                SettingGroup {
                    ActionRow(title: "退出登录", destructive: true, icon: "rectangle.portrait.and.arrow.right", isLast: true) {
                        showLogout = true
                    }
                }
                Text("复刻版登录仅保存在本机，不连接豆包官方账号系统，也不会请求短信验证码。")
                    .font(.system(size: 11))
                    .foregroundColor(AppTheme.textSecondary)
                    .padding(.horizontal, 4)
            } else {
                Card {
                    Text("关于登录")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(AppTheme.text)
                    Text("本复刻版提供本地模拟登录与扫码演示，用于展示账户页状态变化。不会连接官方服务器，也不会收集手机号。")
                        .font(.system(size: 12))
                        .foregroundColor(AppTheme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .alert("退出登录？", isPresented: $showLogout) {
            Button("取消", role: .cancel) {}
            Button("退出", role: .destructive) {
                settings.signOut()
                showToast("已退出登录")
            }
        } message: {
            Text("退出后会关闭超级互传，并停止同步演示。本地设置不会删除。")
        }
    }
}

struct LoginView: View {
    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var router: Router
    @State private var phone = ""
    @State private var agreed = true
    @State private var mode = 0
    @State private var scanning = false
    @State private var scanProgress: CGFloat = 0
    @State private var loggedIn = false
    @State private var showAgreement = false

    var body: some View {
        PageScaffold(title: "登录", subtitle: "本地模拟登录，不会请求官方服务") {
            Card {
                HStack(spacing: 12) {
                    ZStack {
                        Circle().fill(AppTheme.primary.opacity(0.12)).frame(width: 52, height: 52)
                        Image(systemName: "person.badge.key").font(.system(size: 24)).foregroundColor(AppTheme.primary)
                    }
                    VStack(alignment: .leading, spacing: 3) {
                        Text("豆包账号登录").font(.system(size: 17, weight: .semibold)).foregroundColor(AppTheme.text)
                        Text("复刻版：输入任意手机号即可模拟登录").font(.system(size: 11)).foregroundColor(AppTheme.textSecondary)
                    }
                    Spacer()
                }
            }

            HStack(spacing: 8) {
                ChoiceChip(title: "手机号登录", selected: mode == 0) { mode = 0 }
                ChoiceChip(title: "扫码登录", selected: mode == 1) { mode = 1 }
            }

            if mode == 0 {
                Card {
                    Text("手机号")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(AppTheme.textSecondary)
                    TextField("输入任意 11 位手机号", text: $phone)
                        .keyboardType(.numberPad)
                        .font(.system(size: 17))
                        .padding(12)
                        .background(AppTheme.cardAlt)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    HStack(spacing: 6) {
                        Button {
                            agreed.toggle()
                        } label: {
                            Image(systemName: agreed ? "checkmark.square.fill" : "square")
                                .foregroundColor(agreed ? AppTheme.primary : AppTheme.textSecondary)
                        }
                        Text("我已阅读并同意")
                            .font(.system(size: 11))
                            .foregroundColor(AppTheme.textSecondary)
                        Button("用户协议") { showAgreement = true }
                            .font(.system(size: 11))
                            .foregroundColor(AppTheme.primary)
                    }
                    PrimaryButton(title: "一键登录（模拟）", icon: "arrow.right", enabled: agreed) {
                        login()
                    }
                }
            } else {
                Card {
                    VStack(spacing: 14) {
                        ZStack {
                            QRCodeView(text: "doubao-input-clone://local-login/\(UUID().uuidString.prefix(8))")
                                .frame(width: 180, height: 180)
                            if scanning {
                                Rectangle()
                                    .fill(LinearGradient(colors: [AppTheme.primary.opacity(0), AppTheme.primary, AppTheme.primary.opacity(0)], startPoint: .leading, endPoint: .trailing))
                                    .frame(height: 2)
                                    .offset(y: scanOffset)
                                    .animation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true), value: scanning)
                            }
                        }
                        Text(scanning ? "正在等待扫码…" : "使用手机扫码登录（演示）")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(AppTheme.text)
                        Text("二维码为本地生成，不包含官方登录链接。点击下方按钮模拟扫码成功。")
                            .font(.system(size: 11))
                            .foregroundColor(AppTheme.textSecondary)
                            .multilineTextAlignment(.center)
                        PrimaryButton(title: scanning ? "模拟扫码成功" : "开始模拟扫码", icon: "qrcode.viewfinder") {
                            if scanning {
                                login()
                            } else {
                                scanning = true
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
            }

            Card {
                Text("隐私说明")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(AppTheme.text)
                Text("本页面不发送任何网络请求。手机号不会被保存；登录状态仅记录在本地 UserDefaults，用于演示账户页和超级互传的状态变化。")
                    .font(.system(size: 12))
                    .foregroundColor(AppTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .sheet(isPresented: $showAgreement) {
            NavigationView {
                LegalTextView(kind: .agreement, showsClose: true)
            }
        }
        .onChange(of: mode) { _ in scanning = false }
    }

    private var scanOffset: CGFloat {
        scanning ? 80 : -80
    }

    private func login() {
        let name: String
        if phone.count >= 4 {
            name = "豆包用户 \(phone.suffix(4))"
        } else {
            name = "豆包用户"
        }
        settings.signIn(name: name)
        if settings.devices.isEmpty {
            settings.devices = [DeviceRecord(name: "本机 · \(UIDevice.current.name)", kind: UIDevice.current.userInterfaceIdiom == .pad ? "iPad" : "iPhone", lastSeen: "刚刚")]
        }
        scanning = false
        loggedIn = true
        showToast("登录成功（本地模拟）")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            router.pop()
        }
    }
}

struct MessageCenterView: View {
    @EnvironmentObject private var settings: AppSettings
    @State private var selected: AppMessage?
    @State private var showDeleteAll = false

    var body: some View {
        PageScaffold(title: "消息中心", subtitle: "功能通知、隐私提示与帮助") {
            HStack {
                Text("\(settings.unreadMessageCount) 条未读 · \(settings.messages.count) 条消息")
                    .font(.system(size: 12))
                    .foregroundColor(AppTheme.textSecondary)
                Spacer()
                Button("全部已读") {
                    for message in settings.messages { settings.markMessageRead(message) }
                    showToast("已全部标记为已读")
                }
                .font(.system(size: 12))
                .foregroundColor(AppTheme.primary)
                .disabled(settings.unreadMessageCount == 0)
            }
            if settings.messages.isEmpty {
                Card {
                    EmptyStateView(icon: "bell.slash", title: "暂无消息", message: "功能更新与隐私提示会显示在这里。")
                }
            } else {
                Card {
                    ForEach(Array(settings.messages.sorted { $0.date > $1.date }.enumerated()), id: \.element.id) { index, message in
                        Button {
                            settings.markMessageRead(message)
                            selected = message
                        } label: {
                            HStack(alignment: .top, spacing: 10) {
                                ZStack {
                                    Circle().fill(message.read ? AppTheme.cardAlt : AppTheme.primary.opacity(0.14)).frame(width: 36, height: 36)
                                    Image(systemName: icon(for: message.kind))
                                        .font(.system(size: 15))
                                        .foregroundColor(message.read ? AppTheme.textSecondary : AppTheme.primary)
                                }
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack(spacing: 6) {
                                        Text(message.title)
                                            .font(.system(size: 14, weight: message.read ? .regular : .semibold))
                                            .foregroundColor(AppTheme.text)
                                        if !message.read {
                                            Circle().fill(AppTheme.danger).frame(width: 5, height: 5)
                                        }
                                    }
                                    Text(message.body)
                                        .font(.system(size: 12))
                                        .foregroundColor(AppTheme.textSecondary)
                                        .lineLimit(2)
                                        .multilineTextAlignment(.leading)
                                    Text(relativeDate(message.date))
                                        .font(.system(size: 10))
                                        .foregroundColor(AppTheme.textSecondary.opacity(0.8))
                                }
                                Spacer()
                                Menu {
                                    Button("标记已读") { settings.markMessageRead(message) }
                                    Button("删除", role: .destructive) {
                                        settings.deleteMessage(message)
                                        showToast("已删除消息")
                                    }
                                } label: {
                                    Image(systemName: "ellipsis")
                                        .foregroundColor(AppTheme.textSecondary)
                                        .frame(width: 28, height: 28)
                                }
                            }
                            .padding(.vertical, 10)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(RowButtonStyle())
                        if index < settings.messages.count - 1 {
                            Rectangle().fill(AppTheme.divider).frame(height: 0.5)
                        }
                    }
                }
            }
            if !settings.messages.isEmpty {
                SecondaryButton(title: "清空消息", icon: "trash") {
                    showDeleteAll = true
                }
            }
        }
        .sheet(item: $selected) { message in
            NavigationView {
                VStack(alignment: .leading, spacing: 14) {
                    Text(message.title).font(.system(size: 22, weight: .semibold)).foregroundColor(AppTheme.text)
                    Text(relativeDate(message.date)).font(.system(size: 11)).foregroundColor(AppTheme.textSecondary)
                    Text(message.body).font(.system(size: 15)).foregroundColor(AppTheme.text)
                    Spacer()
                }
                .padding(20)
                .navigationTitle("消息详情")
                .navigationBarTitleDisplayMode(.inline)
            }
        }
        .alert("清空全部消息？", isPresented: $showDeleteAll) {
            Button("取消", role: .cancel) {}
            Button("清空", role: .destructive) {
                settings.messages = []
                showToast("消息已清空")
            }
        }
    }

    private func icon(for kind: String) -> String {
        switch kind {
        case "功能": return "sparkles"
        case "隐私": return "lock.shield"
        case "帮助": return "questionmark.circle"
        default: return "bell"
        }
    }

    private func relativeDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}
