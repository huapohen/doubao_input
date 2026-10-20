import Foundation

enum EmojiData {
    static let categories: [(String, [String])] = [
        ("最近", ["😊", "👍", "❤️", "😂", "🎉", "🙏", "👌", "🔥", "✨", "🥰"]),
        ("表情", ["😀", "😃", "😄", "😁", "😆", "😅", "😂", "🤣", "😊", "😇", "🙂", "🙃", "😉", "😌", "😍", "🥰", "😘", "😗", "😙", "😚", "😋", "😛", "😝", "😜", "🤪", "🤨", "🧐", "🤓", "😎", "🤩", "🥳", "😏", "😒", "😞", "😔", "😟", "😕", "🙁", "☹️", "😣", "😖", "😫", "😩", "🥺", "😢", "😭", "😤", "😠", "😡", "🤬", "🤯", "😳", "🥵", "🥶", "😱", "😨", "😰", "😥", "😓", "🤗", "🤔", "🤭", "🤫", "🤥", "😶", "😐", "😑", "😬", "🙄", "😯", "😦", "😧", "😮", "😲", "🥱", "😴", "🤤", "😪", "😵", "🤐", "🥴", "🤢", "🤮", "🤧", "😷", "🤒", "🤕"]),
        ("手势", ["👍", "👎", "👌", "✌️", "🤞", "🤟", "🤘", "🤙", "👈", "👉", "👆", "👇", "☝️", "✋", "🤚", "🖐", "🖖", "👋", "🤝", "🙏", "👏", "🙌", "👐", "🤲", "💪", "🦾", "✍️", "🤳"]),
        ("爱心", ["❤️", "🧡", "💛", "💚", "💙", "💜", "🖤", "🤍", "🤎", "💔", "❣️", "💕", "💞", "💓", "💗", "💖", "💘", "💝", "💟", "♥️"]),
        ("动物", ["🐶", "🐱", "🐭", "🐹", "🐰", "🦊", "🐻", "🐼", "🐨", "🐯", "🦁", "🐮", "🐷", "🐸", "🐵", "🐔", "🐧", "🐦", "🐤", "🦆", "🦅", "🦉", "🦇", "🐺", "🐗", "🐴", "🦄", "🐝", "🐛", "🦋", "🐌", "🐞", "🐢", "🐍", "🦎", "🐙", "🦑", "🦐", "🦀", "🐬", "🐳", "🦈", "🐊", "🐅", "🐆", "🦓", "🦍", "🐘", "🦏", "🐪"]),
        ("食物", ["🍎", "🍐", "🍊", "🍋", "🍌", "🍉", "🍇", "🍓", "🫐", "🍈", "🍒", "🍑", "🥭", "🍍", "🥥", "🥝", "🍅", "🍆", "🥑", "🥦", "🥬", "🥒", "🌶", "🌽", "🥕", "🍞", "🥐", "🥖", "🥨", "🧀", "🍳", "🥞", "🧇", "🥓", "🍔", "🍟", "🍕", "🌭", "🥪", "🌮", "🍜", "🍲", "🍣", "🍱", "🍚", "🍰", "🎂", "🍪", "🍫", "🍬", "☕️", "🍵", "🧋"]),
        ("活动", ["⚽️", "🏀", "🏈", "⚾️", "🎾", "🏐", "🏉", "🎱", "🏓", "🏸", "🥊", "🎯", "🎮", "🎲", "🎸", "🎹", "🎺", "🎻", "🥁", "🎤", "🎧", "🎬", "📷", "🎨", "✈️", "🚗", "🚕", "🚌", "🚲", "🏃", "🚀", "🎉", "🎊", "🎁", "🎈"]),
        ("符号", ["✅", "❌", "⭐️", "🌟", "💫", "⚡️", "💥", "💦", "💨", "🔥", "✨", "🎵", "🎶", "💡", "📌", "📎", "🔗", "✔️", "☑️", "🔴", "🟠", "🟡", "🟢", "🔵", "🟣", "⚫️", "⚪️", "🟤"])
    ]

    static let kaomoji: [(String, [String])] = [
        ("开心", ["(＾▽＾)", "(￣▽￣)", "(≧▽≦)", "ヽ(✿ﾟ▽ﾟ)ノ", "( •̀ ω •́ )✧", "(๑•̀ㅂ•́)و✧"]),
        ("打招呼", ["( ´ ▽ ` )ﾉ", "(・ω・)ノ", "(｡･ω･｡)ﾉ♡", "ヾ(＾∇＾)", "(＾▽＾)／"]),
        ("难过", ["(；′⌒`)", "(╥﹏╥)", "(´；ω；`)", "(个_个)", "(｡•́︿•̀｡)"]),
        ("生气", ["(╯°□°）╯︵ ┻━┻", "(￣ヘ￣)", "(｀Д´)", "٩(╬ʘ益ʘ╬)۶"]),
        ("可爱", ["(づ｡◕‿‿◕｡)づ", "(๑´ω`๑)", "(*/ω＼*)", "(◍•ᴗ•◍)", "ʕ•ᴥ•ʔ"]),
        ("无语", ["(・_・;)", "(￣▽￣)ゞ", "_(:з」∠)_", "(⌒_⌒;)", "┐(￣ヘ￣)┌"])
    ]
}

enum LocalIntelligence {
    static let fillerWords = ["嗯", "啊", "呃", "那个", "就是说", "然后呢", "你知道吧", "这个这个", "额"]

    static func organize(_ text: String, removeFillers: Bool, blankLineParagraphs: Bool, punctuation: String) -> String {
        var result = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !result.isEmpty else { return "" }
        if removeFillers {
            for filler in fillerWords {
                result = result.replacingOccurrences(of: filler, with: "")
            }
        }
        result = result.replacingOccurrences(of: "，,", with: "，")
            .replacingOccurrences(of: "。。", with: "。")
            .replacingOccurrences(of: "  ", with: " ")
        switch punctuation {
        case "none":
            result = result.replacingOccurrences(of: "，", with: "")
            result = result.replacingOccurrences(of: "。", with: "")
        case "comma":
            result = result.replacingOccurrences(of: "。", with: "，")
        case "period":
            result = result.replacingOccurrences(of: "，", with: "。")
        default:
            break
        }
        let sentences = result.split(whereSeparator: { "。！？!?".contains($0) }).map(String.init)
        if sentences.count > 2 {
            let separator = blankLineParagraphs ? "\n\n" : "\n"
            result = sentences.enumerated().map { index, sentence in
                let trimmed = sentence.trimmingCharacters(in: .whitespaces)
                return trimmed + (trimmed.isEmpty ? "" : "。")
            }.joined(separator: separator)
        } else if !result.isEmpty && !"?!。！？…".contains(result.last!) {
            result += "。"
        }
        return result
    }

    static func actionTemplates(_ action: String, context: String) -> String {
        switch action {
        case "祝福":
            return "愿你的每一天都有阳光和好心情，所求皆如愿，所行化坦途。新的一程，平安喜乐，万事胜意！"
        case "高赞动态":
            return "最近发现，把日子过得松弛一点，反而什么都不会耽误。认真吃饭、好好睡觉、偶尔出门走走，生活自会把答案慢慢递给你。✨"
        case "写评论":
            return "这段内容说得很实在，尤其是把复杂的事情讲得这么清楚，收藏了，等有空再慢慢消化。"
        case "自我介绍":
            return "你好，我是小林，平时喜欢阅读、运动和探索新工具。做事比较注重细节，也乐于把复杂问题拆成可执行的步骤。很高兴认识你，期待一起把这件事做好。"
        case "宴席邀请":
            return "诚邀您参加我们的家宴，时间定于本周六晚六点，地点在城南小馆。届时备好薄酒小菜，盼望与您畅叙近况，恭候光临。"
        case "写邮件":
            return "您好：\n\n关于项目进度，目前核心功能已经完成，正在进行联调与测试。预计本周五前提交第一版可体验版本，如有调整我会及时同步。\n\n感谢您的支持！\n\n此致\n敬礼"
        case "爆款文案":
            return "别再硬撑了。真正让人轻松下来的，从来不是把事情做完，而是允许自己偶尔停下来。今天，给自己留十分钟，喝杯热的，发会儿呆。生活不会因为你歇一会儿就跑掉。"
        default:
            let seed = context.trimmingCharacters(in: .whitespacesAndNewlines)
            return seed.isEmpty ? actionTemplates("祝福", context: "") : "围绕“\(seed.prefix(20))”，可以这样写：先点明场景，再给一个具体细节，最后落到真诚的感受。愿你所表达的，都被温柔接住。"
        }
    }

    static func rewrite(_ text: String, mode: String) -> String {
        switch mode {
        case "总结":
            let pieces = text.split(whereSeparator: { "。！？!?\n".contains($0) }).prefix(2)
            return "要点总结：" + pieces.joined(separator: "；") + "。"
        case "关键点":
            let pieces = text.split(whereSeparator: { "。！？!?\n".contains($0) }).prefix(4)
            return pieces.enumerated().map { "• \($1.trimmingCharacters(in: .whitespaces))" }.joined(separator: "\n")
        case "列表":
            let pieces = text.split(whereSeparator: { "。！？!?\n".contains($0) }).prefix(5)
            return pieces.enumerated().map { "\($0.offset + 1). \($0.element.trimmingCharacters(in: .whitespaces))" }.joined(separator: "\n")
        case "检查":
            return text.contains("  ") || text.contains("，，") ? text.replacingOccurrences(of: "  ", with: " ").replacingOccurrences(of: "，，", with: "，") : text
        default:
            return "在这里，我想更从容地表达：\(text.trimmingCharacters(in: .whitespacesAndNewlines))"
        }
    }

    // A small phrasebook used when no AI key is configured. Results are explicitly
    // labelled as offline examples by the UI.
    private static let phrasebook: [(String, String)] = [
        ("你好", "Hello"),
        ("谢谢", "Thank you"),
        ("对不起", "I'm sorry"),
        ("没关系", "It's all right"),
        ("早上好", "Good morning"),
        ("晚安", "Good night"),
        ("再见", "Goodbye"),
        ("好久不见", "Long time no see"),
        ("今天天气很好", "The weather is nice today"),
        ("请问洗手间在哪里", "Excuse me, where is the restroom?"),
        ("我要一杯咖啡", "I'd like a cup of coffee"),
        ("这个多少钱", "How much is this?"),
        ("可以便宜一点吗", "Could you make it a little cheaper?"),
        ("我不太明白", "I don't quite understand"),
        ("请再说一遍", "Please say that again"),
        ("很高兴认识你", "Nice to meet you"),
        ("我马上到", "I'll be there soon"),
        ("收到，谢谢", "Received, thank you"),
        ("没问题", "No problem"),
        ("祝你好运", "Good luck"),
        ("我爱你", "I love you"),
        ("生日快乐", "Happy birthday"),
        ("新年快乐", "Happy New Year"),
        ("请给我菜单", "May I have the menu, please?"),
        ("我迷路了", "I'm lost"),
        ("帮帮我", "Please help me"),
        ("会议几点开始", "What time does the meeting start?"),
        ("我明天有空", "I'm free tomorrow"),
        ("请稍等", "One moment, please"),
        ("干杯", "Cheers")
    ]

    static func translate(_ text: String, toEnglish: Bool) -> String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return "" }
        if toEnglish {
            for (zh, en) in phrasebook where trimmed.contains(zh) {
                return en
            }
            if trimmed.range(of: "^[A-Za-z0-9 .,!?'-]+$", options: .regularExpression) != nil { return trimmed }
            return "[离线示例] " + trimmed
        } else {
            for (zh, en) in phrasebook where trimmed.lowercased().contains(en.lowercased()) {
                return zh
            }
            return "[离线示例] " + trimmed
        }
    }

    static func englishSuggestions(_ word: String) -> [String] {
        []
    }

    // Very small simplified/traditional demo map.
    private static let traditionalMap: [Character: Character] = [
        "这": "這", "个": "個", "们": "們", "来": "來", "说": "說", "时": "時", "会": "會",
        "后": "後", "里": "裡", "为": "為", "国": "國", "过": "過", "还": "還", "么": "麼",
        "车": "車", "门": "門", "问": "問", "题": "題", "见": "見", "听": "聽", "写": "寫",
        "学": "學", "爱": "愛", "开": "開", "关": "關", "长": "長", "马": "馬", "鸟": "鳥",
        "鱼": "魚", "龙": "龍", "风": "風", "云": "雲", "电": "電", "话": "話", "语": "語",
        "书": "書", "买": "買", "卖": "賣", "东": "東", "点": "點", "儿": "兒",
        "让": "讓", "对": "對", "无": "無", "与": "與", "于": "於", "广": "廣", "场": "場",
        "机": "機", "条": "條", "应": "應", "难": "難", "欢": "歡", "乐": "樂", "顶": "頂"
    ]

    static func traditional(_ text: String, toTraditional: Bool) -> String {
        guard toTraditional else { return text }
        let reverse = Dictionary(uniqueKeysWithValues: traditionalMap.map { key, value in
            (value, key)
        })
        return String(text.map { traditionalMap[$0] ?? reverse[$0] ?? $0 })
    }

    static func applyQuickFormat(_ text: String, capitalize: Bool) -> String {
        guard capitalize, let first = text.first else { return text }
        return first.uppercased() + text.dropFirst()
    }
}

enum PunctuationStyle: String, CaseIterable, Identifiable {
    case smart = "智能标点"
    case period = "全部句号"
    case comma = "全部逗号"
    case none = "不加标点"

    var id: String { rawValue }
    var key: String {
        switch self {
        case .smart: return "smart"
        case .period: return "period"
        case .comma: return "comma"
        case .none: return "none"
        }
    }
}
