import SwiftUI
import AudioToolbox

// MARK: - Keyboard types

struct KeyboardTypesView: View {
    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var router: Router
    private let columns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]

    var body: some View {
        PageScaffold(title: "键盘类型", subtitle: "选择主键盘，立即同步到键盘扩展") {
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(KeyboardKind.allCases) { kind in
                    card(kind)
                }
            }
            Card {
                Text("当前选择")
                    .font(.system(size: 12))
                    .foregroundColor(AppTheme.textSecondary)
                HStack {
                    Image(systemName: settings.keyboardType.symbol)
                        .foregroundColor(AppTheme.primary)
                    Text(settings.keyboardType.title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(AppTheme.text)
                    Spacer()
                    Text("立即生效")
                        .font(.system(size: 11))
                        .foregroundColor(AppTheme.primary)
                }
            }
            SecondaryButton(title: "打开键盘实验室", icon: "keyboard") {
                router.push(.keyboardDemo)
            }
            if settings.keyboardType == .shuangpin {
                SecondaryButton(title: "双拼方案设置", icon: "rectangle.split.3x1") {
                    router.push(.doublePinyin)
                }
            }
            if settings.keyboardType == .wubi {
                SecondaryButton(title: "五笔详细设置", icon: "character.book.closed") {
                    router.push(.wubi)
                }
            }
        }
    }

    private func card(_ kind: KeyboardKind) -> some View {
        let selected = settings.keyboardType == kind
        return Button {
            settings.keyboardType = kind
            settings.keyboardTypePicked = true
            showToast("已切换为\(kind.title)")
            if kind == .shuangpin { router.push(.doublePinyin) }
            if kind == .wubi { router.push(.wubi) }
        } label: {
            VStack(alignment: .leading, spacing: 9) {
                KeyboardPreview(kind: kind, selected: selected)
                    .frame(height: 110)
                HStack(spacing: 8) {
                    RadioCircle(selected: selected)
                    Text(kind.title)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(selected ? AppTheme.primary : AppTheme.text)
                    Spacer()
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
    }
}

// MARK: - Double pinyin

struct DoublePinyinView: View {
    @EnvironmentObject private var settings: AppSettings

    var body: some View {
        PageScaffold(title: "双拼设置", subtitle: "选择双拼编码方案，键盘内即时生效") {
            SettingGroup(title: "双拼方案") {
                OptionRow(title: "小鹤双拼", subtitle: "零声母与韵母键位示例：ni + hc → 你好", selected: settings.doublePinyinScheme == "xiaohe", isLast: false) {
                    settings.doublePinyinScheme = "xiaohe"
                    showToast("已选择小鹤双拼")
                }
                OptionRow(title: "自然码", subtitle: "自然码风格键位（演示级覆盖）", selected: settings.doublePinyinScheme == "natural", isLast: true) {
                    settings.doublePinyinScheme = "natural"
                    showToast("已选择自然码")
                }
            }
            SettingGroup(title: "其他") {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("9键双拼").font(.system(size: 15)).foregroundColor(AppTheme.text)
                        Text("敬请期待").font(.system(size: 12)).foregroundColor(AppTheme.textSecondary)
                    }
                    Spacer()
                    Text("暂不支持")
                        .font(.system(size: 11))
                        .foregroundColor(AppTheme.textSecondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(AppTheme.cardAlt)
                        .clipShape(Capsule())
                }
                .padding(.vertical, 12)
            }
            Card {
                Text("小鹤键位速查")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(AppTheme.text)
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 54), spacing: 6)], spacing: 6) {
                    ForEach([("iu", "Q"), ("ei", "W"), ("e", "E"), ("uan", "R"), ("ue", "T"), ("un", "Y"), ("sh/u", "U"), ("ch/i", "I"), ("o", "O"), ("ie", "P"), ("a", "A"), ("ong", "S"), ("ai", "D"), ("en", "F"), ("eng", "G"), ("ang", "H"), ("an", "J"), ("ing", "K"), ("iang", "L"), ("ou", "Z"), ("ia", "X"), ("ao", "C"), ("zh/v", "V"), ("in", "B"), ("iao", "N"), ("ian", "M")], id: \.1) { item in
                        VStack(spacing: 1) {
                            Text(item.1).font(.system(size: 12, weight: .semibold)).foregroundColor(AppTheme.primary)
                            Text(item.0).font(.system(size: 9)).foregroundColor(AppTheme.textSecondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 4)
                        .background(AppTheme.cardAlt)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                    }
                }
                Text("键盘内按两键一组输入。未识别的组合会回退为原始字母，避免吞字。")
                    .font(.system(size: 11))
                    .foregroundColor(AppTheme.textSecondary)
            }
        }
    }
}

// MARK: - Wubi

struct WubiView: View {
    @EnvironmentObject private var settings: AppSettings

    var body: some View {
        PageScaffold(title: "五笔设置", subtitle: "86 版五笔 · 演示级码表（约 250 个常用字）") {
            SettingGroup(title: "方案") {
                OptionRow(title: "86 版五笔", subtitle: "经典键位与拆字规则", selected: true, isLast: false) {
                    showToast("当前使用 86 版五笔")
                }
                OptionRow(title: "98 版五笔", subtitle: "该复刻版暂未提供，敬请期待", selected: false, isLast: true) {
                    showToast("98 版暂未提供")
                }
            }
            SettingGroup(title: "输入行为") {
                ToggleRow(title: "编码提示", subtitle: "候选栏显示五笔编码与按键提示", isOn: $settings.wubiHint, isLast: false) { on in
                    showToast(on ? "已开启编码提示" : "已关闭编码提示")
                }
                ToggleRow(title: "拼音混输", subtitle: "五笔无候选时可继续用拼音输入", isOn: $settings.wubiMixed, isLast: false) { on in
                    showToast(on ? "已开启拼音混输" : "已关闭拼音混输")
                }
                ToggleRow(title: "四码唯一上屏", subtitle: "四码仅剩一个候选时自动上屏", isOn: $settings.wubiFourUnique, isLast: false)
                ToggleRow(title: "第五码首选", subtitle: "第五码输入时选择首选候选", isOn: $settings.wubiFifthFirst, isLast: true)
            }
            Card {
                Text("覆盖说明")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(AppTheme.text)
                Text("本复刻版的手写与五笔为净室演示实现：五笔码表收录 \(WubiTable.count) 个常用字，不包含官方私有词典。输入未知编码时会回退到拼音混输（若开启）。")
                    .font(.system(size: 12))
                    .foregroundColor(AppTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            SecondaryButton(title: "在键盘实验室试五笔", icon: "keyboard") {
                settings.keyboardType = .wubi
                showToast("已切换五笔，请在键盘实验室试用")
            }
        }
    }
}

// MARK: - Layout

struct LayoutSettingsView: View {
    @EnvironmentObject private var settings: AppSettings
    @State private var showSideEditor = false

    var body: some View {
        PageScaffold(title: "布局与显示", subtitle: "所有调整即时保存，外观切换全局生效") {
            Card {
                Text("候选字大小")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(AppTheme.text)
                HStack {
                    Text("你").font(.system(size: CGFloat(settings.candidateFontSize) * 0.65))
                    Text("你好").font(.system(size: CGFloat(settings.candidateFontSize)))
                    Text("豆包输入法").font(.system(size: CGFloat(settings.candidateFontSize)))
                    Spacer()
                    Text("\(Int(settings.candidateFontSize))")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(AppTheme.primary)
                }
                .foregroundColor(AppTheme.text)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(10)
                .background(AppTheme.cardAlt)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                Slider(value: $settings.candidateFontSize, in: 16...30, step: 1)
                    .tint(AppTheme.primary)
                HStack {
                    Text("A").font(.system(size: 12)).foregroundColor(AppTheme.textSecondary)
                    Spacer()
                    Text("A").font(.system(size: 20)).foregroundColor(AppTheme.textSecondary)
                }
            }

            SettingGroup(title: "输入拼音显示") {
                OptionRow(title: "显示在候选栏", subtitle: "拼音串出现在候选文字左侧", selected: settings.pinyinLocation == "candidate", isLast: false) {
                    settings.pinyinLocation = "candidate"
                    showToast("拼音显示在候选栏")
                }
                OptionRow(title: "显示在输入框", subtitle: "隐藏候选栏拼音串（宿主输入框展示组合态）", selected: settings.pinyinLocation == "input", isLast: true) {
                    settings.pinyinLocation = "input"
                    showToast("拼音显示在输入框")
                }
            }

            SettingGroup(title: "26 键布局") {
                OptionRow(title: "数字符号键合并", subtitle: "底部显示 123 与逗号", selected: settings.numberSymbolCombined, isLast: false) {
                    settings.numberSymbolCombined = true
                    showToast("已使用合并布局")
                }
                OptionRow(title: "数字符号键分开", subtitle: "符号键与 123 键独立", selected: !settings.numberSymbolCombined, isLast: false) {
                    settings.numberSymbolCombined = false
                    showToast("已使用分开布局")
                }
                ToggleRow(title: "逗号句号键分开", subtitle: "逗号与句号显示为两个独立按键", isOn: $settings.commaPeriodSeparate, isLast: true)
            }

            SettingGroup(title: "中英切换位置") {
                OptionRow(title: "靠左", selected: settings.cnEnPosition == "left", isLast: false) {
                    settings.cnEnPosition = "left"
                    showToast("中英切换已靠左")
                }
                OptionRow(title: "靠右", selected: settings.cnEnPosition == "right", isLast: true) {
                    settings.cnEnPosition = "right"
                    showToast("中英切换已靠右")
                }
            }

            Card {
                Text("外观")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(AppTheme.text)
                HStack(spacing: 8) {
                    ChoiceChip(title: "浅色", selected: settings.themeMode == "light") {
                        settings.themeMode = "light"
                        showToast("已切换浅色")
                    }
                    ChoiceChip(title: "深色", selected: settings.themeMode == "dark") {
                        settings.themeMode = "dark"
                        showToast("已切换深色")
                    }
                    ChoiceChip(title: "跟随系统", selected: settings.themeMode == "system") {
                        settings.themeMode = "system"
                        showToast("已跟随系统")
                    }
                }
            }

            SettingGroup(title: "输入行为") {
                ToggleRow(title: "上滑数字符号", subtitle: "字母键上滑输入数字与符号", isOn: $settings.swipeNumberSymbols, isLast: false)
                ToggleRow(title: "回车发送", subtitle: "键盘回车键显示“发送”并直接提交", isOn: $settings.enterSend, isLast: true)
            }

            SettingGroup(title: "侧边栏自定义符号") {
                HStack(spacing: 6) {
                    ForEach(settings.sideSymbols, id: \.self) { symbol in
                        Text(symbol)
                            .font(.system(size: 15))
                            .frame(width: 32, height: 32)
                            .background(AppTheme.cardAlt)
                            .clipShape(RoundedRectangle(cornerRadius: 7))
                    }
                    Spacer()
                }
                .padding(.vertical, 10)
                Button {
                    showSideEditor = true
                } label: {
                    HStack {
                        Image(systemName: "slider.horizontal.3")
                        Text("编辑符号（增删、排序）")
                        Spacer()
                    }
                    .font(.system(size: 14))
                    .foregroundColor(AppTheme.primary)
                    .padding(.vertical, 10)
                    .contentShape(Rectangle())
                }
            }

            Card {
                HStack {
                    Text("键盘高度")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(AppTheme.text)
                    Spacer()
                    Text("\(Int(settings.keyboardHeight)) pt")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(AppTheme.primary)
                }
                Slider(value: $settings.keyboardHeight, in: 250...420, step: 5)
                    .tint(AppTheme.primary)
                HStack {
                    Text("紧凑").font(.system(size: 11)).foregroundColor(AppTheme.textSecondary)
                    Spacer()
                    Text("宽大").font(.system(size: 11)).foregroundColor(AppTheme.textSecondary)
                }
                Button("恢复默认（300 pt）") {
                    settings.keyboardHeight = 300
                    showToast("键盘高度已恢复默认")
                }
                .font(.system(size: 12))
                .foregroundColor(AppTheme.primary)
            }

            SettingGroup(title: "单手模式") {
                OptionRow(title: "关闭", selected: settings.oneHand == "off", isLast: false) {
                    settings.oneHand = "off"
                    showToast("已恢复双手")
                }
                OptionRow(title: "左手", selected: settings.oneHand == "left", isLast: false) {
                    settings.oneHand = "left"
                    showToast("已开启左手模式")
                }
                OptionRow(title: "右手", selected: settings.oneHand == "right", isLast: true) {
                    settings.oneHand = "right"
                    showToast("已开启右手模式")
                }
            }
        }
        .sheet(isPresented: $showSideEditor) {
            SideSymbolEditor()
                .environmentObject(settings)
        }
    }
}

struct SideSymbolEditor: View {
    @EnvironmentObject private var settings: AppSettings
    @Environment(\.presentationMode) private var presentation
    @State private var newSymbol = ""
    @State private var symbols: [String] = []
    @State private var editMode: EditMode = .active

    var body: some View {
        NavigationView {
            VStack(spacing: 12) {
                HStack {
                    TextField("添加一个符号", text: $newSymbol)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    Button("添加") {
                        let value = String(newSymbol.prefix(2))
                        guard !value.isEmpty else { return }
                        symbols.append(value)
                        newSymbol = ""
                        save()
                    }
                    .foregroundColor(AppTheme.primary)
                }
                .padding(.horizontal)
                List {
                    ForEach(symbols, id: \.self) { symbol in
                        Text(symbol).font(.system(size: 18))
                    }
                    .onDelete { offsets in
                        symbols.remove(atOffsets: offsets)
                        save()
                    }
                    .onMove { source, destination in
                        symbols.move(fromOffsets: source, toOffset: destination)
                        save()
                    }
                }
                .environment(\.editMode, $editMode)
                Text("拖动右侧把手排序。侧边栏最多显示前 4 个符号。")
                    .font(.system(size: 11))
                    .foregroundColor(AppTheme.textSecondary)
                    .padding(.bottom, 8)
            }
            .background(AppTheme.pageBg.ignoresSafeArea())
            .navigationTitle("自定义侧边符号")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") { presentation.wrappedValue.dismiss() }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("恢复默认") {
                        symbols = ["，", "。", "？", "！"]
                        save()
                        showToast("已恢复默认符号")
                    }
                }
            }
        }
        .onAppear { symbols = settings.sideSymbols }
    }

    private func save() {
        settings.sideSymbols = symbols
    }
}

// MARK: - Fuzzy

struct FuzzyPinyinView: View {
    @EnvironmentObject private var settings: AppSettings
    @State private var expandInitials = true
    @State private var expandFinals = true
    @State private var expandSyllables = false

    var body: some View {
        PageScaffold(title: "模糊拼音", subtitle: "对容易混淆的声母、韵母和音节进行兼容匹配") {
            Card {
                Toggle(isOn: $settings.fuzzyEnabled) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("模糊拼音").font(.system(size: 16, weight: .medium)).foregroundColor(AppTheme.text)
                        Text(settings.fuzzyEnabled ? "已开启，按下方选项兼容发音" : "已关闭，严格匹配拼音")
                            .font(.system(size: 12)).foregroundColor(AppTheme.textSecondary)
                    }
                }
                .tint(AppTheme.primary)
                .onChange(of: settings.fuzzyEnabled) { on in
                    showToast(on ? "模糊拼音已开启" : "模糊拼音已关闭")
                }
            }
            if settings.fuzzyEnabled {
                fuzzySection(title: "声母", options: FuzzyConfig.initialOptions, selection: $settings.fuzzyInitials, expanded: $expandInitials)
                fuzzySection(title: "韵母", options: FuzzyConfig.finalOptions, selection: $settings.fuzzyFinals, expanded: $expandFinals)
                fuzzySection(title: "音节", options: FuzzyConfig.syllableOptions, selection: $settings.fuzzySyllables, expanded: $expandSyllables)
                Card {
                    Text("示例")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(AppTheme.text)
                    Text("开启 z=zh 后输入“zong”可匹配“中”；开启 an=ang 后“fan”可匹配“方”。键盘候选会同时考虑正常与模糊匹配。")
                        .font(.system(size: 12))
                        .foregroundColor(AppTheme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            } else {
                EmptyStateView(icon: "textformat.abc", title: "模糊拼音已关闭", message: "开启后可按声母、韵母、音节选择兼容项。")
            }
        }
    }

    private func fuzzySection(title: String, options: [(String, String)], selection: Binding<[String]>, expanded: Binding<Bool>) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) { expanded.wrappedValue.toggle() }
            } label: {
                HStack {
                    Text(title).font(.system(size: 14, weight: .medium)).foregroundColor(AppTheme.text)
                    Text("\(selection.wrappedValue.count)/\(options.count)")
                        .font(.system(size: 11)).foregroundColor(AppTheme.textSecondary)
                    Spacer()
                    Button("全选") {
                        selection.wrappedValue = options.map { $0.1 }
                        showToast("已全选\(title)")
                    }
                    .font(.system(size: 11)).foregroundColor(AppTheme.primary)
                    Button("清空") {
                        selection.wrappedValue = []
                        showToast("已清空\(title)")
                    }
                    .font(.system(size: 11)).foregroundColor(AppTheme.textSecondary)
                    Image(systemName: expanded.wrappedValue ? "chevron.up" : "chevron.down")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(AppTheme.textSecondary)
                }
                .padding(.vertical, 12)
                .contentShape(Rectangle())
            }
            .buttonStyle(RowButtonStyle())
            if expanded.wrappedValue {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 94), spacing: 8)], spacing: 8) {
                    ForEach(options, id: \.1) { option in
                        let selected = selection.wrappedValue.contains(option.1)
                        Button {
                            var current = selection.wrappedValue
                            if current.contains(option.1) { current.removeAll { $0 == option.1 } } else { current.append(option.1) }
                            selection.wrappedValue = current
                        } label: {
                            HStack(spacing: 4) {
                                Text("\(option.0)=\(option.1)")
                                    .font(.system(size: 12))
                                    .foregroundColor(selected ? AppTheme.primary : AppTheme.text)
                                Spacer(minLength: 0)
                                if selected {
                                    Image(systemName: "checkmark").font(.system(size: 9, weight: .bold)).foregroundColor(AppTheme.primary)
                                }
                            }
                            .padding(.horizontal, 9)
                            .frame(height: 32)
                            .background(selected ? AppTheme.primary.opacity(0.10) : AppTheme.cardAlt)
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(selected ? AppTheme.primary.opacity(0.4) : Color.clear, lineWidth: 1))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                        .buttonStyle(ScaleButtonStyle())
                    }
                }
                .padding(.bottom, 10)
            }
        }
        .padding(.horizontal, 14)
        .background(AppTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

// MARK: - Association / prediction

struct AssociationSettingsView: View {
    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var router: Router

    var body: some View {
        PageScaffold(title: "智能联想", subtitle: "根据上文推荐词语、Emoji 与颜文字") {
            Card {
                Toggle(isOn: $settings.associationEnabled) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("智能联想").font(.system(size: 16, weight: .medium)).foregroundColor(AppTheme.text)
                        Text("输入或上屏后，在候选栏展示关联候选").font(.system(size: 12)).foregroundColor(AppTheme.textSecondary)
                    }
                }
                .tint(AppTheme.primary)
                .onChange(of: settings.associationEnabled) { on in
                    showToast(on ? "智能联想已开启" : "智能联想已关闭")
                }
            }
            Card {
                Text("联想示例")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(AppTheme.text)
                HStack(spacing: 8) {
                    ForEach(["你好", "大家好", "在吗"], id: \.self) { word in
                        Text(word)
                            .font(.system(size: 14))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 7)
                            .background(AppTheme.cardAlt)
                            .clipShape(Capsule())
                    }
                }
                Text("联想在本地完成，使用高频词表与轻量上下文规则；关闭后仍可使用拼音候选。")
                    .font(.system(size: 11))
                    .foregroundColor(AppTheme.textSecondary)
            }
            SecondaryButton(title: "调整输入预测类型", icon: "face.smiling") {
                router.push(.prediction)
            }
        }
    }
}

struct PredictionTypesView: View {
    @EnvironmentObject private var settings: AppSettings

    var body: some View {
        PageScaffold(title: "输入预测类型", subtitle: "选择候选栏中展示的推荐内容") {
            SettingGroup {
                ToggleRow(title: "Emoji", subtitle: "😊 👍 ❤️ 等表情", isOn: $settings.predictionEmoji, isLast: false) { _ in
                    showToast("Emoji 预测已更新")
                }
                ToggleRow(title: "图片表情", subtitle: "本地生成的彩色表情卡片（演示）", isOn: $settings.predictionImage, isLast: false) { _ in
                    showToast("图片表情预测已更新")
                }
                ToggleRow(title: "颜文字", subtitle: "(＾▽＾) (づ｡◕‿‿◕｡)づ 等", isOn: $settings.predictionKaomoji, isLast: true) { _ in
                    showToast("颜文字预测已更新")
                }
            }
            Card {
                Text("预览")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(AppTheme.text)
                HStack(spacing: 10) {
                    if settings.predictionEmoji { Text("😊").font(.system(size: 28)) }
                    if settings.predictionImage {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(LinearGradient(colors: [Color.orange.opacity(0.5), Color.pink.opacity(0.5)], startPoint: .topLeading, endPoint: .bottomTrailing))
                            .frame(width: 44, height: 44)
                            .overlay(Text("图").font(.system(size: 18)).foregroundColor(.white))
                    }
                    if settings.predictionKaomoji { Text("(＾▽＾)").font(.system(size: 16)).foregroundColor(AppTheme.text) }
                    Spacer()
                }
                Text("图片表情为本地绘制的占位卡片，点击会插入 [表情] 标记，不使用官方图片资源。")
                    .font(.system(size: 11))
                    .foregroundColor(AppTheme.textSecondary)
            }
        }
    }
}

// MARK: - Key feedback

struct KeyFeedbackView: View {
    @EnvironmentObject private var settings: AppSettings

    var body: some View {
        PageScaffold(title: "按键反馈", subtitle: "声音、振动、气泡与跟手程度") {
            SettingGroup(title: "响应速度") {
                OptionRow(title: "跟手优先", subtitle: "按键立即响应，适合高速输入", selected: settings.keyResponse == "follow", isLast: false) {
                    settings.keyResponse = "follow"
                    showToast("已选择跟手优先")
                }
                OptionRow(title: "质量优先", subtitle: "轻微防抖，减少误触", selected: settings.keyResponse == "quality", isLast: true) {
                    settings.keyResponse = "quality"
                    showToast("已选择质量优先")
                }
            }
            SettingGroup(title: "声音") {
                ToggleRow(title: "按键声音", isOn: $settings.keySound, isLast: false)
                HStack(spacing: 10) {
                    Image(systemName: "speaker.fill").foregroundColor(AppTheme.textSecondary)
                    Slider(value: $settings.keyVolume, in: 0...1).tint(AppTheme.primary)
                    Image(systemName: "speaker.wave.3.fill").foregroundColor(AppTheme.textSecondary)
                    Button("试听") {
                        playClick()
                    }
                    .font(.system(size: 12))
                    .foregroundColor(AppTheme.primary)
                }
                .padding(.vertical, 10)
            }
            SettingGroup(title: "振动") {
                ToggleRow(title: "按键振动", isOn: $settings.keyVibrate, isLast: false)
                HStack(spacing: 10) {
                    Image(systemName: "iphone.radiowaves.left.and.right").foregroundColor(AppTheme.textSecondary)
                    Slider(value: $settings.keyVibrateLevel, in: 0...1).tint(AppTheme.primary)
                    Button("试振") {
                        let generator = UIImpactFeedbackGenerator(style: settings.keyVibrateLevel > 0.7 ? .medium : .light)
                        generator.impactOccurred()
                    }
                    .font(.system(size: 12))
                    .foregroundColor(AppTheme.primary)
                }
                .padding(.vertical, 10)
            }
            SettingGroup(title: "显示") {
                ToggleRow(title: "26键气泡", subtitle: "长按字母显示放大气泡与备选符号", isOn: $settings.keyBubble, isLast: true)
            }
            Card {
                Text("提示")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(AppTheme.text)
                Text("iOS 键盘扩展的振动与声音受系统设置限制；模拟器可能没有触感。设置会立即同步到键盘扩展。")
                    .font(.system(size: 12))
                    .foregroundColor(AppTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private func playClick() {
        AudioServicesPlaySystemSound(1104)
    }
}

// MARK: - Quick format

struct QuickFormatView: View {
    @EnvironmentObject private var settings: AppSettings

    var body: some View {
        PageScaffold(title: "快捷格式输入", subtitle: "减少中英混排与标点调整的操作") {
            SettingGroup {
                ToggleRow(title: "中英文数字间自动加空格", subtitle: "例如“使用 iOS 17 系统”", isOn: $settings.quickSpace, isLast: false)
                ToggleRow(title: "英文首字母大写", subtitle: "句首自动大写", isOn: $settings.quickCapitalize, isLast: false)
                ToggleRow(title: "双击空格输入句号", subtitle: "英文模式连续按两次空格插入“. ”", isOn: $settings.quickDoubleSpacePeriod, isLast: true)
            }
            Card {
                Text("效果预览")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(AppTheme.text)
                Text(preview)
                    .font(.system(size: 15))
                    .foregroundColor(AppTheme.text)
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(AppTheme.cardAlt)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                Text("快捷格式在本地处理，不依赖云端。部分行为由键盘扩展在输入时执行。")
                    .font(.system(size: 11))
                    .foregroundColor(AppTheme.textSecondary)
            }
        }
    }

    private var preview: String {
        var text = "使用 iOS 17 系统"
        if settings.quickCapitalize { text = "Hello，\(text)" }
        if settings.quickDoubleSpacePeriod { text += "。 " }
        return text
    }
}


