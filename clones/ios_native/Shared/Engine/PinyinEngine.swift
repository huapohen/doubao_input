import Foundation

struct Candidate: Identifiable, Equatable {
    let id = UUID()
    let text: String
    let pinyin: String
    let detail: String
    var score: Double
    let source: String
    /// Optional full text to insert when the display label is abbreviated
    /// (used by long clipboard candidates).
    var insertText: String? = nil

    static func == (lhs: Candidate, rhs: Candidate) -> Bool { lhs.text == rhs.text && lhs.pinyin == rhs.pinyin }
}

enum InputScript: String {
    case pinyin
    case t9
    case shuangpin
    case wubi
    case english
}

/// Offline pinyin / T9 / initials engine. Loads the MIT-derived shared dictionary
/// (jieba + pypinyin data, 33,500 entries) bundled with both targets.
final class PinyinEngine {
    static let shared = PinyinEngine()

    struct Entry {
        let word: String
        let compact: String
        let spaced: String
        let initials: String
        let t9: String
        let freq: Double
    }

    struct FuzzyOptions {
        var enabled: Bool = false
        var initials: Set<String> = []
        var finals: Set<String> = []
        var syllables: Set<String> = []

        var signature: String {
            enabled ? "1|\(initials.sorted().joined(separator: ","))|\(finals.sorted().joined(separator: ","))|\(syllables.sorted().joined(separator: ","))" : "off"
        }
    }

    private(set) var entries: [Entry] = []
    private var exact: [String: [Int]] = [:]
    private var initialsMap: [String: [Int]] = [:]
    private var t9Map: [String: [Int]] = [:]
    private var sortedCompact: [(String, Int)] = []
    private var sortedT9: [(String, Int)] = []
    private var syllableSet: Set<String> = []

    private var fuzzyCache: [String: ([String: [Int]], [(String, Int)])] = [:]
    private var loaded = false
    private let loadLock = NSRecursiveLock()
    private let mruKey = "mru_words"
    private let blockedKey = "blocked_words"

    private let englishWords: [String] = [
        "hello", "help", "here", "hey", "how", "have", "happy", "hope", "home", "house",
        "good", "great", "get", "got", "going", "goodbye", "glad", "group", "guess", "give",
        "thanks", "thank", "that", "this", "the", "there", "their", "them", "then", "think",
        "time", "today", "tomorrow", "tonight", "together", "talk", "take", "tell", "try",
        "love", "like", "look", "let", "last", "later", "little", "life", "live", "long",
        "meeting", "message", "more", "most", "make", "many", "maybe", "mean", "morning", "music",
        "name", "need", "new", "next", "nice", "night", "now", "number", "never", "nothing",
        "okay", "only", "one", "other", "our", "out", "over", "open", "order", "office",
        "please", "people", "place", "plan", "problem", "project", "put", "question", "quick", "quite",
        "really", "right", "ready", "room", "run", "said", "same", "see", "send", "sure",
        "sorry", "still", "something", "soon", "start", "sure", "speak", "support", "system", "school",
        "take", "thing", "think", "today", "together", "told", "too", "try", "two", "understand",
        "very", "want", "wait", "way", "welcome", "well", "what", "when", "where", "which",
        "who", "why", "will", "with", "word", "work", "world", "would", "write", "yes",
        "you", "your", "zero", "be", "at", "in", "on", "of", "to", "is", "it", "we",
        "中文", "输入", "豆包", "你好", "谢谢", "收到", "好的", "可以", "没问题", "稍等"
    ]

    private init() {}

    // MARK: - Loading

    func loadIfNeeded() {
        loadLock.lock()
        defer { loadLock.unlock() }
        guard !loaded else { return }
        loaded = true
        let candidatesURLs = [
            Bundle.main.url(forResource: "pinyin_dict", withExtension: "json"),
            Bundle(for: PinyinEngine.self).url(forResource: "pinyin_dict", withExtension: "json")
        ].compactMap { $0 }

        guard let url = candidatesURLs.first,
              let data = try? Data(contentsOf: url),
              let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let raw = root["entries"] as? [[String: Any]] else {
            buildFallback()
            return
        }

        var built: [Entry] = []
        built.reserveCapacity(raw.count)
        for item in raw {
            guard let word = item["w"] as? String, let pinyin = item["p"] as? String else { continue }
            let freq = (item["f"] as? NSNumber)?.doubleValue ?? 1
            let compact = pinyin.replacingOccurrences(of: " ", with: "").lowercased()
            if compact.isEmpty { continue }
            let tokens = pinyin.lowercased().split(separator: " ").map(String.init)
            let initials = tokens.compactMap { $0.first }.map(String.init).joined()
            built.append(Entry(word: word, compact: compact, spaced: pinyin.lowercased(), initials: initials, t9: Self.t9(compact), freq: freq))
        }
        if built.isEmpty { buildFallback(); return }
        entries = built
        buildIndexes()
    }

    private func buildFallback() {
        let fallback: [(String, String, Double)] = [
            ("你好", "ni hao", 9000), ("我", "wo", 8000), ("的", "de", 7900), ("是", "shi", 7800),
            ("在", "zai", 7700), ("不", "bu", 7600), ("了", "le", 7500), ("有", "you", 7400),
            ("人", "ren", 7300), ("这", "zhe", 7200), ("中", "zhong", 7100), ("国", "guo", 7000),
            ("今天", "jin tian", 6000), ("明天", "ming tian", 5900), ("谢谢", "xie xie", 5800),
            ("豆包", "dou bao", 5700), ("输入法", "shu ru fa", 5600), ("可以", "ke yi", 5500),
            ("什么", "shen me", 5400), ("怎么", "zen me", 5300), ("好的", "hao de", 5200),
            ("收到", "shou dao", 5100), ("再见", "zai jian", 5000), ("喜欢", "xi huan", 4900)
        ]
        entries = fallback.map { word, pinyin, freq in
            let compact = pinyin.replacingOccurrences(of: " ", with: "")
            let tokens = pinyin.split(separator: " ").map(String.init)
            return Entry(word: word, compact: compact, spaced: pinyin, initials: tokens.compactMap { $0.first }.map(String.init).joined(), t9: Self.t9(compact), freq: freq)
        }
        buildIndexes()
    }

    private func buildIndexes() {
        exact.removeAll(keepingCapacity: true)
        initialsMap.removeAll(keepingCapacity: true)
        t9Map.removeAll(keepingCapacity: true)
        syllableSet.removeAll(keepingCapacity: true)

        for (idx, entry) in entries.enumerated() {
            exact[entry.compact, default: []].append(idx)
            initialsMap[entry.initials, default: []].append(idx)
            t9Map[entry.t9, default: []].append(idx)
            for token in entry.spaced.split(separator: " ") {
                syllableSet.insert(String(token))
            }
        }
        sortedCompact = entries.enumerated().map { ($0.element.compact, $0.offset) }.sorted { $0.0 < $1.0 }
        sortedT9 = entries.enumerated().map { ($0.element.t9, $0.offset) }.sorted { $0.0 < $1.0 }

        // High frequency first within exact buckets.
        for key in exact.keys {
            exact[key]?.sort { entries[$0].freq > entries[$1].freq }
        }
        for key in t9Map.keys {
            t9Map[key]?.sort { entries[$0].freq > entries[$1].freq }
        }
        for key in initialsMap.keys {
            initialsMap[key]?.sort { entries[$0].freq > entries[$1].freq }
        }
    }

    // MARK: - T9 / fuzzy

    static func t9(_ compact: String) -> String {
        let map: [Character: Character] = [
            "a": "2", "b": "2", "c": "2",
            "d": "3", "e": "3", "f": "3",
            "g": "4", "h": "4", "i": "4",
            "j": "5", "k": "5", "l": "5",
            "m": "6", "n": "6", "o": "6",
            "p": "7", "q": "7", "r": "7", "s": "7",
            "t": "8", "u": "8", "v": "8",
            "w": "9", "x": "9", "y": "9", "z": "9"
        ]
        var result = ""
        for ch in compact {
            if let digit = map[ch] { result.append(digit) }
            else if ch.isNumber { result.append(ch) }
        }
        return result
    }

    private func normalized(_ text: String, options: FuzzyOptions) -> String {
        guard options.enabled else { return text }
        var value = text
        let initialMap = [("zh", "z"), ("ch", "c"), ("sh", "s"), ("f", "h"), ("n", "l"), ("r", "l")]
        for pair in initialMap where options.initials.contains(pair.1) || options.initials.contains(pair.0) {
            value = value.replacingOccurrences(of: pair.0, with: pair.1)
        }
        let finalMap = [("ang", "an"), ("eng", "en"), ("ing", "in"), ("iang", "ian"), ("uang", "uan"), ("ong", "un"), ("ie", "ei"), ("uo", "ou")]
        for pair in finalMap where options.finals.contains(pair.1) || options.finals.contains(pair.0) {
            value = value.replacingOccurrences(of: pair.0, with: pair.1)
        }
        if options.syllables.contains("fei") { value = value.replacingOccurrences(of: "fei", with: "hui") }
        if options.syllables.contains("wang") { value = value.replacingOccurrences(of: "wang", with: "huang") }
        return value
    }

    private func fuzzyIndex(_ options: FuzzyOptions) -> ([String: [Int]], [(String, Int)]) {
        let key = options.signature
        if let cached = fuzzyCache[key] { return cached }
        var map: [String: [Int]] = [:]
        for (idx, entry) in entries.enumerated() {
            map[normalized(entry.compact, options: options), default: []].append(idx)
        }
        var pairs: [(String, Int)] = []
        for (key, indices) in map {
            for idx in indices { pairs.append((key, idx)) }
        }
        let sorted = pairs.sorted { $0.0 < $1.0 }
        let result = (map, sorted)
        fuzzyCache[key] = result
        return result
    }

    // MARK: - Candidates

    func candidates(for rawInput: String, script: InputScript, fuzzy: FuzzyOptions = FuzzyOptions(), limit: Int = 9) -> [Candidate] {
        loadIfNeeded()
        let input = rawInput.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        guard !input.isEmpty else { return associations(after: "", limit: limit) }

        switch script {
        case .english:
            return englishCandidates(input, limit: limit)
        case .t9:
            return t9Candidates(input, limit: limit)
        case .wubi:
            return wubiCandidates(input, limit: limit)
        case .shuangpin:
            let converted = ShuangpinConverter.convert(input, scheme: SettingsReader.doublePinyinScheme)
            return pinyinCandidates(converted.isEmpty ? input : converted, fuzzy: fuzzy, limit: limit, sourceLabel: "双拼")
        case .pinyin:
            return pinyinCandidates(input, fuzzy: fuzzy, limit: limit, sourceLabel: "拼音")
        }
    }

    private func pinyinCandidates(_ input: String, fuzzy: FuzzyOptions, limit: Int, sourceLabel: String) -> [Candidate] {
        let compact = input.replacingOccurrences(of: "'", with: "").replacingOccurrences(of: " ", with: "")
        guard !compact.isEmpty else { return [] }
        var scores: [String: Candidate] = [:]
        let mru = recentWords()
        let blocked = Set(SharedStore.stringArray(blockedKey))
        let personal = personalEntries()

        func add(_ idx: Int, base: Double, source: String) {
            let entry = entries[idx]
            if blocked.contains(entry.word) { return }
            var score = base + entry.freq
            if entry.word.count > 1 { score += 400 }
            if mru.contains(entry.word) { score += 90000 }
            if personal.contains(where: { $0.word == entry.word }) { score += 250000 }
            let prior = scores[entry.word]
            if prior == nil || prior!.score < score {
                scores[entry.word] = Candidate(text: entry.word, pinyin: entry.spaced, detail: entry.spaced, score: score, source: source)
            }
        }

        let useFuzzy = fuzzy.enabled
        let index = useFuzzy ? fuzzyIndex(fuzzy) : (exact, sortedCompact)
        let query = useFuzzy ? normalized(compact, options: fuzzy) : compact

        if let indices = index.0[query] {
            for idx in indices.prefix(30) { add(idx, base: 60000, source: sourceLabel) }
        }

        // Prefix matches: words whose pinyin begins with what was typed.
        let sorted = index.1
        var pos = lowerBound(sorted, query)
        var scanned = 0
        while pos < sorted.count, sorted[pos].0.hasPrefix(query), scanned < 900 {
            add(sorted[pos].1, base: 30000 - Double(scanned) * 2, source: sourceLabel)
            pos += 1
            scanned += 1
        }

        // Initials (简拼): nh -> 你好.
        if compact.count >= 2 {
            let initialsQuery = useFuzzy ? normalized(compact, options: fuzzy) : compact
            for (key, indices) in initialsMap where key == initialsQuery {
                for idx in indices.prefix(20) { add(idx, base: 22000, source: "简拼") }
            }
        }

        // Personal words not in dictionary, or matching by pinyin prefix.
        for item in personal {
            let p = item.pinyin.replacingOccurrences(of: " ", with: "").lowercased()
            if p.hasPrefix(query) || item.word.hasPrefix(input) {
                let score = 400000 + Double(item.word.count)
                scores[item.word] = Candidate(text: item.word, pinyin: item.pinyin, detail: item.pinyin, score: score, source: "个人词库")
            }
        }

        // Partial syllable fallback: typing "nih" can still offer 你.
        if scores.isEmpty || (scores.count < 3 && compact.count > 2) {
            var cut = compact.count - 1
            while cut >= 1 {
                let piece = String(compact.prefix(cut))
                if syllableSet.contains(piece) || exact[piece] != nil {
                    for idx in (exact[piece] ?? []).prefix(5) {
                        add(idx, base: 12000, source: "拼音")
                    }
                    break
                }
                cut -= 1
            }
        }

        // Emoji / kaomoji / image suggestions when enabled and a sensible query exists.
        return Array(scores.values.sorted { $0.score > $1.score }.prefix(limit))
    }

    private func t9Candidates(_ input: String, limit: Int) -> [Candidate] {
        let digits = input.filter { $0.isNumber }
        guard !digits.isEmpty else { return [] }
        var scores: [String: Candidate] = [:]
        let mru = recentWords()
        let personal = personalEntries()

        func add(_ idx: Int, base: Double) {
            let entry = entries[idx]
            var score = base + entry.freq
            if entry.word.count > 1 { score += 300 }
            if mru.contains(entry.word) { score += 90000 }
            if personal.contains(where: { $0.word == entry.word }) { score += 250000 }
            if let old = scores[entry.word], old.score >= score { return }
            scores[entry.word] = Candidate(text: entry.word, pinyin: entry.spaced, detail: "\(entry.spaced) · \(entry.t9)", score: score, source: "9键")
        }

        if let indices = t9Map[digits] {
            for idx in indices.prefix(40) { add(idx, base: 50000) }
        }
        var pos = lowerBound(sortedT9, digits)
        var scanned = 0
        while pos < sortedT9.count, sortedT9[pos].0.hasPrefix(digits), scanned < 700 {
            add(sortedT9[pos].1, base: 25000 - Double(scanned) * 2)
            pos += 1
            scanned += 1
        }
        // Partial digit fallback (type 9 then 4 ...).
        if scores.isEmpty, digits.count > 1 {
            let prefix = String(digits.prefix(digits.count - 1))
            if let indices = t9Map[prefix] { for idx in indices.prefix(5) { add(idx, base: 10000) } }
        }
        return Array(scores.values.sorted { $0.score > $1.score }.prefix(limit))
    }

    private func wubiCandidates(_ input: String, limit: Int) -> [Candidate] {
        let code = input.lowercased().filter { $0.isLetter }
        guard !code.isEmpty else { return [] }
        var results: [Candidate] = []
        let matches = WubiTable.lookup(prefix: code)
        for (index, item) in matches.enumerated() where index < 8 {
            results.append(Candidate(text: item.word, pinyin: item.code, detail: "五笔 \(item.code)", score: Double(100000 - index * 100), source: "五笔"))
        }
        if SettingsReader.wubiMixed {
            let pinyin = pinyinCandidates(code, fuzzy: FuzzyOptions(), limit: 6, sourceLabel: "拼音混输")
            results.append(contentsOf: pinyin)
        }
        var seen = Set<String>()
        return Array(results.filter { seen.insert($0.text).inserted }.prefix(limit))
    }

    private func englishCandidates(_ input: String, limit: Int) -> [Candidate] {
        let query = input.lowercased()
        var results: [Candidate] = []
        let personal = personalEntries().filter { $0.word.range(of: "^[A-Za-z]+$", options: .regularExpression) != nil }
        for item in personal where item.word.lowercased().hasPrefix(query) {
            results.append(Candidate(text: item.word, pinyin: "", detail: "个人词库", score: 300000, source: "个人词库"))
        }
        var seen = Set(results.map { $0.text.lowercased() })
        for word in englishWords where word.lowercased().hasPrefix(query) {
            if seen.insert(word).inserted {
                results.append(Candidate(text: word, pinyin: "", detail: "English", score: Double(1000 - results.count), source: "English"))
            }
        }
        let mru = recentWords()
        for word in mru where word.lowercased().hasPrefix(query) {
            if seen.insert(word).inserted {
                results.append(Candidate(text: word, pinyin: "", detail: "最近使用", score: 90000, source: "最近"))
            }
        }
        return Array(results.sorted { $0.score > $1.score }.prefix(limit))
    }

    func associations(after context: String, limit: Int = 9) -> [Candidate] {
        loadIfNeeded()
        var results: [Candidate] = []
        let table: [String: [String]] = [
            "你好": ["我好", "大家好", "在吗", "最近怎么样"],
            "谢谢": ["不客气", "没关系", "应该的"],
            "收到": ["好的", "我马上处理", "稍等"],
            "好的": ["没问题", "收到", "我马上到"],
            "在吗": ["在的", "怎么了", "你说"],
            "再见": ["拜拜", "下次见", "路上小心"],
            "今天": ["天气不错", "有点忙", "很开心"],
            "明天": ["见", "再说", "有空吗"],
            "可以": ["没问题", "好的", "我安排一下"],
            "豆包": ["输入法", "很好用", "语音输入"],
            "请输入": ["内容", "文字", "搜索关键词"]
        ]
        let last = String(context.suffix(6))
        if SettingsReader.associationEnabled {
            for (key, values) in table where context.contains(key) || last.contains(key) {
                for (i, value) in values.enumerated() {
                    results.append(Candidate(text: value, pinyin: "", detail: "智能联想", score: 1000 - Double(i), source: "联想"))
                }
            }
            if SettingsReader.predictionEmoji {
                let emoji = ["😊", "👍", "❤️", "🎉", "😂", "🙏"]
                for e in emoji { results.append(Candidate(text: e, pinyin: "", detail: "Emoji", score: 20, source: "预测")) }
            }
            if SettingsReader.predictionKaomoji {
                let kao = ["(＾▽＾)", "( ´ ▽ ` )ﾉ", "(づ｡◕‿‿◕｡)づ", "(￣▽￣)~*"]
                for k in kao { results.append(Candidate(text: k, pinyin: "", detail: "颜文字", score: 10, source: "预测")) }
            }
            if SettingsReader.predictionImage {
                results.append(Candidate(text: "[表情]", pinyin: "", detail: "图片表情（本地占位）", score: 8, source: "预测"))
            }
        }
        var seen = Set<String>()
        return Array(results.filter { seen.insert($0.text).inserted }.prefix(limit))
    }

    // MARK: - Learning

    func learn(_ word: String) {
        guard !word.isEmpty else { return }
        var list = SharedStore.stringArray(mruKey)
        list.removeAll { $0 == word }
        list.insert(word, at: 0)
        if list.count > 60 { list = Array(list.prefix(60)) }
        SharedStore.defaults.set(list, forKey: mruKey)
        SharedStore.defaults.synchronize()
    }

    func block(_ word: String) {
        var list = SharedStore.stringArray(blockedKey)
        if !list.contains(word) {
            list.append(word)
            SharedStore.defaults.set(list, forKey: blockedKey)
        }
    }

    func recentWords() -> [String] {
        SharedStore.stringArray(mruKey)
    }

    func personalEntries() -> [LexiconEntry] {
        SharedStore.data([LexiconEntry].self, forKey: "personal_lexicon", fallback: [])
    }

    // MARK: - Utilities

    private func lowerBound(_ array: [(String, Int)], _ value: String) -> Int {
        var low = 0
        var high = array.count
        while low < high {
            let mid = (low + high) / 2
            if array[mid].0 < value { low = mid + 1 } else { high = mid }
        }
        return low
    }

    func searchWords(query: String, limit: Int = 30) -> [Candidate] {
        loadIfNeeded()
        let q = query.lowercased()
        guard !q.isEmpty else { return [] }
        var out: [Candidate] = []
        for entry in entries where entry.word.contains(query) || entry.compact.hasPrefix(q) {
            out.append(Candidate(text: entry.word, pinyin: entry.spaced, detail: entry.spaced, score: entry.freq, source: "词典"))
            if out.count >= limit * 3 { break }
        }
        return Array(out.sorted { $0.score > $1.score }.prefix(limit))
    }

    /// Fuzzy config read from shared defaults for the extension and demo keyboard.
    static func currentFuzzyOptions() -> FuzzyOptions {
        let d = SharedStore.defaults
        let enabled = d.bool(forKey: "fuzzy_enabled")
        return FuzzyOptions(
            enabled: enabled,
            initials: Set(SharedStore.stringArray("fuzzy_initials")),
            finals: Set(SharedStore.stringArray("fuzzy_finals")),
            syllables: Set(SharedStore.stringArray("fuzzy_syllables"))
        )
    }
}

/// A tiny reader for values the extension needs frequently.
enum SettingsReader {
    static var defaults: UserDefaults { SharedStore.defaults }

    static var keyboardKind: KeyboardKind {
        KeyboardKind(rawValue: defaults.string(forKey: "keyboard_type") ?? "") ?? .pinyin26
    }
    static var doublePinyinScheme: String { defaults.string(forKey: "double_pinyin_scheme") ?? "xiaohe" }
    static var associationEnabled: Bool { defaults.object(forKey: "association_enabled") as? Bool ?? true }
    static var predictionEmoji: Bool { defaults.object(forKey: "prediction_emoji") as? Bool ?? true }
    static var predictionImage: Bool { defaults.object(forKey: "prediction_image") as? Bool ?? true }
    static var predictionKaomoji: Bool { defaults.object(forKey: "prediction_kaomoji") as? Bool ?? true }
    static var keySound: Bool { defaults.object(forKey: "key_sound") as? Bool ?? true }
    static var keyVibrate: Bool { defaults.object(forKey: "key_vibrate") as? Bool ?? true }
    static var keyBubble: Bool { defaults.object(forKey: "key_bubble") as? Bool ?? true }
    static var oneHand: String { defaults.string(forKey: "one_hand") ?? "off" }
    static var keyboardHeight: Double { defaults.object(forKey: "keyboard_height") as? Double ?? 300 }
    static var candidateFontSize: Double { defaults.object(forKey: "candidate_font_size") as? Double ?? 22 }
    static var enterSend: Bool { defaults.object(forKey: "enter_send") as? Bool ?? false }
    static var quickDoubleSpacePeriod: Bool { defaults.object(forKey: "quick_double_space_period") as? Bool ?? true }
    static var quickCapitalize: Bool { defaults.object(forKey: "quick_capitalize") as? Bool ?? true }
    static var wubiMixed: Bool { defaults.object(forKey: "wubi_mixed") as? Bool ?? true }
    static var wubiHint: Bool { defaults.object(forKey: "wubi_hint") as? Bool ?? true }
    static var themeMode: String { defaults.string(forKey: "theme_mode") ?? "system" }
    static var sideSymbols: [String] {
        let symbols = SharedStore.stringArray("layout_side_symbols")
        return symbols.isEmpty ? ["，", "。", "？", "！"] : symbols
    }
    static var clipboardCandidate: Bool { defaults.object(forKey: "clipboard_candidate") as? Bool ?? true }
    static var auxiliaryInput: Bool { defaults.object(forKey: "auxiliary_input") as? Bool ?? true }
    static var keyResponse: String { defaults.string(forKey: "key_response") ?? "follow" }
    static var floating: Bool { defaults.bool(forKey: "floating") }
    static var privacyMode: String { defaults.string(forKey: "privacy_mode") ?? "smart" }
    static var inputMode: String { defaults.string(forKey: "input_mode") ?? "smart" }
}
