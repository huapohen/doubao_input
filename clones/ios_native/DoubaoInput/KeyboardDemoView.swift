import SwiftUI
import UIKit

struct KeyboardDemoView: View {
    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var router: Router
    @State private var text = "你好，这是豆包输入法（iOS 复刻）的键盘实验室。\n"
    @State private var height: CGFloat = 330
    @State private var showGuide = false
    @Environment(\.horizontalSizeClass) private var sizeClass

    var body: some View {
        VStack(spacing: 0) {
            header
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    inputCard
                    typePicker
                    infoRow
                }
                .frame(maxWidth: 720)
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity)
            }
            KeyboardHostView(
                text: $text,
                height: $height,
                keyboardKind: settings.keyboardType,
                returnTitle: settings.enterSend ? "发送" : "换行",
                initialPanel: UserDefaults.standard.string(forKey: "kbPanel") ?? ""
            )
            .frame(height: sizeClass == .regular ? 380 : 330)
            .background(Color(red: 0.92, green: 0.92, blue: 0.93))
        }
        .background(AppTheme.pageBg.ignoresSafeArea())
        .navigationBarHidden(true)
        .sheet(isPresented: $showGuide) {
            EnableKeyboardGuide()
        }
    }

    private var header: some View {
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
            VStack(spacing: 1) {
                Text("键盘实验室").font(.system(size: 17, weight: .semibold)).foregroundColor(AppTheme.text)
                Text("App 内真实键盘视图 · 与扩展共用代码").font(.system(size: 9)).foregroundColor(AppTheme.textSecondary)
            }
            Spacer()
            Button {
                showGuide = true
            } label: {
                Image(systemName: "questionmark.circle")
                    .font(.system(size: 17))
                    .foregroundColor(AppTheme.textSecondary)
                    .frame(width: 40, height: 40)
            }
        }
        .frame(height: 50)
        .background(AppTheme.pageBg)
        .overlay(alignment: .bottom) { Rectangle().fill(AppTheme.divider).frame(height: 0.5) }
    }

    private var inputCard: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("测试输入框")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(AppTheme.textSecondary)
                Spacer()
                Text("\(text.count) 字符")
                    .font(.system(size: 10))
                    .foregroundColor(AppTheme.textSecondary)
                Button("清空") {
                    text = ""
                    showToast("已清空测试输入框")
                }
                .font(.system(size: 11))
                .foregroundColor(AppTheme.primary)
            }
            TextEditor(text: $text)
                .font(.system(size: 16))
                .frame(minHeight: 94, maxHeight: 120)
                .padding(8)
                .background(AppTheme.card)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(AppTheme.divider, lineWidth: 0.5)
                )
            Text("点击下方键盘输入；中文候选可上屏，支持删除、空格、换行、中英切换与工具箱。")
                .font(.system(size: 10))
                .foregroundColor(AppTheme.textSecondary)
        }
    }

    private var typePicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(KeyboardKind.allCases) { kind in
                    ChoiceChip(title: kind.shortTitle, selected: settings.keyboardType == kind) {
                        settings.keyboardType = kind
                        settings.keyboardTypePicked = true
                        showToast("已切换为\(kind.title)")
                    }
                }
            }
        }
    }

    private var infoRow: some View {
        HStack(spacing: 8) {
            Image(systemName: "info.circle")
                .font(.system(size: 12))
                .foregroundColor(AppTheme.textSecondary)
            Text("这是 App 内键盘 Demo，不是系统键盘。系统键盘需在设置 → 通用 → 键盘中添加本扩展。")
                .font(.system(size: 10))
                .foregroundColor(AppTheme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
            Spacer()
            Button("启用指引") { showGuide = true }
                .font(.system(size: 10))
                .foregroundColor(AppTheme.primary)
            Button("系统键盘测试") { router.push(.systemKeyboardTest) }
                .font(.system(size: 10))
                .foregroundColor(AppTheme.primary)
        }
    }
}

struct KeyboardHostView: UIViewRepresentable {
    @Binding var text: String
    @Binding var height: CGFloat
    var keyboardKind: KeyboardKind
    var returnTitle: String
    var initialPanel: String = ""

    func makeUIView(context: Context) -> KeyboardRootView {
        let view = KeyboardRootView(frame: .zero)
        view.actionDelegate = context.coordinator
        view.keyboardKind = keyboardKind
        view.returnKeyTitle = returnTitle
        view.rebuildForKind()
        view.reloadTheme()
        if !initialPanel.isEmpty {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
                view.automationOpenPanel(initialPanel)
            }
        }
        return view
    }

    func updateUIView(_ uiView: KeyboardRootView, context: Context) {
        context.coordinator.text = $text
        context.coordinator.height = $height
        if uiView.keyboardKind != keyboardKind {
            uiView.keyboardKind = keyboardKind
            uiView.rebuildForKind()
        }
        if uiView.returnKeyTitle != returnTitle {
            uiView.returnKeyTitle = returnTitle
            if uiView.page == .letters || uiView.page == .t9 || uiView.page == .numbers || uiView.page == .symbols {
                uiView.buildKeyboard()
            }
        }
        uiView.reloadTheme()
        uiView.setNeedsLayout()
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(text: $text, height: $height)
    }

    final class Coordinator: NSObject, KeyboardActionDelegate {
        var text: Binding<String>
        var height: Binding<CGFloat>

        init(text: Binding<String>, height: Binding<CGFloat>) {
            self.text = text
            self.height = height
        }

        func keyboardInsert(_ value: String) {
            text.wrappedValue += value
        }

        func keyboardDelete() {
            guard !text.wrappedValue.isEmpty else { return }
            text.wrappedValue.removeLast()
        }

        func keyboardReturn() {
            text.wrappedValue += "\n"
        }

        func keyboardNextInputMode() {
            showToast("Demo 模式：系统键盘切换需在设备中使用地球键")
        }

        func keyboardDismiss() {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }

        func keyboardRequestHeight(_ value: CGFloat) {
            let clamped = max(250, min(440, value))
            height.wrappedValue = clamped + 30
        }

        func keyboardShowMessage(_ message: String) {
            showToast(message)
        }
    }
}
