import UIKit
import AudioToolbox

protocol KeyboardActionDelegate: AnyObject {
    func keyboardInsert(_ text: String)
    func keyboardDelete()
    func keyboardReturn()
    func keyboardNextInputMode()
    func keyboardDismiss()
    func keyboardRequestHeight(_ height: CGFloat)
    func keyboardShowMessage(_ message: String)
}

extension KeyboardActionDelegate {
    func keyboardShowMessage(_ message: String) {}
}

enum KeyboardPage {
    case letters
    case numbers
    case symbols
    case t9
    case handwriting
    case stroke
}

final class KBKeyButton: UIButton {
    var specID: String = ""
    var units: CGFloat = 1
    var normalColor: UIColor = .white
    var pressedColor: UIColor = .lightGray
    var useFunctionStyle = false

    override var isHighlighted: Bool {
        didSet {
            backgroundColor = isHighlighted ? pressedColor : normalColor
        }
    }
}

final class KeyboardRootView: UIView {
    weak var actionDelegate: KeyboardActionDelegate?

    // MARK: State
    var keyboardKind: KeyboardKind = SettingsReader.keyboardKind
    var page: KeyboardPage = .letters
    var language: String = "zh" // zh / en
    var shiftState: Int = 0 // 0 off, 1 shifted, 2 locked
    var composition: String = ""
    var englishBuffer: String = ""
    var candidates: [Candidate] = []
    var candidatePage: Int = 0
    var lastCommitted: String = ""
    var theme: KeyboardTheme = .current(dark: false)
    var returnKeyTitle: String = "换行"
    var scriptOverride: InputScript?

    // MARK: Views
    let toolbarScroll = UIScrollView()
    let toolbarStack = UIStackView()
    let candidateScroll = UIScrollView()
    let candidateStack = UIStackView()
    let candidateBackground = UIView()
    let prevButton = UIButton(type: .system)
    let nextButton = UIButton(type: .system)
    let keyContainer = UIView()
    let handwritingCanvas = HandwritingCanvasView()
    var panelOverlay: UIView?
    var toastLabel: UILabel?
    var voiceOverlay: UIView?

    var keyRows: [[KBKeyButton]] = []
    var rowUnits: [[CGFloat]] = []
    var rowInsets: [CGFloat] = []
    var t9SideKeys: [KBKeyButton] = []
    var t9LetterKeys: [KBKeyButton] = []
    var t9RightKeys: [KBKeyButton] = []
    var t9BottomKeys: [KBKeyButton] = []
    var handwritingButtons: [KBKeyButton] = []
    var allKeyButtons: [KBKeyButton] = []

    var backspaceTimer: Timer?
    var backspaceKey: KBKeyButton?
    var shiftKey: KBKeyButton?
    var alternatePopup: UIView?
    var lastShiftTap: Date = .distantPast
    var lastSpaceTap: Date = .distantPast
    var voiceTimer: Timer?
    var voiceSeconds = 0

    // MARK: Init
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    private func commonInit() {
        clipsToBounds = true
        backgroundColor = theme.background
        reloadTheme()
        setupToolbar()
        setupCandidateBar()
        keyContainer.backgroundColor = .clear
        addSubview(keyContainer)
        handwritingCanvas.isHidden = true
        handwritingCanvas.onRecognized = { [weak self] results in
            guard let self else { return }
            if results.isEmpty {
                self.showToast("换个写法试试")
            } else {
                self.candidates = results.enumerated().map { index, text in
                    Candidate(text: text, pinyin: "", detail: "手写识别", score: Double(100 - index), source: "手写")
                }
                self.candidatePage = 0
                self.reloadCandidateBar()
            }
        }
        addSubview(handwritingCanvas)
        buildKeyboard()
        NotificationCenter.default.addObserver(self, selector: #selector(settingsChanged), name: UserDefaults.didChangeNotification, object: nil)
    }

    deinit {
        backspaceTimer?.invalidate()
        voiceTimer?.invalidate()
        NotificationCenter.default.removeObserver(self)
    }

    @objc private func settingsChanged() {
        let newTheme = makeTheme()
        if newTheme.background != theme.background {
            theme = newTheme
            applyTheme()
        }
        if SettingsReader.keyboardKind != keyboardKind && panelOverlay == nil {
            keyboardKind = SettingsReader.keyboardKind
            rebuildForKind()
        }
    }

    private func makeTheme() -> KeyboardTheme {
        let dark = KeyboardTheme.resolvedDark(themeMode: SettingsReader.themeMode, traits: traitCollection)
        return KeyboardTheme.current(dark: dark)
    }

    func reloadTheme() {
        theme = makeTheme()
        applyTheme()
    }

    private func applyTheme() {
        backgroundColor = theme.background
        candidateBackground.backgroundColor = theme.background
        keyContainer.backgroundColor = .clear
        toolbarScroll.backgroundColor = theme.background
        for button in allKeyButtons {
            button.normalColor = button.useFunctionStyle ? theme.keyFunction : theme.key
            button.pressedColor = button.useFunctionStyle ? theme.keyFunctionPressed : theme.keyPressed
            button.backgroundColor = button.normalColor
            button.setTitleColor(theme.text, for: .normal)
        }
        prevButton.tintColor = theme.secondaryText
        nextButton.tintColor = theme.secondaryText
        handwritingCanvas.theme = theme
        handwritingCanvas.setNeedsDisplay()
        reloadCandidateBar()
        rebuildToolbarItems()
        setNeedsLayout()
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if previousTraitCollection?.userInterfaceStyle != traitCollection.userInterfaceStyle {
            reloadTheme()
        }
    }

    // MARK: - Toolbar
    private func setupToolbar() {
        toolbarScroll.showsHorizontalScrollIndicator = false
        toolbarScroll.alwaysBounceHorizontal = true
        toolbarStack.axis = .horizontal
        toolbarStack.alignment = .center
        toolbarStack.spacing = 6
        toolbarScroll.addSubview(toolbarStack)
        toolbarStack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            toolbarStack.leadingAnchor.constraint(equalTo: toolbarScroll.contentLayoutGuide.leadingAnchor, constant: 6),
            toolbarStack.trailingAnchor.constraint(equalTo: toolbarScroll.contentLayoutGuide.trailingAnchor, constant: -6),
            toolbarStack.topAnchor.constraint(equalTo: toolbarScroll.contentLayoutGuide.topAnchor),
            toolbarStack.bottomAnchor.constraint(equalTo: toolbarScroll.contentLayoutGuide.bottomAnchor),
            toolbarStack.heightAnchor.constraint(equalTo: toolbarScroll.frameLayoutGuide.heightAnchor)
        ])
        addSubview(toolbarScroll)
        rebuildToolbarItems()
    }

    func rebuildToolbarItems() {
        for view in toolbarStack.arrangedSubviews {
            toolbarStack.removeArrangedSubview(view)
            view.removeFromSuperview()
        }
        // The toolbox stays pinned; the remaining items are user-customizable.
        toolbarStack.addArrangedSubview(toolbarIcon("square.grid.2x2", label: "工具箱", action: #selector(openToolbox)))
        var ids = SharedStore.stringArray("custom_toolbar")
        if ids.isEmpty { ids = ["voice", "clipboard", "emoji", "phrases", "switch", "onehand", "height", "dismiss"] }
        for id in ids {
            if let item = toolbarItem(for: id) {
                toolbarStack.addArrangedSubview(item)
            }
        }
        setNeedsLayout()
    }

    private func toolbarItem(for id: String) -> UIView? {
        switch id {
        case "voice":
            return toolbarPill(icon: "mic.fill", text: "点击说话", action: #selector(openVoice))
        case "clipboard":
            return toolbarIcon("doc.on.clipboard", label: "剪切板", action: #selector(openClipboard))
        case "emoji":
            return toolbarIcon("face.smiling", label: "表情", action: #selector(openEmoji))
        case "phrases":
            return toolbarIcon("text.bubble", label: "常用语", action: #selector(openPhrases))
        case "switch":
            return toolbarIcon("globe", label: "键盘", action: #selector(nextInputMode))
        case "onehand":
            return toolbarIcon("rectangle.righthalf.inset.filled", label: "单手", action: #selector(toggleOneHand))
        case "height":
            return toolbarIcon("arrow.up.and.down", label: "调节", action: #selector(openHeightPanel))
        case "dismiss":
            return toolbarIcon("chevron.down", label: "收起", action: #selector(dismissKeyboard))
        case "translate":
            return toolbarIcon("character.bubble", label: "翻译", action: #selector(openTranslateToolbar))
        case "ai":
            return toolbarIcon("sparkles", label: "AI 写作", action: #selector(openAIToolbar))
        case "organize":
            return toolbarIcon("wand.and.stars", label: "智能整理", action: #selector(openOrganizeToolbar))
        default:
            return nil
        }
    }

    private func toolbarIcon(_ symbol: String, label: String, action: Selector) -> UIButton {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: symbol), for: .normal)
        button.tintColor = theme.secondaryText
        button.accessibilityLabel = label
        button.addTarget(self, action: action, for: .touchUpInside)
        button.widthAnchor.constraint(equalToConstant: 34).isActive = true
        button.heightAnchor.constraint(equalToConstant: 32).isActive = true
        return button
    }

    private func toolbarPill(icon: String, text: String, action: Selector) -> UIButton {
        var config = UIButton.Configuration.plain()
        config.image = UIImage(systemName: icon)
        config.title = text
        config.imagePadding = 4
        config.baseForegroundColor = theme.secondaryText
        config.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 10, bottom: 0, trailing: 10)
        config.background.backgroundColor = theme.panel.withAlphaComponent(0.75)
        config.background.cornerRadius = 14
        let button = UIButton(configuration: config)
        button.addTarget(self, action: action, for: .touchUpInside)
        button.heightAnchor.constraint(equalToConstant: 30).isActive = true
        return button
    }

    private func setupCandidateBar() {
        candidateBackground.backgroundColor = theme.background
        addSubview(candidateBackground)
        candidateStack.axis = .horizontal
        candidateStack.alignment = .center
        candidateStack.spacing = 2
        candidateScroll.showsHorizontalScrollIndicator = false
        candidateScroll.alwaysBounceHorizontal = true
        candidateScroll.addSubview(candidateStack)
        candidateStack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            candidateStack.leadingAnchor.constraint(equalTo: candidateScroll.contentLayoutGuide.leadingAnchor, constant: 4),
            candidateStack.trailingAnchor.constraint(equalTo: candidateScroll.contentLayoutGuide.trailingAnchor, constant: -4),
            candidateStack.topAnchor.constraint(equalTo: candidateScroll.contentLayoutGuide.topAnchor),
            candidateStack.bottomAnchor.constraint(equalTo: candidateScroll.contentLayoutGuide.bottomAnchor),
            candidateStack.heightAnchor.constraint(equalTo: candidateScroll.frameLayoutGuide.heightAnchor)
        ])
        addSubview(candidateScroll)
        prevButton.setTitle("‹", for: .normal)
        prevButton.titleLabel?.font = .systemFont(ofSize: 26)
        prevButton.tintColor = theme.secondaryText
        prevButton.addTarget(self, action: #selector(previousPage), for: .touchUpInside)
        nextButton.setTitle("›", for: .normal)
        nextButton.titleLabel?.font = .systemFont(ofSize: 26)
        nextButton.tintColor = theme.secondaryText
        nextButton.addTarget(self, action: #selector(nextPage), for: .touchUpInside)
        addSubview(prevButton)
        addSubview(nextButton)
    }

    // MARK: - Layout
    override func layoutSubviews() {
        super.layoutSubviews()
        let visibleWidth = min(bounds.width, UIScreen.main.bounds.width)
        let width = min(max(320, visibleWidth - 8), KeyboardMetrics.maxWidth)
        var contentX = max(0, (visibleWidth - width) / 2)
        var contentWidth = width
        let hand = SettingsReader.oneHand
        if SettingsReader.floating {
            contentWidth = width * 0.88
            contentX = (bounds.width - contentWidth) / 2
        } else if hand == "left" {
            contentWidth = width * 0.84
            contentX = 4
        } else if hand == "right" {
            contentWidth = width * 0.84
            contentX = bounds.width - contentWidth - 4
        }
        let content = CGRect(x: contentX, y: 0, width: contentWidth, height: bounds.height)

        toolbarScroll.frame = CGRect(x: content.minX, y: 0, width: content.width, height: KeyboardMetrics.toolbarHeight)
        candidateBackground.frame = CGRect(x: content.minX, y: KeyboardMetrics.toolbarHeight, width: content.width, height: KeyboardMetrics.candidateHeight)
        let arrowWidth: CGFloat = 20
        prevButton.frame = CGRect(x: content.maxX - arrowWidth * 2 - 4, y: KeyboardMetrics.toolbarHeight, width: arrowWidth, height: KeyboardMetrics.candidateHeight)
        nextButton.frame = CGRect(x: content.maxX - arrowWidth - 4, y: KeyboardMetrics.toolbarHeight, width: arrowWidth, height: KeyboardMetrics.candidateHeight)
        prevButton.isHidden = candidatePage == 0 || candidates.count <= 9
        nextButton.isHidden = (candidatePage + 1) * 9 >= candidates.count
        candidateScroll.frame = CGRect(x: content.minX + 4, y: KeyboardMetrics.toolbarHeight, width: content.width - 8, height: KeyboardMetrics.candidateHeight)

        let keyboardTop = KeyboardMetrics.toolbarHeight + KeyboardMetrics.candidateHeight
        let keyboardRect = CGRect(x: content.minX, y: keyboardTop, width: content.width, height: bounds.height - keyboardTop)
        keyContainer.frame = keyboardRect
        handwritingCanvas.frame = CGRect(x: content.minX, y: keyboardTop, width: content.width, height: keyboardRect.height)

        if page == .handwriting {
            layoutHandwriting(in: keyContainer.bounds)
        } else if page == .t9 {
            layoutT9(in: keyContainer.bounds)
        } else if page == .stroke {
            layoutStroke(in: keyContainer.bounds)
        } else {
            layoutRows(in: keyContainer.bounds)
        }
        if let panel = panelOverlay {
            panel.frame = CGRect(x: content.minX, y: KeyboardMetrics.toolbarHeight, width: content.width, height: bounds.height - KeyboardMetrics.toolbarHeight)
        }
        if let voice = voiceOverlay {
            voice.frame = bounds
        }
        attachSubtitleLayout()
    }

    private func layoutRows(in rect: CGRect) {
        guard !keyRows.isEmpty else { return }
        let count = keyRows.count
        let gap = KeyboardMetrics.gap
        let rowHeight = (rect.height - CGFloat(count - 1) * gap - 6) / CGFloat(count)
        var y = rect.minY + 2
        for (rowIndex, row) in keyRows.enumerated() {
            let units = rowUnits[rowIndex]
            let total = units.reduce(0, +)
            let innerWidth = rect.width - KeyboardMetrics.sideInset * 2
            let unit = (innerWidth - gap * CGFloat(max(0, row.count - 1))) / max(total, 0.1)
            var x = rect.minX + KeyboardMetrics.sideInset + rowInsets[rowIndex] * unit
            for (i, key) in row.enumerated() {
                let w = unit * units[i]
                key.frame = CGRect(x: x, y: y, width: w, height: rowHeight)
                x += w + gap
            }
            y += rowHeight + gap
        }
    }

    private func layoutT9(in rect: CGRect) {
        guard !t9LetterKeys.isEmpty else { return }
        let gap = KeyboardMetrics.gap
        let bottomHeight = max(40, rect.height * 0.18)
        let gridHeight = rect.height - bottomHeight - gap - 4
        let rowHeight = (gridHeight - gap * 3) / 4
        let totalUnits: CGFloat = 0.9 + 3 + 1.15
        let unit = (rect.width - KeyboardMetrics.sideInset * 2 - gap * 4) / totalUnits
        let sideWidth = unit * 0.9
        let rightWidth = unit * 1.15
        let x0 = rect.minX + KeyboardMetrics.sideInset
        let x1 = x0 + sideWidth + gap
        let gridWidth = unit * 3 + gap * 2
        let x2 = x1 + gridWidth + gap
        let y0 = rect.minY + 2

        for (i, key) in t9SideKeys.enumerated() {
            key.frame = CGRect(x: x0, y: y0 + CGFloat(i) * (rowHeight + gap), width: sideWidth, height: rowHeight)
        }
        for (i, key) in t9LetterKeys.enumerated() {
            let col = i % 3
            let row = i / 3
            key.frame = CGRect(x: x1 + CGFloat(col) * (unit + gap), y: y0 + CGFloat(row) * (rowHeight + gap), width: unit, height: rowHeight)
        }
        if t9RightKeys.count >= 3 {
            t9RightKeys[0].frame = CGRect(x: x2, y: y0, width: rightWidth, height: rowHeight)
            t9RightKeys[1].frame = CGRect(x: x2, y: y0 + rowHeight + gap, width: rightWidth, height: rowHeight)
            t9RightKeys[2].frame = CGRect(x: x2, y: y0 + (rowHeight + gap) * 2, width: rightWidth, height: rowHeight * 2 + gap)
        }
        let bottomY = y0 + gridHeight + gap
        let bottomUnits: [CGFloat] = [1.0, 1.0, 2.7, 1.2]
        let bottomTotal = bottomUnits.reduce(0, +)
        let bUnit = (rect.width - KeyboardMetrics.sideInset * 2 - gap * 3) / bottomTotal
        var bx = rect.minX + KeyboardMetrics.sideInset
        for (i, key) in t9BottomKeys.enumerated() where i < bottomUnits.count {
            let w = bottomUnits[i] * bUnit
            key.frame = CGRect(x: bx, y: bottomY, width: w, height: bottomHeight)
            bx += w + gap
        }
    }

    private func layoutStroke(in rect: CGRect) {
        guard keyRows.count >= 2 else { return }
        let gap = KeyboardMetrics.gap
        let topHeight = rect.height * 0.58
        let rowGap = gap
        let firstRow = keyRows[0]
        let unit = (rect.width - KeyboardMetrics.sideInset * 2 - gap * CGFloat(firstRow.count - 1)) / CGFloat(firstRow.count)
        var x = rect.minX + KeyboardMetrics.sideInset
        let firstY = rect.minY + 4
        let firstH = topHeight / 2 - gap
        for key in firstRow {
            key.frame = CGRect(x: x, y: firstY, width: unit, height: firstH)
            x += unit + gap
        }
        let second = keyRows[1]
        let unit2 = (rect.width - KeyboardMetrics.sideInset * 2 - gap * CGFloat(second.count - 1)) / CGFloat(second.count)
        x = rect.minX + KeyboardMetrics.sideInset
        for key in second {
            key.frame = CGRect(x: x, y: firstY + firstH + rowGap, width: unit2, height: firstH)
            x += unit2 + gap
        }
        if keyRows.count > 2 {
            let bottom = keyRows[2]
            let bottomY = firstY + firstH * 2 + rowGap + 8
            let bottomH = rect.maxY - bottomY - 6
            let bUnit = (rect.width - KeyboardMetrics.sideInset * 2 - gap * CGFloat(bottom.count - 1)) / CGFloat(bottom.count)
            x = rect.minX + KeyboardMetrics.sideInset
            for key in bottom {
                key.frame = CGRect(x: x, y: bottomY, width: bUnit, height: max(36, bottomH))
                x += bUnit + gap
            }
        }
    }

    private func layoutHandwriting(in rect: CGRect) {
        guard !handwritingButtons.isEmpty else { return }
        let gap = KeyboardMetrics.gap
        let bottomHeight = max(42, rect.height * 0.18)
        handwritingCanvas.isHidden = false
        let containerFrame = keyContainer.frame
        handwritingCanvas.frame = CGRect(x: containerFrame.minX, y: containerFrame.minY, width: containerFrame.width, height: containerFrame.height - bottomHeight - gap)
        let units: [CGFloat] = [1, 1, 2.2, 1, 1.6]
        let total = units.reduce(0, +)
        let unit = (rect.width - KeyboardMetrics.sideInset * 2 - gap * 4) / total
        var x = rect.minX + KeyboardMetrics.sideInset
        let y = rect.maxY - bottomHeight
        for (i, key) in handwritingButtons.enumerated() where i < units.count {
            let w = units[i] * unit
            key.frame = CGRect(x: x, y: y, width: w, height: bottomHeight)
            x += w + gap
        }
    }

    // MARK: - Build keyboard
    func rebuildForKind() {
        composition = ""
        englishBuffer = ""
        switch keyboardKind {
        case .pinyin26, .shuangpin, .wubi:
            language = "zh"
            page = .letters
        case .pinyin9:
            language = "zh"
            page = .t9
        case .handwriting:
            page = .handwriting
        case .stroke:
            page = .stroke
        }
        buildKeyboard()
        setNeedsLayout()
        layoutIfNeeded()
    }

    func buildKeyboard() {
        for key in allKeyButtons { key.removeFromSuperview() }
        allKeyButtons.removeAll()
        keyRows.removeAll()
        rowUnits.removeAll()
        rowInsets.removeAll()
        t9SideKeys.removeAll()
        t9LetterKeys.removeAll()
        t9RightKeys.removeAll()
        t9BottomKeys.removeAll()
        handwritingButtons.removeAll()
        handwritingCanvas.isHidden = true

        switch page {
        case .letters: buildLetterKeys()
        case .numbers: buildNumberKeys()
        case .symbols: buildSymbolKeys()
        case .t9: buildT9Keys()
        case .handwriting: buildHandwritingKeys()
        case .stroke: buildStrokeKeys()
        }
        if composition.isEmpty && candidates.isEmpty {
            candidates = idleCandidates(after: lastCommitted)
        }
        reloadCandidateBar()
    }

    private func makeKey(_ title: String, subtitle: String? = nil, units: CGFloat = 1, function: Bool = false, font: CGFloat = 21, action: (() -> Void)?) -> KBKeyButton {
        let key = KBKeyButton(type: .custom)
        key.specID = UUID().uuidString
        key.units = units
        key.useFunctionStyle = function
        key.normalColor = function ? theme.keyFunction : theme.key
        key.pressedColor = function ? theme.keyFunctionPressed : theme.keyPressed
        key.backgroundColor = key.normalColor
        key.setTitleColor(theme.text, for: .normal)
        key.titleLabel?.font = .systemFont(ofSize: font, weight: .regular)
        key.layer.cornerRadius = KeyboardMetrics.corner
        key.layer.cornerCurve = .continuous
        key.clipsToBounds = false
        key.setTitle(title, for: .normal)
        key.accessibilityLabel = subtitle.map { "\(title) \($0)" } ?? title
        if let subtitle {
            let label = UILabel()
            label.text = subtitle
            label.font = .systemFont(ofSize: max(8, font * 0.40), weight: .medium)
            label.textColor = theme.secondaryText
            label.tag = 991
            label.isUserInteractionEnabled = false
            key.addSubview(label)
        }
        if title == "⌫" {
            key.addTarget(self, action: #selector(backspaceTouchDown), for: .touchDown)
            key.addTarget(self, action: #selector(backspaceTouchUp), for: [.touchUpInside, .touchUpOutside, .touchCancel, .touchDragExit])
        } else {
            key.addAction(UIAction { [weak self] _ in
                self?.keyTapped()
                action?()
            }, for: .touchUpInside)
        }
        keyContainer.addSubview(key)
        allKeyButtons.append(key)
        return key
    }

    private func attachSubtitleLayout() {
        for key in allKeyButtons {
            if let label = key.viewWithTag(991) as? UILabel {
                let height = key.bounds.height
                label.frame = CGRect(x: 2, y: height * 0.46, width: key.bounds.width - 4, height: height * 0.42)
                label.textAlignment = .center
            }
        }
    }

    private func addRow(_ specs: [(String, String?, CGFloat, Bool, CGFloat, () -> Void)], inset: CGFloat = 0) {
        var row: [KBKeyButton] = []
        var units: [CGFloat] = []
        for spec in specs {
            let key = makeKey(spec.0, subtitle: spec.1, units: spec.2, function: spec.3, font: spec.4, action: spec.5)
            row.append(key)
            units.append(spec.2)
        }
        keyRows.append(row)
        rowUnits.append(units)
        rowInsets.append(inset)
    }

    private func buildLetterKeys() {
        let lettersRow1 = Array("qwertyuiop")
        let lettersRow2 = Array("asdfghjkl")
        let lettersRow3 = Array("zxcvbnm")
        let topMap: [Character: String] = ["q": "1", "w": "2", "e": "3", "r": "4", "t": "5", "y": "6", "u": "7", "i": "8", "o": "9", "p": "0"]
        let midMap: [Character: String] = ["a": "-", "s": "/", "d": ":", "f": ";", "g": "(", "h": ")", "j": "¥", "k": "&", "l": "@"]
        let bottomMap: [Character: String] = ["z": "@", "x": ".", "c": "#", "v": "、", "b": "?", "n": "!", "m": "，"]

        var row1: [(String, String?, CGFloat, Bool, CGFloat, () -> Void)] = []
        for ch in lettersRow1 {
            row1.append((displayLetter(ch), topMap[ch], 1, false, 21, { [weak self] in self?.typeLetter(ch) }))
        }
        addRow(row1)
        var row2: [(String, String?, CGFloat, Bool, CGFloat, () -> Void)] = []
        for ch in lettersRow2 {
            row2.append((displayLetter(ch), midMap[ch], 1, false, 21, { [weak self] in self?.typeLetter(ch) }))
        }
        addRow(row2, inset: 0.5)
        var row3: [(String, String?, CGFloat, Bool, CGFloat, () -> Void)] = []
        row3.append((shiftTitle(), nil, 1.4, true, 20, { [weak self] in self?.toggleShift() }))
        for ch in lettersRow3 {
            row3.append((displayLetter(ch), bottomMap[ch], 1, false, 21, { [weak self] in self?.typeLetter(ch) }))
        }
        row3.append(("⌫", nil, 1.4, true, 20, { [weak self] in self?.handleBackspace() }))
        addRow(row3)
        shiftKey = keyRows.last?.first
        var row4: [(String, String?, CGFloat, Bool, CGFloat, () -> Void)] = []
        let numberSymbolSetting = SharedStore.defaults.object(forKey: "layout_number_symbol_combined") as? Bool ?? true
        let commaPeriodSetting = SharedStore.defaults.object(forKey: "layout_comma_period_separate") as? Bool ?? false
        let cnPosition = SharedStore.defaults.string(forKey: "layout_cnen_position") ?? "left"
        var fixedUnits: CGFloat = 1.2 + 0.65 + 1.05 + 1.35
        row4.append(("123", nil, 1.2, true, 17, { [weak self] in self?.showNumbers() }))
        if !numberSymbolSetting {
            fixedUnits += 0.9
            row4.append(("符号", nil, 0.9, true, 14, { [weak self] in self?.showSymbols() }))
        }
        row4.append((",", nil, 0.65, true, 20, { [weak self] in self?.insertDirect("，") }))
        if commaPeriodSetting {
            fixedUnits += 0.65
            row4.append(("。", nil, 0.65, true, 20, { [weak self] in self?.insertDirect("。") }))
        }
        let cnTitle = language == "zh" ? "中/英" : "英/中"
        if cnPosition == "left" {
            row4.append((cnTitle, nil, 1.05, true, 13, { [weak self] in self?.toggleLanguage() }))
        }
        let spaceUnits = max(2.0, 10 - fixedUnits)
        row4.append(((language == "zh" ? "空格" : "space"), nil, spaceUnits, false, 15, { [weak self] in self?.spaceTapped() }))
        if cnPosition != "left" {
            row4.append((cnTitle, nil, 1.05, true, 13, { [weak self] in self?.toggleLanguage() }))
        }
        row4.append((returnKeyTitle, nil, 1.35, true, 15, { [weak self] in self?.commitAndReturn() }))
        addRow(row4)
        styleSpecialKeys()
        configureLetterGestures(topMap: topMap, midMap: midMap, bottomMap: bottomMap)
    }

    private func configureLetterGestures(topMap: [Character: String], midMap: [Character: String], bottomMap: [Character: String]) {
        for row in keyRows {
            for key in row {
                guard let title = key.title(for: .normal), title.count == 1,
                      let letter = title.lowercased().first, "abcdefghijklmnopqrstuvwxyz".contains(letter) else { continue }
                let alternate = topMap[letter] ?? midMap[letter] ?? bottomMap[letter] ?? ""
                objc_setAssociatedObject(key, &Self.letterAssociationKey, String(letter), .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
                objc_setAssociatedObject(key, &Self.alternateAssociationKey, alternate, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
                let long = UILongPressGestureRecognizer(target: self, action: #selector(letterLongPress(_:)))
                long.minimumPressDuration = 0.35
                key.addGestureRecognizer(long)
                let swipe = UISwipeGestureRecognizer(target: self, action: #selector(letterSwipeUp(_:)))
                swipe.direction = .up
                swipe.cancelsTouchesInView = true
                key.addGestureRecognizer(swipe)
            }
        }
    }

    @objc private func letterLongPress(_ gesture: UILongPressGestureRecognizer) {
        guard gesture.state == .began, SettingsReader.keyBubble,
              let key = gesture.view as? KBKeyButton,
              let letter = objc_getAssociatedObject(key, &Self.letterAssociationKey) as? String else { return }
        showAlternateBubble(for: key, letter: letter)
    }

    @objc private func letterSwipeUp(_ gesture: UISwipeGestureRecognizer) {
        guard SettingsReader.defaults.object(forKey: "layout_swipe_number_symbols") as? Bool ?? true,
              let key = gesture.view as? KBKeyButton,
              let alternate = objc_getAssociatedObject(key, &Self.alternateAssociationKey) as? String,
              !alternate.isEmpty else { return }
        insertDirect(alternate)
        showToast("上滑输入 \(alternate)")
    }

    private func showAlternateBubble(for key: KBKeyButton, letter: String) {
        dismissAlternateBubble()
        playFeedback()
        let uppercase = letter.uppercased()
        let alternate = objc_getAssociatedObject(key, &Self.alternateAssociationKey) as? String ?? ""
        let bubble = UIView()
        bubble.backgroundColor = UIColor.black.withAlphaComponent(0.86)
        bubble.layer.cornerRadius = 10
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 4
        stack.translatesAutoresizingMaskIntoConstraints = false
        bubble.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: bubble.leadingAnchor, constant: 6),
            stack.trailingAnchor.constraint(equalTo: bubble.trailingAnchor, constant: -6),
            stack.topAnchor.constraint(equalTo: bubble.topAnchor, constant: 4),
            stack.bottomAnchor.constraint(equalTo: bubble.bottomAnchor, constant: -4)
        ])
        let options = [uppercase, letter, alternate].filter { !$0.isEmpty }
        for option in options {
            let button = UIButton(type: .system)
            button.setTitle(option, for: .normal)
            button.setTitleColor(.white, for: .normal)
            button.titleLabel?.font = .systemFont(ofSize: 20, weight: .medium)
            button.widthAnchor.constraint(greaterThanOrEqualToConstant: 34).isActive = true
            button.heightAnchor.constraint(equalToConstant: 38).isActive = true
            button.addAction(UIAction { [weak self] _ in
                self?.insertDirect(option)
                self?.dismissAlternateBubble()
            }, for: .touchUpInside)
            stack.addArrangedSubview(button)
        }
        let keyFrame = key.convert(key.bounds, to: self)
        let bubbleWidth = CGFloat(options.count) * 42 + 12
        bubble.frame = CGRect(x: min(max(4, keyFrame.midX - bubbleWidth / 2), bounds.width - bubbleWidth - 4),
                              y: max(KeyboardMetrics.toolbarHeight + 2, keyFrame.minY - 52),
                              width: bubbleWidth, height: 46)
        addSubview(bubble)
        alternatePopup = bubble
        bubble.alpha = 0
        UIView.animate(withDuration: 0.12) { bubble.alpha = 1 }
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { [weak self, weak bubble] in
            if let bubble, self?.alternatePopup === bubble { self?.dismissAlternateBubble() }
        }
    }

    func dismissAlternateBubble() {
        alternatePopup?.removeFromSuperview()
        alternatePopup = nil
    }

    private func displayLetter(_ ch: Character) -> String {
        (shiftState > 0 || language == "en") ? String(ch).uppercased() : String(ch).uppercased()
    }

    private func shiftTitle() -> String {
        switch shiftState {
        case 2: return "⇪"
        case 1: return "⇧"
        default: return "⇧"
        }
    }

    private func styleSpecialKeys() {
        // Accent-style keys for the bottom action row.
        guard let bottomRow = keyRows.last else { return }
        if let action = bottomRow.last {
            action.backgroundColor = theme.accent
            action.normalColor = theme.accent
            action.pressedColor = UIColor(red: 0.19, green: 0.32, blue: 0.95, alpha: 1)
            action.setTitleColor(.white, for: .normal)
        }
    }

    private func buildT9Keys() {
        let symbols = SettingsReader.sideSymbols
        for symbol in symbols.prefix(4) {
            let key = makeKey(symbol, subtitle: nil, units: 0.9, function: true, font: 20, action: { [weak self] in self?.insertDirect(symbol) })
            t9SideKeys.append(key)
        }
        let digitSpecs: [(String, String, String)] = [
            ("1", "@#", "1"), ("2", "ABC", "2"), ("3", "DEF", "3"),
            ("4", "GHI", "4"), ("5", "JKL", "5"), ("6", "MNO", "6"),
            ("7", "PQRS", "7"), ("8", "TUV", "8"), ("9", "WXYZ", "9")
        ]
        for spec in digitSpecs {
            let key = makeKey(spec.0, subtitle: spec.1, units: 1, function: false, font: 22, action: { [weak self] in
                guard let self else { return }
                if spec.0 == "1" { self.showSymbolsPanel() }
                else { self.typeT9(spec.2) }
            })
            let long = UILongPressGestureRecognizer(target: self, action: #selector(t9LongPress(_:)))
            long.minimumPressDuration = 0.40
            key.addGestureRecognizer(long)
            key.accessibilityHint = "长按输入数字 \(spec.0)"
            t9LetterKeys.append(key)
        }
        let back = makeKey("⌫", subtitle: nil, units: 1.15, function: true, font: 20, action: { [weak self] in self?.handleBackspace() })
        let clear = makeKey("重输", subtitle: nil, units: 1.15, function: true, font: 15, action: { [weak self] in
            self?.composition = ""
            self?.reloadCandidatesForComposition()
        })
        let action = makeKey(returnKeyTitle, subtitle: nil, units: 1.15, function: false, font: 15, action: { [weak self] in self?.commitAndReturn() })
        action.backgroundColor = theme.accent
        action.normalColor = theme.accent
        action.pressedColor = UIColor(red: 0.19, green: 0.32, blue: 0.95, alpha: 1)
        action.setTitleColor(.white, for: .normal)
        t9RightKeys = [back, clear, action]

        t9BottomKeys = [
            makeKey("符号", subtitle: nil, units: 1, function: true, font: 15, action: { [weak self] in self?.showSymbols() }),
            makeKey("123", subtitle: nil, units: 1, function: true, font: 15, action: { [weak self] in self?.showNumbers() }),
            makeKey(language == "zh" ? "空格" : "space", subtitle: nil, units: 2.7, function: false, font: 14, action: { [weak self] in self?.spaceTapped() }),
            makeKey(language == "zh" ? "中/英" : "英/中", subtitle: nil, units: 1.2, function: true, font: 14, action: { [weak self] in self?.toggleLanguage() })
        ]
        // Bottom action also available as a dedicated send button on T9.
        if t9BottomKeys.count == 4 {
            t9BottomKeys[2].accessibilityLabel = "空格"
        }
    }

    private func buildNumberKeys() {
        addRow(Array("1234567890").map { ch in
            (String(ch), nil, 1, false, 23, { [weak self] in self?.insertDirect(String(ch)) })
        })
        let symbols: [(String, String)] = [("-", "-"), ("/", "/"), (":", ":"), (";", ";"), ("(", "("), (")", ")"), ("¥", "¥"), ("&", "&"), ("@", "@"), ("\"", "\"")]
        addRow(symbols.map { s in (s.0, nil, 1, true, 18, { [weak self] in self?.insertDirect(s.1) }) })
        let more: [(String, String)] = [("#+=", ""), (".", "."), (",", ","), ("?", "?"), ("!", "!"), ("'", "'"), ("…", "…"), ("·", "·"), ("~", "~"), ("`", "`")]
        var row: [(String, String?, CGFloat, Bool, CGFloat, () -> Void)] = []
        for s in more {
            if s.0 == "#+=" {
                row.append((s.0, nil, 1.1, true, 15, { [weak self] in self?.showSymbols() }))
            } else {
                row.append((s.0, nil, 1, true, 18, { [weak self] in self?.insertDirect(s.1) }))
            }
        }
        row.append(("⌫", nil, 1.2, true, 20, { [weak self] in self?.handleBackspace() }))
        addRow(row)
        addRow([
            ("符号", nil, 1, true, 15, { [weak self] in self?.showSymbols() }),
            ("ABC", nil, 1, true, 15, { [weak self] in self?.showLetters() }),
            ((language == "zh" ? "空格" : "space"), nil, 3.6, false, 14, { [weak self] in self?.spaceTapped() }),
            (language == "zh" ? "中/英" : "英/中", nil, 1.2, true, 14, { [weak self] in self?.toggleLanguage() }),
            (returnKeyTitle, nil, 1.5, false, 15, { [weak self] in self?.commitAndReturn() })
        ])
        styleSpecialKeys()
    }

    private func buildSymbolKeys() {
        addRow(["[", "]", "{", "}", "#", "%", "^", "*", "+", "="].map { s in
            (s, nil, 1, true, 19, { [weak self] in self?.insertDirect(s) })
        })
        addRow(["_", "\\", "|", "~", "<", ">", "€", "£", "¥", "•"].map { s in
            (s, nil, 1, true, 19, { [weak self] in self?.insertDirect(s) })
        })
        var row: [(String, String?, CGFloat, Bool, CGFloat, () -> Void)] = []
        row.append(("123", nil, 1.1, true, 15, { [weak self] in self?.showNumbers() }))
        row.append((".", nil, 1, true, 19, { [weak self] in self?.insertDirect("。") }))
        row.append((",", nil, 1, true, 19, { [weak self] in self?.insertDirect("，") }))
        row.append(("?", nil, 1, true, 19, { [weak self] in self?.insertDirect("？") }))
        row.append(("!", nil, 1, true, 19, { [weak self] in self?.insertDirect("！") }))
        row.append(("'", nil, 1, true, 19, { [weak self] in self?.insertDirect("'") }))
        row.append(("⌫", nil, 1.2, true, 20, { [weak self] in self?.handleBackspace() }))
        addRow(row)
        addRow([
            ("ABC", nil, 1, true, 15, { [weak self] in self?.showLetters() }),
            (",", nil, 0.8, true, 20, { [weak self] in self?.insertDirect("，") }),
            ((language == "zh" ? "空格" : "space"), nil, 3.4, false, 14, { [weak self] in self?.spaceTapped() }),
            (language == "zh" ? "中/英" : "英/中", nil, 1.2, true, 14, { [weak self] in self?.toggleLanguage() }),
            (returnKeyTitle, nil, 1.5, false, 15, { [weak self] in self?.commitAndReturn() })
        ])
        styleSpecialKeys()
    }

    private func buildHandwritingKeys() {
        handwritingCanvas.isHidden = false
        let buttons: [(String, CGFloat, CGFloat, () -> Void)] = [
            ("清空", 1, 16, { [weak self] in self?.handwritingCanvas.clear() }),
            ("撤销", 1, 16, { [weak self] in self?.handwritingCanvas.undo() }),
            ((language == "zh" ? "空格" : "space"), 2.2, 14, { [weak self] in self?.spaceTapped() }),
            (returnKeyTitle, 1, 16, { [weak self] in self?.commitAndReturn() }),
            ("找字", 1.6, 16, { [weak self] in self?.openHandwritingLookup() })
        ]
        for item in buttons {
            let key = makeKey(item.0, subtitle: nil, units: item.1, function: item.0 != "space", font: item.2, action: item.3)
            handwritingButtons.append(key)
        }
        handwritingCanvas.onRecognized = { [weak self] results in
            guard let self else { return }
            if results.isEmpty {
                self.showToast("换个写法试试")
            } else {
                self.candidates = results.enumerated().map { index, text in
                    Candidate(text: text, pinyin: "", detail: "手写识别", score: Double(100 - index), source: "手写")
                }
                self.candidatePage = 0
                self.reloadCandidateBar()
            }
        }
    }

    private func buildStrokeKeys() {
        let strokes: [(String, String)] = [("横", "1"), ("竖", "2"), ("撇", "3"), ("捺", "4"), ("折", "5"), ("通配", "6")]
        var first: [(String, String?, CGFloat, Bool, CGFloat, () -> Void)] = []
        for (title, code) in strokes {
            first.append((title, nil, 1, false, 22, { [weak self] in self?.typeStroke(code) }))
        }
        first.append(("⌫", nil, 1, true, 20, { [weak self] in self?.handleBackspace() }))
        addRow(first)
        addRow([
            ("清空", nil, 1, true, 15, { [weak self] in self?.composition = ""; self?.reloadCandidatesForComposition() }),
            ("符号", nil, 1, true, 15, { [weak self] in self?.showSymbols() }),
            ((language == "zh" ? "空格" : "space"), nil, 2.8, false, 14, { [weak self] in self?.spaceTapped() })
        ])
        addRow([
            ("ABC", nil, 1, true, 15, { [weak self] in self?.showLetters() }),
            ("123", nil, 1, true, 15, { [weak self] in self?.showNumbers() }),
            (returnKeyTitle, nil, 1.6, false, 15, { [weak self] in self?.commitAndReturn() })
        ])
        styleSpecialKeys()
    }

    // MARK: - Key actions
    private func keyTapped() {
        playFeedback()
        dismissAlternateBubble()
    }

    func playFeedback() {
        if SettingsReader.keySound {
            AudioServicesPlaySystemSound(1104)
        }
        if SettingsReader.keyVibrate {
            let level = SharedStore.defaults.object(forKey: "key_vibrate_level") as? Double ?? 0.6
            let generator = UIImpactFeedbackGenerator(style: level > 0.7 ? .medium : .light)
            generator.impactOccurred()
        }
    }

    private func typeLetter(_ ch: Character) {
        let letter = String(ch)
        if language == "en" {
            englishBuffer += letter
            actionDelegate?.keyboardInsert(letter)
            candidates = PinyinEngine.shared.candidates(for: englishBuffer, script: .english, limit: 27)
            candidatePage = 0
            reloadCandidateBar()
            if shiftState == 1 { shiftState = 0; updateShiftAppearance() }
            return
        }
        composition += letter
        reloadCandidatesForComposition()
        if shiftState == 1 { shiftState = 0; updateShiftAppearance() }
    }

    private func typeT9(_ digit: String) {
        composition += digit
        reloadCandidatesForComposition()
    }

    private func typeStroke(_ code: String) {
        composition += code
        let table: [String: [String]] = [
            "1": ["一"], "2": ["丨"], "3": ["丿"], "4": ["丶"], "5": ["乙"],
            "11": ["二"], "12": ["十"], "13": ["厂"], "14": ["广"], "15": ["丁"],
            "111": ["三"], "112": ["干"], "113": ["于"], "121": ["土"], "122": ["王"],
            "123": ["才"], "124": ["寸"], "131": ["大"], "132": ["丈"], "141": ["六"],
            "211": ["上"], "212": ["止"], "221": ["卜"], "231": ["小"], "251": ["口"],
            "311": ["人"], "312": ["八"], "321": ["了"], "331": ["子"], "341": ["女"],
            "411": ["心"], "421": ["火"], "431": ["文"], "441": ["方"], "511": ["马"]
        ]
        let results = table[composition] ?? table.filter { $0.key.hasPrefix(composition) }.values.flatMap { $0 }
        candidates = Array(Set(results)).enumerated().map { i, text in
            Candidate(text: text, pinyin: "", detail: "笔画 \(composition)", score: Double(100 - i), source: "笔画")
        }
        candidatePage = 0
        reloadCandidateBar()
        if candidates.isEmpty && composition.count > 1 {
            // wildcard fallback: let the user keep typing
        }
    }

    func insertDirect(_ text: String) {
        if !composition.isEmpty { composition = ""; candidates = [] }
        actionDelegate?.keyboardInsert(text)
        lastCommitted = text
        reloadCandidateBar()
    }

    private func handleBackspace() {
        if !composition.isEmpty {
            composition.removeLast()
            reloadCandidatesForComposition()
            return
        }
        if !englishBuffer.isEmpty {
            englishBuffer.removeLast()
        }
        actionDelegate?.keyboardDelete()
        lastCommitted = ""
        reloadCandidateBar()
    }

    private func spaceTapped() {
        if !composition.isEmpty {
            commitFirstCandidate()
            return
        }
        let now = Date()
        if language == "en" && SettingsReader.quickDoubleSpacePeriod && now.timeIntervalSince(lastSpaceTap) < 0.38 {
            actionDelegate?.keyboardDelete()
            actionDelegate?.keyboardInsert(". ")
            lastSpaceTap = now
            return
        }
        lastSpaceTap = now
        if !englishBuffer.isEmpty { englishBuffer = "" }
        actionDelegate?.keyboardInsert(" ")
        lastCommitted = ""
        reloadCandidateBar()
    }

    private func toggleLanguage() {
        composition = ""
        englishBuffer = ""
        language = language == "zh" ? "en" : "zh"
        candidates = []
        if language == "en" {
            page = .letters
        } else if keyboardKind == .pinyin9 {
            page = .t9
        } else if page != .letters && page != .handwriting && page != .stroke && page != .t9 {
            page = .letters
        }
        buildKeyboard()
        setNeedsLayout()
        showToast(language == "zh" ? "中文输入" : "English")
    }

    private func toggleShift() {
        let now = Date()
        if now.timeIntervalSince(lastShiftTap) < 0.32 {
            shiftState = shiftState == 2 ? 0 : 2
        } else {
            shiftState = shiftState == 0 ? 1 : (shiftState == 1 ? 0 : 0)
        }
        lastShiftTap = now
        updateShiftAppearance()
        rebuildCaseTitles()
    }

    private func updateShiftAppearance() {
        guard let shift = shiftKey else { return }
        shift.backgroundColor = shiftState > 0 ? theme.accent : theme.keyFunction
        shift.normalColor = shiftState > 0 ? theme.accent : theme.keyFunction
        shift.setTitleColor(shiftState > 0 ? .white : theme.text, for: .normal)
        shift.setTitle(shiftTitle(), for: .normal)
    }

    private func rebuildCaseTitles() {
        guard page == .letters else { return }
        for row in keyRows {
            for key in row {
                if let title = key.title(for: .normal), title.count == 1, let ch = title.lowercased().first, "abcdefghijklmnopqrstuvwxyz".contains(ch) {
                    key.setTitle(displayLetter(ch), for: .normal)
                }
            }
        }
        updateShiftAppearance()
    }

    private func commitFirstCandidate() {
        if let first = candidates.first {
            commitCandidate(first)
        }
    }

    func commitCandidate(_ candidate: Candidate) {
        let insertion = candidate.insertText ?? candidate.text
        if language == "en" && !englishBuffer.isEmpty {
            for _ in englishBuffer { actionDelegate?.keyboardDelete() }
            actionDelegate?.keyboardInsert(insertion + " ")
            englishBuffer = ""
        } else {
            actionDelegate?.keyboardInsert(insertion)
        }
        PinyinEngine.shared.learn(candidate.text)
        lastCommitted = candidate.text
        composition = ""
        englishBuffer = ""
        candidates = idleCandidates(after: candidate.text)
        candidatePage = 0
        reloadCandidateBar()
    }

    private func idleCandidates(after context: String) -> [Candidate] {
        var list = PinyinEngine.shared.associations(after: context, limit: 27)
        if SettingsReader.clipboardCandidate && SettingsReader.auxiliaryInput {
            let items = SharedStore.data([ClipboardItem].self, forKey: "clipboard_items", fallback: [])
            if let first = items.first, !first.text.isEmpty {
                let oneLine = first.text.replacingOccurrences(of: "\n", with: " ")
                let preview = oneLine.count > 6 ? String(oneLine.prefix(6)) + "…" : oneLine
                list.insert(Candidate(text: preview, pinyin: "", detail: "剪切板 · " + first.displayTime, score: 2000, source: "剪切板", insertText: first.text), at: 0)
            }
        }
        return list
    }

    private func commitAndReturn() {
        if !composition.isEmpty {
            if let first = candidates.first {
                commitCandidate(first)
            } else {
                composition = ""
            }
        }
        englishBuffer = ""
        if SettingsReader.enterSend {
            actionDelegate?.keyboardInsert("\n")
        } else {
            actionDelegate?.keyboardReturn()
        }
        candidates = []
        reloadCandidateBar()
    }

    func reloadCandidatesForComposition() {
        guard !composition.isEmpty else {
            candidates = idleCandidates(after: lastCommitted)
            candidatePage = 0
            reloadCandidateBar()
            return
        }
        let script: InputScript
        switch page {
        case .t9: script = .t9
        case .stroke: return
        case .letters:
            switch keyboardKind {
            case .shuangpin: script = .shuangpin
            case .wubi: script = .wubi
            default: script = .pinyin
            }
        default: script = .pinyin
        }
        candidates = PinyinEngine.shared.candidates(for: composition, script: script, fuzzy: PinyinEngine.currentFuzzyOptions(), limit: 27)
        candidatePage = 0
        reloadCandidateBar()
    }

    func reloadCandidateBar() {
        for view in candidateStack.arrangedSubviews {
            candidateStack.removeArrangedSubview(view)
            view.removeFromSuperview()
        }
        let fontSize = CGFloat(SettingsReader.candidateFontSize)
        if !composition.isEmpty && SettingsReader.defaults.string(forKey: "pinyin_location") != "input" {
            let label = UILabel()
            var shown = composition
            if page == .t9 {
                shown = composition
            } else if keyboardKind == .wubi {
                shown = "五笔 " + composition
            } else {
                shown = composition
            }
            label.text = shown
            label.font = .systemFont(ofSize: 13, weight: .regular)
            label.textColor = theme.secondaryText
            label.setContentHuggingPriority(.required, for: .horizontal)
            candidateStack.addArrangedSubview(label)
            let divider = UIView()
            divider.backgroundColor = theme.divider
            divider.widthAnchor.constraint(equalToConstant: 1).isActive = true
            divider.heightAnchor.constraint(equalToConstant: 20).isActive = true
            candidateStack.addArrangedSubview(divider)
        }
        let start = candidatePage * 9
        let slice = Array(candidates.dropFirst(start).prefix(9))
        if slice.isEmpty && composition.isEmpty {
            let hint = UILabel()
            hint.text = language == "zh" ? "轻点空格上屏 · 长按空格说话" : "Type in English"
            hint.font = .systemFont(ofSize: 13)
            hint.textColor = theme.secondaryText
            candidateStack.addArrangedSubview(hint)
        } else if slice.isEmpty {
            let hint = UILabel()
            hint.text = "无候选 · 换个拼音试试"
            hint.font = .systemFont(ofSize: 13)
            hint.textColor = theme.secondaryText
            candidateStack.addArrangedSubview(hint)
        }
        for candidate in slice {
            let button = UIButton(type: .system)
            button.contentEdgeInsets = UIEdgeInsets(top: 0, left: 8, bottom: 0, right: 8)
            button.setTitle(candidate.text, for: .normal)
            button.setTitleColor(theme.text, for: .normal)
            button.titleLabel?.font = .systemFont(ofSize: fontSize)
            button.heightAnchor.constraint(equalToConstant: KeyboardMetrics.candidateHeight - 8).isActive = true
            button.addAction(UIAction { [weak self] _ in self?.commitCandidate(candidate) }, for: .touchUpInside)
            let long = UILongPressGestureRecognizer(target: self, action: #selector(candidateLongPress(_:)))
            button.addGestureRecognizer(long)
            objc_setAssociatedObject(button, &Self.candidateKey, candidate, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            candidateStack.addArrangedSubview(button)
        }
        prevButton.isHidden = candidatePage == 0 || candidates.count <= 9
        nextButton.isHidden = (candidatePage + 1) * 9 >= candidates.count
        setNeedsLayout()
    }

    @objc private func candidateLongPress(_ gesture: UILongPressGestureRecognizer) {
        guard gesture.state == .began, let button = gesture.view as? UIButton,
              let candidate = objc_getAssociatedObject(button, &Self.candidateKey) as? Candidate else { return }
        let alert = UIAlertController(title: candidate.text, message: candidate.detail, preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "删除候选词", style: .destructive) { [weak self] _ in
            PinyinEngine.shared.block(candidate.text)
            self?.reloadCandidatesForComposition()
            self?.showToast("已从候选移除")
        })
        alert.addAction(UIAlertAction(title: "复制", style: .default) { _ in
            UIPasteboard.general.string = candidate.text
        })
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        if let pop = alert.popoverPresentationController {
            pop.sourceView = button
            pop.sourceRect = button.bounds
        }
        topViewController?.present(alert, animated: true)
    }

    @objc private func previousPage() {
        candidatePage = max(0, candidatePage - 1)
        reloadCandidateBar()
    }

    @objc private func nextPage() {
        if (candidatePage + 1) * 9 < candidates.count {
            candidatePage += 1
            reloadCandidateBar()
        }
    }

    // MARK: - Mode switches
    func showNumbers() {
        page = .numbers
        composition = ""
        buildKeyboard()
        setNeedsLayout()
    }

    func showSymbols() {
        page = .symbols
        composition = ""
        buildKeyboard()
        setNeedsLayout()
    }

    func showLetters() {
        page = keyboardKind == .pinyin9 ? .t9 : .letters
        composition = ""
        buildKeyboard()
        setNeedsLayout()
    }

    // MARK: - Toolbar actions
    @objc func openVoice() { showVoiceOverlay() }
    @objc func openClipboard() { showClipboardPanel() }
    @objc func openEmoji() { showEmojiPanel() }
    @objc func openPhrases() { showPhrasesPanel() }
    @objc func nextInputMode() { actionDelegate?.keyboardNextInputMode() }
    @objc func toggleOneHand() {
        let current = SettingsReader.oneHand
        let next = current == "off" ? "left" : (current == "left" ? "right" : "off")
        SharedStore.defaults.set(next, forKey: "one_hand")
        SharedStore.defaults.synchronize()
        setNeedsLayout()
        layoutIfNeeded()
        showToast(next == "off" ? "单手模式已关闭" : "单手模式：\(next == "left" ? "左手" : "右手")")
    }
    @objc func dismissKeyboard() { actionDelegate?.keyboardDismiss() }
    @objc func openHeightPanel() { showHeightPanel() }
    @objc func openToolbox() { showToolbox() }

    @objc private func openTranslateToolbar() { showTranslatePanel() }
    @objc private func openAIToolbar() { showAIPanel() }
    @objc private func openOrganizeToolbar() { showOrganizePanel() }

    @objc private func t9LongPress(_ gesture: UILongPressGestureRecognizer) {
        guard gesture.state == .began, let key = gesture.view as? KBKeyButton,
              let title = key.title(for: .normal), title.count == 1, "123456789".contains(title) else { return }
        playFeedback()
        insertDirect(title)
    }

    @objc private func backspaceTouchDown() {
        playFeedback()
        handleBackspace()
        backspaceTimer?.invalidate()
        let repeatInterval = SettingsReader.keyResponse == "quality" ? 0.13 : 0.09
        backspaceTimer = Timer.scheduledTimer(withTimeInterval: repeatInterval, repeats: true) { [weak self] _ in
            self?.handleBackspace()
            if SettingsReader.keyVibrate {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            }
        }
        if let timer = backspaceTimer {
            RunLoop.main.add(timer, forMode: .common)
        }
    }

    @objc private func backspaceTouchUp() {
        backspaceTimer?.invalidate()
        backspaceTimer = nil
    }

    // MARK: - Automated verification hook
    /// Used by the extension's debug verification path (and screenshots) to drive the
    /// exact same composition -> candidate -> textDocumentProxy pipeline without taps.
    func automationCompose(_ input: String) {
        language = "zh"
        page = .letters
        keyboardKind = keyboardKind == .pinyin9 ? .pinyin26 : keyboardKind
        buildKeyboard()
        setNeedsLayout()
        layoutIfNeeded()
        composition = input
        reloadCandidatesForComposition()
    }

    func automationCommitFirst() {
        guard let first = candidates.first else { return }
        commitCandidate(first)
    }

    func automationOpenPanel(_ id: String) {
        switch id {
        case "emoji": showEmojiPanel()
        case "clipboard": showClipboardPanel()
        case "phrases": showPhrasesPanel()
        case "toolbox": showToolbox()
        case "keyboardPicker": showKeyboardPicker()
        case "height": showHeightPanel()
        case "translate": showTranslatePanel()
        case "ai": showAIPanel()
        case "organize": showOrganizePanel()
        case "symbols": showSymbolsPanel()
        case "voice": showVoiceOverlay()
        default: break
        }
    }

    // MARK: - Toasts
    func showToast(_ message: String) {
        toastLabel?.removeFromSuperview()
        let label = UILabel()
        label.text = message
        label.font = .systemFont(ofSize: 13, weight: .medium)
        label.textColor = .white
        label.backgroundColor = UIColor.black.withAlphaComponent(0.78)
        label.textAlignment = .center
        label.layer.cornerRadius = 14
        label.clipsToBounds = true
        label.alpha = 0
        let width = min(bounds.width - 40, max(CGFloat(150), CGFloat(message.count) * 16 + 32))
        label.frame = CGRect(x: (bounds.width - width) / 2, y: KeyboardMetrics.toolbarHeight + KeyboardMetrics.candidateHeight + 8, width: width, height: 30)
        addSubview(label)
        toastLabel = label
        UIView.animate(withDuration: 0.18, animations: { label.alpha = 1 }) { _ in
            UIView.animate(withDuration: 0.25, delay: 1.4, options: [], animations: { label.alpha = 0 }) { _ in
                label.removeFromSuperview()
            }
        }
    }

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        // Alternate popups sit above keys and must receive touches.
        if let popup = alternatePopup, popup.frame.contains(point) {
            return super.hitTest(point, with: event)
        }
        return super.hitTest(point, with: event)
    }

    // MARK: - Helpers
    var topViewController: UIViewController? {
        var responder: UIResponder? = self
        while let current = responder {
            if let controller = current as? UIViewController { return controller }
            responder = current.next
        }
        return window?.rootViewController
    }

    static var candidateKey: UInt8 = 0
    static var letterAssociationKey: UInt8 = 0
    static var alternateAssociationKey: UInt8 = 0
}
