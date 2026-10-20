import UIKit

/// The real system keyboard extension. It hosts the shared, UIKit-only KeyboardRootView
/// and bridges its actions to the text input session.
final class KeyboardViewController: UIInputViewController, KeyboardActionDelegate {
    private var keyboardView: KeyboardRootView!
    private var heightConstraint: NSLayoutConstraint!

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(red: 0.92, green: 0.92, blue: 0.93, alpha: 1)

        let keyboard = KeyboardRootView(frame: .zero)
        keyboard.translatesAutoresizingMaskIntoConstraints = false
        keyboard.actionDelegate = self
        view.addSubview(keyboard)
        NSLayoutConstraint.activate([
            keyboard.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            keyboard.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            keyboard.topAnchor.constraint(equalTo: view.topAnchor),
            keyboard.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        keyboardView = keyboard

        updateHeight(for: traitCollection)
        updateReturnKey()
        keyboardView.reloadTheme()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        runAutomatedKeyboardCheckIfNeeded()
    }

    private func runAutomatedKeyboardCheckIfNeeded() {
        let mode = SharedStore.defaults.string(forKey: "keyboard_autotest_mode") ?? ""
        guard !mode.isEmpty else { return }
        SharedStore.defaults.removeObject(forKey: "keyboard_autotest_mode")
        SharedStore.defaults.synchronize()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { [weak self] in
            self?.keyboardView.automationCompose("nihao")
            if mode == "commit" {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
                    self?.keyboardView.automationCommitFirst()
                }
            }
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateHeight(for: traitCollection)
        keyboardView.reloadTheme()
        keyboardView.rebuildForKind()
        updateReturnKey()
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate(alongsideTransition: nil) { [weak self] _ in
            guard let self else { return }
            self.updateHeight(for: self.traitCollection)
            self.keyboardView.reloadTheme()
            self.keyboardView.setNeedsLayout()
            self.keyboardView.layoutIfNeeded()
        }
    }

    override func textDidChange(_ textInput: UITextInput?) {
        super.textDidChange(textInput)
        updateReturnKey()
    }

    private func updateHeight(for traits: UITraitCollection) {
        let stored = SharedStore.defaults.object(forKey: "keyboard_height") as? Double ?? 300
        let landscape = view.bounds.width > view.bounds.height
        let height = KeyboardMetrics.preferredHeight(idiom: traits.userInterfaceIdiom, landscape: landscape, stored: stored)
        if heightConstraint == nil {
            heightConstraint = view.heightAnchor.constraint(equalToConstant: height)
            heightConstraint.priority = UILayoutPriority(999)
            heightConstraint.isActive = true
        } else {
            heightConstraint.constant = height
        }
    }

    private func updateReturnKey() {
        guard let keyboardView else { return }
        let title: String
        switch textDocumentProxy.returnKeyType ?? .default {
        case .search: title = "搜索"
        case .send: title = "发送"
        case .go: title = "前往"
        case .done: title = "完成"
        case .next, .continue: title = "下一项"
        case .join: title = "加入"
        case .route: title = "路线"
        case .emergencyCall: title = "呼叫"
        default: title = "换行"
        }
        if keyboardView.returnKeyTitle != title {
            keyboardView.returnKeyTitle = title
            keyboardView.setNeedsLayout()
        }
    }

    // MARK: - KeyboardActionDelegate

    func keyboardInsert(_ text: String) {
        textDocumentProxy.insertText(text)
    }

    func keyboardDelete() {
        textDocumentProxy.deleteBackward()
    }

    func keyboardReturn() {
        textDocumentProxy.insertText("\n")
    }

    func keyboardNextInputMode() {
        advanceToNextInputMode()
    }

    func keyboardDismiss() {
        dismissKeyboard()
    }

    func keyboardRequestHeight(_ height: CGFloat) {
        guard heightConstraint != nil else { return }
        heightConstraint.constant = max(250, min(440, height))
        UIView.animate(withDuration: 0.18) {
            self.view.layoutIfNeeded()
        }
    }

    func keyboardShowMessage(_ message: String) {
        keyboardView.showToast(message)
    }
}
