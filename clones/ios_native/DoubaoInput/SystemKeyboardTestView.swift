import SwiftUI

struct SystemKeyboardTestView: View {
    @EnvironmentObject private var router: Router
    @State private var text = ""
    @State private var autoCheckMode = ""
    @FocusState private var focused: Bool

    var body: some View {
        PageScaffold(title: "系统键盘测试", subtitle: "使用 iOS 系统键盘输入；启用扩展后会显示复刻键盘") {
            Card {
                HStack(spacing: 10) {
                    Image(systemName: "keyboard.badge.ellipsis")
                        .font(.system(size: 22))
                        .foregroundColor(AppTheme.primary)
                    VStack(alignment: .leading, spacing: 3) {
                        Text("系统输入框").font(.system(size: 15, weight: .medium)).foregroundColor(AppTheme.text)
                        Text("点击下方输入框调起系统键盘。若已添加并切换到复刻键盘，会显示 26 键/9 键界面。")
                            .font(.system(size: 11))
                            .foregroundColor(AppTheme.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                TextEditor(text: $text)
                    .focused($focused)
                    .font(.system(size: 17))
                    .frame(minHeight: 160)
                    .padding(10)
                    .background(AppTheme.cardAlt)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(focused ? AppTheme.primary.opacity(0.4) : AppTheme.divider, lineWidth: 1)
                    )
                    .overlay(alignment: .topLeading) {
                        if text.isEmpty {
                            Text("点这里开始输入中文…")
                                .font(.system(size: 15))
                                .foregroundColor(AppTheme.textSecondary)
                                .padding(16)
                                .allowsHitTesting(false)
                        }
                    }
                HStack(spacing: 10) {
                    PrimaryButton(title: focused ? "键盘已调起" : "调起系统键盘", icon: "keyboard") {
                        focused = true
                    }
                    SecondaryButton(title: "打开系统设置", icon: "gear") {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    }
                }
                HStack {
                    Text("\(text.count) 字符")
                        .font(.system(size: 10))
                        .foregroundColor(AppTheme.textSecondary)
                    Spacer()
                    if !autoCheckMode.isEmpty {
                        Text("自动验证模式：\(autoCheckMode == "commit" ? "组词并上屏" : "仅组词")")
                            .font(.system(size: 10))
                            .foregroundColor(AppTheme.primary)
                    }
                }
            }

            Card {
                Text("启用步骤")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(AppTheme.text)
                ForEach(["设置 → 通用 → 键盘 → 键盘", "添加新键盘 → 豆包输入法（iOS 复刻）", "在输入框长按地球键切换到复刻键盘", "建议允许完全访问以共享剪切板与词库"], id: \.self) { line in
                    HStack(alignment: .top, spacing: 6) {
                        Circle().fill(AppTheme.primary.opacity(0.5)).frame(width: 4, height: 4).padding(.top, 6)
                        Text(line).font(.system(size: 12)).foregroundColor(AppTheme.textSecondary)
                    }
                }
                HStack(spacing: 10) {
                    SecondaryButton(title: "复制启用路径", icon: "doc.on.doc") {
                        UIPasteboard.general.string = "设置 → 通用 → 键盘 → 键盘 → 添加新键盘 → 豆包输入法（iOS 复刻）"
                        showToast("已复制启用路径")
                    }
                    SecondaryButton(title: "键盘实验室", icon: "keyboard") {
                        router.push(.keyboardDemo)
                    }
                }
            }

            Card {
                Text("扩展信息")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(AppTheme.text)
                Text("扩展 Bundle ID\ncom.huapohen.doubaoinput.ios.keyboard\n\n主 App\ncom.huapohen.doubaoinput.ios\n\n词典随扩展打包，本地加载，无需联网。")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(AppTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .onAppear {
            if let mode = UserDefaults.standard.string(forKey: "kbAutotest"), !mode.isEmpty {
                autoCheckMode = mode
                SharedStore.defaults.set(mode, forKey: "keyboard_autotest_mode")
                SharedStore.defaults.synchronize()
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                focused = true
            }
        }
        .onChange(of: text) { _ in
            if !autoCheckMode.isEmpty {
                autoCheckMode = ""
            }
        }
    }
}
