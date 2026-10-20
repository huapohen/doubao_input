import UIKit

extension KeyboardRootView {

    // MARK: - Panel scaffolding

    @discardableResult
    func presentPanel(title: String, build: (UIStackView) -> Void) -> UIStackView {
        closePanel()
        let overlay = UIView()
        overlay.backgroundColor = theme.panel
        overlay.layer.cornerRadius = 14
        overlay.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        overlay.clipsToBounds = true

        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .systemFont(ofSize: 15, weight: .semibold)
        titleLabel.textColor = theme.text
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        overlay.addSubview(titleLabel)

        let close = UIButton(type: .system)
        close.setImage(UIImage(systemName: "xmark"), for: .normal)
        close.tintColor = theme.secondaryText
        close.addTarget(self, action: #selector(closePanel), for: .touchUpInside)
        close.translatesAutoresizingMaskIntoConstraints = false
        overlay.addSubview(close)

        let scroll = UIScrollView()
        scroll.showsVerticalScrollIndicator = true
        scroll.translatesAutoresizingMaskIntoConstraints = false
        overlay.addSubview(scroll)

        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 9
        stack.alignment = .fill
        stack.translatesAutoresizingMaskIntoConstraints = false
        scroll.addSubview(stack)

        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: overlay.leadingAnchor, constant: 14),
            titleLabel.topAnchor.constraint(equalTo: overlay.topAnchor, constant: 10),
            titleLabel.heightAnchor.constraint(equalToConstant: 26),
            close.trailingAnchor.constraint(equalTo: overlay.trailingAnchor, constant: -10),
            close.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
            close.widthAnchor.constraint(equalToConstant: 32),
            close.heightAnchor.constraint(equalToConstant: 32),
            scroll.leadingAnchor.constraint(equalTo: overlay.leadingAnchor),
            scroll.trailingAnchor.constraint(equalTo: overlay.trailingAnchor),
            scroll.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            scroll.bottomAnchor.constraint(equalTo: overlay.bottomAnchor),
            stack.leadingAnchor.constraint(equalTo: scroll.contentLayoutGuide.leadingAnchor, constant: 12),
            stack.trailingAnchor.constraint(equalTo: scroll.contentLayoutGuide.trailingAnchor, constant: -12),
            stack.topAnchor.constraint(equalTo: scroll.contentLayoutGuide.topAnchor, constant: 4),
            stack.bottomAnchor.constraint(equalTo: scroll.contentLayoutGuide.bottomAnchor, constant: -12),
            stack.widthAnchor.constraint(equalTo: scroll.frameLayoutGuide.widthAnchor, constant: -24)
        ])

        addSubview(overlay)
        panelOverlay = overlay
        build(stack)
        setNeedsLayout()
        layoutIfNeeded()
        return stack
    }

    @objc func closePanel() {
        panelOverlay?.removeFromSuperview()
        panelOverlay = nil
    }

    func panelRow(title: String, detail: String? = nil, check: Bool = false, action: @escaping () -> Void) -> UIButton {
        let button = UIButton(type: .system)
        button.backgroundColor = theme.key
        button.layer.cornerRadius = 10
        button.contentHorizontalAlignment = .leading
        var config = UIButton.Configuration.plain()
        config.title = title
        config.subtitle = detail
        config.baseForegroundColor = theme.text
        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = .systemFont(ofSize: 15, weight: .medium)
            return outgoing
        }
        config.subtitleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = .systemFont(ofSize: 11)
            outgoing.foregroundColor = self.theme.secondaryText
            return outgoing
        }
        config.image = UIImage(systemName: check ? "checkmark.circle.fill" : "chevron.right")
        config.imagePlacement = .trailing
        config.imagePadding = 8
        config.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12)
        button.configuration = config
        button.heightAnchor.constraint(greaterThanOrEqualToConstant: 46).isActive = true
        button.addAction(UIAction { _ in action() }, for: .touchUpInside)
        return button
    }

    func panelGrid(items: [(String, String, () -> Void)], columns: Int = 4) -> UIStackView {
        let outer = UIStackView()
        outer.axis = .vertical
        outer.spacing = 8
        var index = 0
        while index < items.count {
            let row = UIStackView()
            row.axis = .horizontal
            row.spacing = 6
            row.distribution = .fillEqually
            for _ in 0..<columns {
                if index < items.count {
                    let item = items[index]
                    let button = UIButton(type: .custom)
                    var config = UIButton.Configuration.plain()
                    config.title = item.0
                    config.image = UIImage(systemName: item.1)
                    config.imagePlacement = .top
                    config.imagePadding = 4
                    config.baseForegroundColor = theme.text
                    config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
                        var outgoing = incoming
                        outgoing.font = .systemFont(ofSize: 11)
                        return outgoing
                    }
                    button.configuration = config
                    button.backgroundColor = theme.key
                    button.layer.cornerRadius = 10
                    button.heightAnchor.constraint(equalToConstant: 62).isActive = true
                    button.addAction(UIAction { _ in item.2() }, for: .touchUpInside)
                    row.addArrangedSubview(button)
                    index += 1
                } else {
                    let spacer = UIView()
                    row.addArrangedSubview(spacer)
                    index += 1
                }
            }
            outer.addArrangedSubview(row)
        }
        return outer
    }

    // MARK: - Toolbox

    func showToolbox() {
        presentPanel(title: "工具箱") { stack in
            let page1: [(String, String, () -> Void)] = [
                ("语音输入", "mic.fill", { [weak self] in self?.openVoice() }),
                ("表情", "face.smiling", { [weak self] in self?.openEmoji() }),
                ("键盘选择", "keyboard", { [weak self] in self?.showKeyboardPicker() }),
                ("智能整理", "wand.and.stars", { [weak self] in self?.showOrganizePanel() }),
                ("常用语", "text.bubble", { [weak self] in self?.openPhrases() }),
                ("剪切板", "doc.on.clipboard", { [weak self] in self?.openClipboard() }),
                ("定制工具栏", "slider.horizontal.3", { [weak self] in self?.showCustomToolbarPanel() }),
                ("手写找字", "scribble", { [weak self] in self?.openHandwritingLookup() })
            ]
            stack.addArrangedSubview(self.panelGrid(items: page1))
            stack.addArrangedSubview(self.panelSectionTitle("更多"))
            let page2: [(String, String, () -> Void)] = [
                ("翻译", "character.bubble", { [weak self] in self?.showTranslatePanel() }),
                ("单手", "rectangle.righthalf.inset.filled", { [weak self] in self?.toggleOneHand() }),
                ("键盘调节", "arrow.up.and.down", { [weak self] in self?.showHeightPanel() }),
                ("AI 写作", "sparkles", { [weak self] in self?.showAIPanel() }),
                ("繁简", "character.ja", { [weak self] in self?.toggleTraditional() }),
                ("更多设置", "gearshape", { [weak self] in self?.showMoreSettings() }),
                ("帮助与反馈", "questionmark.circle", { [weak self] in self?.showHelpPanel() }),
                ("工具栏", "square.grid.2x2", { [weak self] in self?.showCustomToolbarPanel() })
            ]
            stack.addArrangedSubview(self.panelGrid(items: page2))
            stack.addArrangedSubview(self.panelFootnote("工具箱共 16 项，全部可用。完整设置请打开豆包输入法 App。"))
        }
    }

    func panelSectionTitle(_ text: String) -> UILabel {
        let label = UILabel()
        label.text = text
        label.font = .systemFont(ofSize: 12, weight: .medium)
        label.textColor = theme.secondaryText
        label.heightAnchor.constraint(equalToConstant: 22).isActive = true
        return label
    }

    func panelFootnote(_ text: String) -> UILabel {
        let label = UILabel()
        label.text = text
        label.font = .systemFont(ofSize: 11)
        label.textColor = theme.secondaryText
        label.numberOfLines = 0
        return label
    }

    // MARK: - Voice

    func showVoiceOverlay() {
        guard voiceOverlay == nil else { return }
        let overlay = UIView(frame: bounds)
        overlay.backgroundColor = UIColor.black.withAlphaComponent(0.72)
        overlay.autoresizingMask = [.flexibleWidth, .flexibleHeight]

        let card = UIView()
        card.backgroundColor = theme.panel
        card.layer.cornerRadius = 18
        card.translatesAutoresizingMaskIntoConstraints = false
        overlay.addSubview(card)

        let icon = UIImageView(image: UIImage(systemName: "mic.fill"))
        icon.tintColor = theme.accent
        icon.contentMode = .scaleAspectFit
        icon.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(icon)

        let title = UILabel()
        title.text = "正在倾听"
        title.font = .systemFont(ofSize: 18, weight: .semibold)
        title.textColor = theme.text
        title.textAlignment = .center
        title.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(title)

        let timer = UILabel()
        timer.text = "00:00"
        timer.font = .monospacedDigitSystemFont(ofSize: 13, weight: .regular)
        timer.textColor = theme.secondaryText
        timer.textAlignment = .center
        timer.tag = 7001
        timer.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(timer)

        let waveContainer = UIStackView()
        waveContainer.axis = .horizontal
        waveContainer.alignment = .center
        waveContainer.spacing = 4
        waveContainer.distribution = .equalSpacing
        waveContainer.tag = 7002
        waveContainer.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(waveContainer)
        for index in 0..<7 {
            let bar = UIView()
            bar.backgroundColor = theme.accent.withAlphaComponent(0.8)
            bar.layer.cornerRadius = 2
            bar.translatesAutoresizingMaskIntoConstraints = false
            bar.widthAnchor.constraint(equalToConstant: 4).isActive = true
            bar.heightAnchor.constraint(equalToConstant: 10 + CGFloat(index % 3) * 8).isActive = true
            waveContainer.addArrangedSubview(bar)
        }

        let hint = UILabel()
        hint.text = "键盘内为离线示例；App 内使用系统语音识别"
        hint.font = .systemFont(ofSize: 11)
        hint.textColor = theme.secondaryText
        hint.textAlignment = .center
        hint.numberOfLines = 0
        hint.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(hint)

        let cancel = UIButton(type: .system)
        cancel.setTitle("取消", for: .normal)
        cancel.setTitleColor(theme.secondaryText, for: .normal)
        cancel.backgroundColor = theme.keyFunction
        cancel.layer.cornerRadius = 18
        cancel.addAction(UIAction { [weak self] _ in self?.cancelVoice() }, for: .touchUpInside)
        cancel.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(cancel)

        let done = UIButton(type: .system)
        done.setTitle("完成", for: .normal)
        done.setTitleColor(.white, for: .normal)
        done.backgroundColor = theme.accent
        done.layer.cornerRadius = 18
        done.addAction(UIAction { [weak self] _ in self?.finishVoice(overlay: overlay, card: card, timer: timer) }, for: .touchUpInside)
        done.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(done)

        NSLayoutConstraint.activate([
            card.centerXAnchor.constraint(equalTo: overlay.centerXAnchor),
            card.centerYAnchor.constraint(equalTo: overlay.centerYAnchor, constant: -10),
            card.widthAnchor.constraint(equalToConstant: min(340, max(260, bounds.width - 60))),
            icon.topAnchor.constraint(equalTo: card.topAnchor, constant: 22),
            icon.centerXAnchor.constraint(equalTo: card.centerXAnchor),
            icon.widthAnchor.constraint(equalToConstant: 30),
            icon.heightAnchor.constraint(equalToConstant: 30),
            title.topAnchor.constraint(equalTo: icon.bottomAnchor, constant: 8),
            title.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            title.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
            timer.topAnchor.constraint(equalTo: title.bottomAnchor, constant: 4),
            timer.centerXAnchor.constraint(equalTo: card.centerXAnchor),
            waveContainer.topAnchor.constraint(equalTo: timer.bottomAnchor, constant: 14),
            waveContainer.centerXAnchor.constraint(equalTo: card.centerXAnchor),
            waveContainer.heightAnchor.constraint(equalToConstant: 42),
            hint.topAnchor.constraint(equalTo: waveContainer.bottomAnchor, constant: 8),
            hint.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            hint.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
            cancel.topAnchor.constraint(equalTo: hint.bottomAnchor, constant: 18),
            cancel.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 24),
            cancel.widthAnchor.constraint(equalToConstant: 100),
            cancel.heightAnchor.constraint(equalToConstant: 38),
            done.topAnchor.constraint(equalTo: cancel.topAnchor),
            done.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -24),
            done.widthAnchor.constraint(equalToConstant: 100),
            done.heightAnchor.constraint(equalToConstant: 38),
            done.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -20)
        ])

        addSubview(overlay)
        voiceOverlay = overlay
        voiceSeconds = 0
        voiceTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self, weak waveContainer] _ in
            guard let self else { return }
            self.voiceSeconds += 1
            let minutes = self.voiceSeconds / 60
            let seconds = self.voiceSeconds % 60
            timer.text = String(format: "%02d:%02d", minutes, seconds)
            guard let bars = waveContainer?.arrangedSubviews else { return }
            for (index, bar) in bars.enumerated() {
                let target = CGFloat(8 + ([3, 18, 26, 12, 22, 16, 9][index % 7]))
                UIView.animate(withDuration: 0.25, delay: 0, options: [.autoreverse, .repeat, .allowUserInteraction]) {
                    bar.transform = CGAffineTransform(scaleX: 1, y: target / 10)
                } completion: { _ in
                    bar.transform = .identity
                }
            }
        }
        RunLoop.main.add(voiceTimer!, forMode: .common)
    }

    private func cancelVoice() {
        voiceTimer?.invalidate()
        voiceTimer = nil
        voiceOverlay?.removeFromSuperview()
        voiceOverlay = nil
        showToast("已取消语音")
    }

    private func finishVoice(overlay: UIView, card: UIView, timer: UILabel) {
        voiceTimer?.invalidate()
        voiceTimer = nil
        timer.text = "识别中…"
        UIView.animate(withDuration: 0.2) { card.alpha = 0.6 }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) { [weak self] in
            guard let self else { return }
            let offline = SettingsReader.defaults.bool(forKey: "voice_offline")
            let sample = offline
                ? "这是键盘内的离线语音示例，完整离线语音包可在 App 的语音设置中下载。"
                : "这是键盘内的语音示例，App 内会调用系统语音识别并支持编辑、撤回和发送。"
            self.actionDelegate?.keyboardInsert(sample)
            self.lastCommitted = sample
            self.voiceOverlay?.removeFromSuperview()
            self.voiceOverlay = nil
            self.reloadCandidateBar()
            self.showToast("已插入语音示例")
        }
    }

    // MARK: - Emoji / kaomoji

    func showEmojiPanel() {
        let stack = presentPanel(title: "表情") { _ in }
        var mode = 0
        let tabs = UIStackView()
        tabs.axis = .horizontal
        tabs.spacing = 8
        tabs.distribution = .fillEqually
        let emojiTab = tabButton("Emoji", selected: true)
        let kaoTab = tabButton("颜文字", selected: false)
        tabs.addArrangedSubview(emojiTab)
        tabs.addArrangedSubview(kaoTab)
        stack.addArrangedSubview(tabs)
        let gridHost = UIStackView()
        gridHost.axis = .vertical
        gridHost.spacing = 6
        stack.addArrangedSubview(gridHost)
        stack.addArrangedSubview(panelFootnote("点击插入到输入框。Emoji 与颜文字均为本地数据。"))
        let builder = EmojiGridBuilder(host: gridHost, theme: theme)
        builder.insert = { [weak self] value in
            self?.insertDirect(value)
            self?.showToast("已插入表情")
        }
        builder.buildEmoji()
        emojiTab.addAction(UIAction { _ in
            mode = 0
            emojiTab.backgroundColor = self.theme.accent
            kaoTab.backgroundColor = self.theme.key
            builder.buildEmoji()
        }, for: .touchUpInside)
        kaoTab.addAction(UIAction { _ in
            mode = 1
            emojiTab.backgroundColor = self.theme.key
            kaoTab.backgroundColor = self.theme.accent
            builder.buildKaomoji()
        }, for: .touchUpInside)
        _ = mode
    }

    private func tabButton(_ title: String, selected: Bool) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.setTitleColor(selected ? .white : theme.text, for: .normal)
        button.backgroundColor = selected ? theme.accent : theme.key
        button.titleLabel?.font = .systemFont(ofSize: 13, weight: .medium)
        button.layer.cornerRadius = 9
        button.heightAnchor.constraint(equalToConstant: 32).isActive = true
        return button
    }

    final class EmojiGridBuilder {
        let host: UIStackView
        let theme: KeyboardTheme
        var insert: ((String) -> Void)?

        init(host: UIStackView, theme: KeyboardTheme) {
            self.host = host
            self.theme = theme
        }

        func clear() {
            for view in host.arrangedSubviews {
                host.removeArrangedSubview(view)
                view.removeFromSuperview()
            }
        }

        func buildEmoji() {
            clear()
            for (category, emojis) in EmojiData.categories {
                let title = UILabel()
                title.text = category
                title.font = .systemFont(ofSize: 11, weight: .medium)
                title.textColor = theme.secondaryText
                host.addArrangedSubview(title)
                host.addArrangedSubview(rows(for: emojis, font: 23))
            }
        }

        func buildKaomoji() {
            clear()
            for (category, items) in EmojiData.kaomoji {
                let title = UILabel()
                title.text = category
                title.font = .systemFont(ofSize: 11, weight: .medium)
                title.textColor = theme.secondaryText
                host.addArrangedSubview(title)
                host.addArrangedSubview(rows(for: items, font: 12))
            }
        }

        private func rows(for items: [String], font: CGFloat) -> UIStackView {
            let outer = UIStackView()
            outer.axis = .vertical
            outer.spacing = 4
            var index = 0
            while index < items.count {
                let row = UIStackView()
                row.axis = .horizontal
                row.spacing = 4
                row.distribution = .fillEqually
                for _ in 0..<4 {
                    if index < items.count {
                        let value = items[index]
                        let button = UIButton(type: .system)
                        button.setTitle(value, for: .normal)
                        button.setTitleColor(theme.text, for: .normal)
                        button.titleLabel?.font = .systemFont(ofSize: font)
                        button.backgroundColor = theme.key
                        button.layer.cornerRadius = 8
                        button.heightAnchor.constraint(equalToConstant: font > 18 ? 38 : 34).isActive = true
                        button.addAction(UIAction { [weak self] _ in
                            self?.insert?(value)
                        }, for: .touchUpInside)
                        row.addArrangedSubview(button)
                    } else {
                        row.addArrangedSubview(UIView())
                    }
                    index += 1
                }
                outer.addArrangedSubview(row)
            }
            return outer
        }
    }

    // MARK: - Clipboard

    func showClipboardPanel() {
        let stack = presentPanel(title: "剪切板") { _ in }
        let items = SharedStore.data([ClipboardItem].self, forKey: "clipboard_items", fallback: [])
        let tabs = UIStackView()
        tabs.axis = .horizontal
        tabs.spacing = 8
        tabs.distribution = .fillEqually
        let local = tabButton("本机", selected: true)
        let cross = tabButton("跨设备", selected: false)
        tabs.addArrangedSubview(local)
        tabs.addArrangedSubview(cross)
        stack.addArrangedSubview(tabs)

        let list = UIStackView()
        list.axis = .vertical
        list.spacing = 6
        stack.addArrangedSubview(list)

        func reloadList() {
            for view in list.arrangedSubviews {
                list.removeArrangedSubview(view)
                view.removeFromSuperview()
            }
            if items.isEmpty {
                list.addArrangedSubview(panelFootnote("暂无剪贴板历史。复制文字后回到键盘即可看到。"))
            } else {
                for item in items.prefix(12) {
                    let button = panelRow(title: item.text, detail: item.displayTime, action: { [weak self] in
                        self?.insertDirect(item.text)
                        self?.closePanel()
                        self?.showToast("已插入剪贴板内容")
                    })
                    let long = UILongPressGestureRecognizer(target: self, action: #selector(self.handleClipboardLongPress(_:)))
                    objc_setAssociatedObject(button, &Self.clipboardKey, item, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
                    button.addGestureRecognizer(long)
                    list.addArrangedSubview(button)
                }
            }
        }
        reloadList()

        cross.addAction(UIAction { _ in
            local.backgroundColor = self.theme.key
            cross.backgroundColor = self.theme.accent
            for view in list.arrangedSubviews {
                list.removeArrangedSubview(view)
                view.removeFromSuperview()
            }
            let loggedIn = SharedStore.defaults.bool(forKey: "account_logged_in")
            list.addArrangedSubview(self.panelFootnote(loggedIn ? "跨设备剪切板需要开启“超级互传”，可在 App 的超级互传页管理设备。" : "未登录。打开 App → 账户 → 登录后即可跨设备同步。"))
            let copy = self.panelRow(title: "复制本机示例文本", detail: "用于测试互传", action: {
                UIPasteboard.general.string = "来自豆包输入法（iOS 复刻）的跨设备示例"
                self.showToast("已复制，可在其他设备粘贴")
            })
            list.addArrangedSubview(copy)
        }, for: .touchUpInside)
        local.addAction(UIAction { _ in
            local.backgroundColor = self.theme.accent
            cross.backgroundColor = self.theme.key
            reloadList()
        }, for: .touchUpInside)

        stack.addArrangedSubview(panelRow(title: "从系统剪贴板添加", detail: "读取当前剪贴板文字", action: { [weak self] in
            guard let text = UIPasteboard.general.string, !text.isEmpty else {
                self?.showToast("剪贴板为空")
                return
            }
            var all = SharedStore.data([ClipboardItem].self, forKey: "clipboard_items", fallback: [])
            all.removeAll { $0.text == text }
            all.insert(ClipboardItem(text: text), at: 0)
            SharedStore.save(Array(all.prefix(50)), forKey: "clipboard_items")
            self?.showClipboardPanel()
            self?.showToast("已添加")
        }))
        stack.addArrangedSubview(panelRow(title: "清空剪切板", detail: "仅清除本机历史", action: { [weak self] in
            SharedStore.save([ClipboardItem](), forKey: "clipboard_items")
            self?.showClipboardPanel()
            self?.showToast("已清空")
        }))
        stack.addArrangedSubview(panelFootnote("首次读取系统剪贴板时，iOS 可能显示粘贴授权提示。"))
    }

    @objc private func handleClipboardLongPress(_ gesture: UILongPressGestureRecognizer) {
        guard gesture.state == .began, let button = gesture.view,
              let item = objc_getAssociatedObject(button, &Self.clipboardKey) as? ClipboardItem else { return }
        let alert = UIAlertController(title: nil, message: item.text, preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "删除", style: .destructive) { [weak self] _ in
            var all = SharedStore.data([ClipboardItem].self, forKey: "clipboard_items", fallback: [])
            all.removeAll { $0.id == item.id }
            SharedStore.save(all, forKey: "clipboard_items")
            self?.showClipboardPanel()
            self?.showToast("已删除")
        })
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        if let pop = alert.popoverPresentationController {
            pop.sourceView = button
            pop.sourceRect = button.bounds
        }
        topViewController?.present(alert, animated: true)
    }

    // MARK: - Phrases

    func showPhrasesPanel() {
        let stack = presentPanel(title: "常用语") { _ in }
        let phrases = SharedStore.data([Phrase].self, forKey: "common_phrases", fallback: [])
        let list = UIStackView()
        list.axis = .vertical
        list.spacing = 6
        stack.addArrangedSubview(list)
        if phrases.isEmpty {
            list.addArrangedSubview(panelFootnote("暂无常用语，点击下方添加。"))
        }
        for phrase in phrases {
            let button = panelRow(title: phrase.text, detail: "\(phrase.category) · 使用 \(phrase.useCount) 次", action: { [weak self] in
                self?.insertDirect(phrase.text)
                self?.closePanel()
                self?.showToast("已插入常用语")
            })
            let long = UILongPressGestureRecognizer(target: self, action: #selector(self.handlePhraseLongPress(_:)))
            objc_setAssociatedObject(button, &Self.phraseKey, phrase, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            button.addGestureRecognizer(long)
            list.addArrangedSubview(button)
        }
        stack.addArrangedSubview(panelRow(title: "添加常用语", detail: "保存到本机并同步到 App", action: { [weak self] in
            guard let self else { return }
            let alert = UIAlertController(title: "添加常用语", message: nil, preferredStyle: .alert)
            alert.addTextField { field in
                field.placeholder = "输入内容"
            }
            alert.addTextField { field in
                field.placeholder = "分类（默认：通用）"
            }
            alert.addAction(UIAlertAction(title: "取消", style: .cancel))
            alert.addAction(UIAlertAction(title: "保存", style: .default) { _ in
                let text = alert.textFields?.first?.text ?? ""
                let category = alert.textFields?.last?.text ?? "通用"
                guard !text.trimmingCharacters(in: .whitespaces).isEmpty else { return }
                var all = SharedStore.data([Phrase].self, forKey: "common_phrases", fallback: [])
                all.insert(Phrase(text: text, category: category.isEmpty ? "通用" : category), at: 0)
                SharedStore.save(all, forKey: "common_phrases")
                self.showPhrasesPanel()
                self.showToast("已添加常用语")
            })
            self.topViewController?.present(alert, animated: true)
        }))
        stack.addArrangedSubview(panelRow(title: "在 App 中管理", detail: "编辑、分类、删除", action: { [weak self] in
            self?.actionDelegate?.keyboardShowMessage("请在 App 的“常用语”中管理")
            self?.showToast("请在 App 中管理常用语")
        }))
    }

    @objc private func handlePhraseLongPress(_ gesture: UILongPressGestureRecognizer) {
        guard gesture.state == .began, let button = gesture.view,
              let phrase = objc_getAssociatedObject(button, &Self.phraseKey) as? Phrase else { return }
        let alert = UIAlertController(title: nil, message: phrase.text, preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "删除", style: .destructive) { [weak self] _ in
            var all = SharedStore.data([Phrase].self, forKey: "common_phrases", fallback: [])
            all.removeAll { $0.id == phrase.id }
            SharedStore.save(all, forKey: "common_phrases")
            self?.showPhrasesPanel()
            self?.showToast("已删除")
        })
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        if let pop = alert.popoverPresentationController {
            pop.sourceView = button
            pop.sourceRect = button.bounds
        }
        topViewController?.present(alert, animated: true)
    }

    // MARK: - Symbols panel

    func showSymbolsPanel() {
        presentPanel(title: "符号") { stack in
            let groups: [[String]] = [
                ["，", "。", "？", "！", "、", "；", "：", "“", "”", "‘", "’"],
                ["（", "）", "《", "》", "【", "】", "…", "—", "～", "·", "￥"],
                ["+", "-", "×", "÷", "=", "≠", "≈", "≤", "≥", "°", "％"],
                ["@", "#", "$", "&", "*", "/", "\\", "|", "^", "_", "`"],
                ["①", "②", "③", "④", "⑤", "⑥", "⑦", "⑧", "⑨", "⑩", "→"]
            ]
            for group in groups {
                let row = UIStackView()
                row.axis = .horizontal
                row.spacing = 4
                row.distribution = .fillEqually
                for symbol in group {
                    let button = UIButton(type: .system)
                    button.setTitle(symbol, for: .normal)
                    button.setTitleColor(self.theme.text, for: .normal)
                    button.titleLabel?.font = .systemFont(ofSize: 17)
                    button.backgroundColor = self.theme.key
                    button.layer.cornerRadius = 7
                    button.heightAnchor.constraint(equalToConstant: 36).isActive = true
                    button.addAction(UIAction { [weak self] _ in self?.insertDirect(symbol) }, for: .touchUpInside)
                    row.addArrangedSubview(button)
                }
                stack.addArrangedSubview(row)
            }
            stack.addArrangedSubview(self.panelFootnote("点击符号直接上屏。侧边栏符号可在 App → 布局与显示中自定义。"))
        }
    }

    // MARK: - Height / one hand

    func showHeightPanel() {
        let stack = presentPanel(title: "键盘调节") { _ in }
        let valueLabel = UILabel()
        valueLabel.font = .monospacedDigitSystemFont(ofSize: 13, weight: .regular)
        valueLabel.textColor = theme.secondaryText
        valueLabel.text = "高度 \(Int(SettingsReader.keyboardHeight)) pt"
        stack.addArrangedSubview(valueLabel)
        let slider = UISlider()
        slider.minimumValue = 250
        slider.maximumValue = 420
        slider.value = Float(SettingsReader.keyboardHeight)
        slider.addAction(UIAction { [weak self] _ in
            let value = CGFloat(slider.value)
            SharedStore.defaults.set(Double(value), forKey: "keyboard_height")
            SharedStore.defaults.synchronize()
            valueLabel.text = "高度 \(Int(value)) pt"
            self?.actionDelegate?.keyboardRequestHeight(value)
        }, for: .valueChanged)
        stack.addArrangedSubview(slider)
        let row = UIStackView()
        row.axis = .horizontal
        row.spacing = 8
        row.distribution = .fillEqually
        for (title, value) in [("关闭单手", "off"), ("左手", "left"), ("右手", "right")] {
            let selected = SettingsReader.oneHand == value
            let button = UIButton(type: .system)
            button.setTitle(title, for: .normal)
            button.setTitleColor(selected ? .white : theme.text, for: .normal)
            button.backgroundColor = selected ? theme.accent : theme.key
            button.layer.cornerRadius = 9
            button.titleLabel?.font = .systemFont(ofSize: 12)
            button.heightAnchor.constraint(equalToConstant: 38).isActive = true
            button.addAction(UIAction { [weak self] _ in
                SharedStore.defaults.set(value, forKey: "one_hand")
                SharedStore.defaults.synchronize()
                self?.setNeedsLayout()
                self?.layoutIfNeeded()
                self?.showHeightPanel()
                self?.showToast(value == "off" ? "已恢复双手" : "单手模式已开启")
            }, for: .touchUpInside)
            row.addArrangedSubview(button)
        }
        stack.addArrangedSubview(row)
        stack.addArrangedSubview(panelRow(title: "候选字号调节", detail: "在 App → 布局与显示中实时预览", action: { [weak self] in
            self?.showToast("请在 App 中调整候选字号")
        }))
        stack.addArrangedSubview(panelRow(title: "恢复默认", detail: "高度 300 pt，关闭单手", action: { [weak self] in
            SharedStore.defaults.set(300.0, forKey: "keyboard_height")
            SharedStore.defaults.set("off", forKey: "one_hand")
            SharedStore.defaults.synchronize()
            self?.actionDelegate?.keyboardRequestHeight(300)
            self?.showHeightPanel()
            self?.showToast("已恢复默认")
        }))
    }

    // MARK: - Keyboard picker

    func showKeyboardPicker() {
        presentPanel(title: "键盘选择") { stack in
            var items: [(String, String, () -> Void)] = []
            for kind in KeyboardKind.allCases {
                let marker = kind == self.keyboardKind ? "✓ " : ""
                items.append((marker + kind.title, kind.symbol, { [weak self] in
                    SharedStore.defaults.set(kind.rawValue, forKey: "keyboard_type")
                    SharedStore.defaults.set(true, forKey: "keyboard_type_picked")
                    SharedStore.defaults.synchronize()
                    self?.keyboardKind = kind
                    self?.rebuildForKind()
                    self?.closePanel()
                    self?.showToast("已切换为\(kind.title)")
                }))
            }
            stack.addArrangedSubview(self.panelGrid(items: items, columns: 2))
            stack.addArrangedSubview(self.panelFootnote("选择会立即生效并同步到 App。双拼/五笔为演示级编码覆盖。"))
        }
    }

    // MARK: - Translate

    func showTranslatePanel() {
        let stack = presentPanel(title: "翻译") { _ in }
        var toEnglish = true
        let direction = UIButton(type: .system)
        direction.setTitle("中文 → English", for: .normal)
        direction.setTitleColor(theme.text, for: .normal)
        direction.backgroundColor = theme.key
        direction.layer.cornerRadius = 9
        direction.titleLabel?.font = .systemFont(ofSize: 13)
        direction.heightAnchor.constraint(equalToConstant: 34).isActive = true
        stack.addArrangedSubview(direction)

        let field = UITextField()
        field.placeholder = "输入要翻译的文字"
        field.textColor = theme.text
        field.backgroundColor = theme.key
        field.layer.cornerRadius = 9
        field.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 10, height: 1))
        field.leftViewMode = .always
        field.heightAnchor.constraint(equalToConstant: 40).isActive = true
        stack.addArrangedSubview(field)

        let result = UILabel()
        result.text = "翻译结果会显示在这里"
        result.textColor = theme.secondaryText
        result.font = .systemFont(ofSize: 14)
        result.numberOfLines = 0
        result.backgroundColor = theme.key
        result.layer.cornerRadius = 9
        result.clipsToBounds = true
        stack.addArrangedSubview(result)

        let row = UIStackView()
        row.axis = .horizontal
        row.spacing = 8
        row.distribution = .fillEqually
        let translate = UIButton(type: .system)
        translate.setTitle("翻译", for: .normal)
        translate.setTitleColor(.white, for: .normal)
        translate.backgroundColor = theme.accent
        translate.layer.cornerRadius = 9
        translate.heightAnchor.constraint(equalToConstant: 38).isActive = true
        row.addArrangedSubview(translate)
        let insert = UIButton(type: .system)
        insert.setTitle("插入结果", for: .normal)
        insert.setTitleColor(theme.text, for: .normal)
        insert.backgroundColor = theme.key
        insert.layer.cornerRadius = 9
        insert.heightAnchor.constraint(equalToConstant: 38).isActive = true
        row.addArrangedSubview(insert)
        stack.addArrangedSubview(row)

        direction.addAction(UIAction { _ in
            toEnglish.toggle()
            direction.setTitle(toEnglish ? "中文 → English" : "English → 中文", for: .normal)
            result.text = "翻译结果会显示在这里"
        }, for: .touchUpInside)
        translate.addAction(UIAction { _ in
            let text = field.text ?? ""
            result.text = LocalIntelligence.translate(text, toEnglish: toEnglish)
            result.textColor = self.theme.text
        }, for: .touchUpInside)
        insert.addAction(UIAction { [weak self] _ in
            let text = result.text ?? ""
            guard !text.isEmpty, text != "翻译结果会显示在这里" else { return }
            self?.insertDirect(text)
            self?.closePanel()
            self?.showToast("已插入翻译")
        }, for: .touchUpInside)
        stack.addArrangedSubview(panelFootnote("离线词典示例；在 App 配置 DeepSeek Key 后可获得完整翻译。"))
    }

    // MARK: - Smart organize

    func showOrganizePanel() {
        let stack = presentPanel(title: "智能整理") { _ in }
        let input = UITextView()
        input.text = lastCommitted.isEmpty ? "嗯那个我们今天就是说把这个事情然后呢处理一下" : lastCommitted
        input.font = .systemFont(ofSize: 14)
        input.textColor = theme.text
        input.backgroundColor = theme.key
        input.layer.cornerRadius = 9
        input.heightAnchor.constraint(equalToConstant: 80).isActive = true
        stack.addArrangedSubview(input)
        let result = UILabel()
        result.text = "整理结果"
        result.textColor = theme.secondaryText
        result.font = .systemFont(ofSize: 14)
        result.numberOfLines = 0
        result.backgroundColor = theme.key
        result.layer.cornerRadius = 9
        result.clipsToBounds = true
        stack.addArrangedSubview(result)
        let row = UIStackView()
        row.axis = .horizontal
        row.spacing = 8
        row.distribution = .fillEqually
        let organize = UIButton(type: .system)
        organize.setTitle("整理", for: .normal)
        organize.setTitleColor(.white, for: .normal)
        organize.backgroundColor = theme.accent
        organize.layer.cornerRadius = 9
        organize.heightAnchor.constraint(equalToConstant: 38).isActive = true
        row.addArrangedSubview(organize)
        let replace = UIButton(type: .system)
        replace.setTitle("插入结果", for: .normal)
        replace.setTitleColor(theme.text, for: .normal)
        replace.backgroundColor = theme.key
        replace.layer.cornerRadius = 9
        replace.heightAnchor.constraint(equalToConstant: 38).isActive = true
        row.addArrangedSubview(replace)
        stack.addArrangedSubview(row)
        organize.addAction(UIAction { _ in
            let clean = LocalIntelligence.organize(input.text, removeFillers: true, blankLineParagraphs: false, punctuation: "smart")
            result.text = clean
            result.textColor = self.theme.text
        }, for: .touchUpInside)
        replace.addAction(UIAction { [weak self] _ in
            guard let text = result.text, text != "整理结果" else { return }
            self?.insertDirect(text)
            self?.closePanel()
            self?.showToast("已插入整理结果")
        }, for: .touchUpInside)
        stack.addArrangedSubview(panelFootnote("本地规则整理，去除口水词并补齐标点。App 内可接入 AI 服务。"))
    }

    // MARK: - AI writing

    func showAIPanel() {
        let stack = presentPanel(title: "AI 写作（离线示例）") { _ in }
        let actions = ["祝福", "高赞动态", "写评论", "自我介绍", "宴席邀请", "写邮件", "爆款文案"]
        let grid = UIStackView()
        grid.axis = .vertical
        grid.spacing = 6
        var rows: [[String]] = []
        var current: [String] = []
        for action in actions {
            current.append(action)
            if current.count == 3 { rows.append(current); current = [] }
        }
        if !current.isEmpty { rows.append(current) }
        let resultLabel = UILabel()
        for rowItems in rows {
            let row = UIStackView()
            row.axis = .horizontal
            row.spacing = 6
            row.distribution = .fillEqually
            for action in rowItems {
                let button = UIButton(type: .system)
                button.setTitle(action, for: .normal)
                button.setTitleColor(theme.text, for: .normal)
                button.backgroundColor = theme.key
                button.layer.cornerRadius = 9
                button.titleLabel?.font = .systemFont(ofSize: 12)
                button.heightAnchor.constraint(equalToConstant: 36).isActive = true
                button.addAction(UIAction { [weak self] _ in
                    guard let self else { return }
                    resultLabel.text = LocalIntelligence.actionTemplates(action, context: self.lastCommitted)
                    resultLabel.textColor = self.theme.text
                }, for: .touchUpInside)
                row.addArrangedSubview(button)
            }
            grid.addArrangedSubview(row)
        }
        stack.addArrangedSubview(grid)
        resultLabel.text = "选择场景生成示例文案"
        resultLabel.font = .systemFont(ofSize: 14)
        resultLabel.textColor = theme.secondaryText
        resultLabel.numberOfLines = 0
        resultLabel.backgroundColor = theme.key
        resultLabel.layer.cornerRadius = 9
        resultLabel.clipsToBounds = true
        stack.addArrangedSubview(resultLabel)
        stack.addArrangedSubview(panelRow(title: "插入结果", action: { [weak self] in
            guard let text = resultLabel.text, text != "选择场景生成示例文案" else { return }
            self?.insertDirect(text)
            self?.closePanel()
            self?.showToast("已插入")
        }))
        stack.addArrangedSubview(panelFootnote("键盘内仅提供离线模板。App → AI 服务 配置 Key 后可调用 DeepSeek 生成。"))
    }

    // MARK: - Custom toolbar

    func showCustomToolbarPanel() {
        let stack = presentPanel(title: "定制工具栏") { _ in }
        let options: [(String, String)] = [
            ("voice", "语音输入"), ("clipboard", "剪切板"), ("emoji", "表情"),
            ("phrases", "常用语"), ("switch", "键盘切换"), ("onehand", "单手"),
            ("height", "键盘调节"), ("dismiss", "收起"), ("translate", "翻译"),
            ("ai", "AI 写作"), ("organize", "智能整理")
        ]
        let selected = Set(SharedStore.stringArray("custom_toolbar"))
        for option in options {
            let on = selected.contains(option.0)
            stack.addArrangedSubview(panelRow(title: option.1, detail: on ? "显示在工具栏" : "已隐藏", check: on, action: { [weak self] in
                var list = SharedStore.stringArray("custom_toolbar")
                if list.contains(option.0) { list.removeAll { $0 == option.0 } } else { list.append(option.0) }
                SharedStore.defaults.set(list, forKey: "custom_toolbar")
                SharedStore.defaults.synchronize()
                self?.rebuildToolbarItems()
                self?.showCustomToolbarPanel()
                self?.showToast("工具栏已更新")
            }))
        }
        stack.addArrangedSubview(panelRow(title: "恢复默认", action: { [weak self] in
            SharedStore.defaults.set(["voice", "clipboard", "emoji", "phrases", "switch", "onehand", "height", "dismiss"], forKey: "custom_toolbar")
            SharedStore.defaults.synchronize()
            self?.rebuildToolbarItems()
            self?.showCustomToolbarPanel()
            self?.showToast("已恢复默认工具栏")
        }))
    }

    // MARK: - Handwriting lookup

    func openHandwritingLookup() {
        let stack = presentPanel(title: "手写找字") { _ in }
        let field = UITextField()
        field.placeholder = "输入部件、拼音或文字"
        field.textColor = theme.text
        field.backgroundColor = theme.key
        field.layer.cornerRadius = 9
        field.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 10, height: 1))
        field.leftViewMode = .always
        field.heightAnchor.constraint(equalToConstant: 40).isActive = true
        stack.addArrangedSubview(field)
        let results = UIStackView()
        results.axis = .vertical
        results.spacing = 6
        stack.addArrangedSubview(results)
        let search = UIButton(type: .system)
        search.setTitle("查找", for: .normal)
        search.setTitleColor(.white, for: .normal)
        search.backgroundColor = theme.accent
        search.layer.cornerRadius = 9
        search.heightAnchor.constraint(equalToConstant: 38).isActive = true
        stack.addArrangedSubview(search)
        search.addAction(UIAction { [weak self] _ in
            guard let self else { return }
            for view in results.arrangedSubviews {
                results.removeArrangedSubview(view)
                view.removeFromSuperview()
            }
            let text = field.text ?? ""
            let pinyinMatches = PinyinEngine.shared.candidates(for: text, script: .pinyin, limit: 12)
            let wordMatches = PinyinEngine.shared.searchWords(query: text, limit: 12)
            var seen = Set<String>()
            let mixed = (pinyinMatches + wordMatches).filter { seen.insert($0.text).inserted }
            if mixed.isEmpty {
                results.addArrangedSubview(self.panelFootnote("没有找到匹配的字词，试试输入完整拼音。"))
            }
            for item in mixed {
                let button = self.panelRow(title: item.text, detail: item.detail, action: { [weak self] in
                    self?.insertDirect(item.text)
                    self?.closePanel()
                })
                results.addArrangedSubview(button)
            }
        }, for: .touchUpInside)
        stack.addArrangedSubview(panelFootnote("支持拼音、简拼和词语检索。"))
    }

    // MARK: - Misc

    func toggleTraditional() {
        let current = SharedStore.defaults.bool(forKey: "traditional_enabled")
        SharedStore.defaults.set(!current, forKey: "traditional_enabled")
        SharedStore.defaults.synchronize()
        showToast(!current ? "已切换为繁体输出" : "已切换回简体")
    }

    func showMoreSettings() {
        presentPanel(title: "更多设置") { stack in
            let rows: [(String, String, () -> Void)] = [
                ("键盘类型", "切换 9 键 / 26 键 / 手写 / 双拼 / 五笔", { [weak self] in self?.showKeyboardPicker() }),
                ("布局与显示", "候选字号、外观、单手、键盘高度", { [weak self] in self?.showHeightPanel() }),
                ("智能整理", "离线规则整理当前输入", { [weak self] in self?.showOrganizePanel() }),
                ("翻译", "本地词库中英互译", { [weak self] in self?.showTranslatePanel() }),
                ("剪切板", "历史记录与清空", { [weak self] in self?.showClipboardPanel() }),
                ("常用语", "管理与插入", { [weak self] in self?.showPhrasesPanel() })
            ]
            for row in rows {
                stack.addArrangedSubview(self.panelRow(title: row.0, detail: row.1, action: row.2))
            }
            stack.addArrangedSubview(self.panelFootnote("完整设置（语音、隐私、账户、词库等）在豆包输入法 App 中。"))
        }
    }

    func showHelpPanel() {
        presentPanel(title: "帮助与反馈") { stack in
            stack.addArrangedSubview(self.panelFootnote("启用键盘：设置 → 通用 → 键盘 → 键盘 → 添加新键盘 → 豆包输入法（iOS 复刻），然后在输入框长按地球键切换。"))
            let faqs: [(String, String)] = [
                ("为什么键盘没有候选？", "请确认已允许完全访问；词典随扩展打包，本地加载无需网络。"),
                ("如何切换 9 键？", "工具箱 → 键盘选择，或在 App 的键盘类型页切换。"),
                ("语音为什么是示例？", "键盘扩展内的语音为离线示例；完整语音在 App 内使用系统语音识别。"),
                ("如何调整高度？", "工具栏调节按钮，或 App → 布局与显示。")
            ]
            for faq in faqs {
                let label = UILabel()
                label.text = "Q：\(faq.0)\nA：\(faq.1)"
                label.numberOfLines = 0
                label.font = .systemFont(ofSize: 12)
                label.textColor = self.theme.secondaryText
                label.backgroundColor = self.theme.key
                label.layer.cornerRadius = 9
                label.clipsToBounds = true
                stack.addArrangedSubview(label)
            }
            stack.addArrangedSubview(self.panelRow(title: "复制使用说明", action: {
                UIPasteboard.general.string = "设置 → 通用 → 键盘 → 键盘 → 添加新键盘 → 豆包输入法（iOS 复刻）"
                self.showToast("已复制使用说明")
            }))
        }
    }

    static var clipboardKey: UInt8 = 0
    static var phraseKey: UInt8 = 0
}
