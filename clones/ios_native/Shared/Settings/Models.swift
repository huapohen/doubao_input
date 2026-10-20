import Foundation

// MARK: - Shared value types used by the app and the keyboard extension.

public struct ClipboardItem: Codable, Identifiable, Equatable {
    public var id: UUID
    public var text: String
    public var date: Date
    public var kind: String // "text" | "image"
    public var pinned: Bool

    public init(id: UUID = UUID(), text: String, date: Date = Date(), kind: String = "text", pinned: Bool = false) {
        self.id = id
        self.text = text
        self.date = date
        self.kind = kind
        self.pinned = pinned
    }

    public var displayTime: String {
        let f = DateFormatter()
        f.dateFormat = "MM-dd HH:mm"
        return f.string(from: date)
    }
}

public struct Phrase: Codable, Identifiable, Equatable {
    public var id: UUID
    public var text: String
    public var category: String
    public var useCount: Int

    public init(id: UUID = UUID(), text: String, category: String = "通用", useCount: Int = 0) {
        self.id = id
        self.text = text
        self.category = category
        self.useCount = useCount
    }
}

public struct LexiconEntry: Codable, Identifiable, Equatable {
    public var id: UUID
    public var word: String
    public var pinyin: String
    public var source: String
    public var addedAt: Date

    public init(id: UUID = UUID(), word: String, pinyin: String = "", source: String = "个人", addedAt: Date = Date()) {
        self.id = id
        self.word = word
        self.pinyin = pinyin
        self.source = source
        self.addedAt = addedAt
    }
}

public struct AppMessage: Codable, Identifiable, Equatable {
    public var id: UUID
    public var title: String
    public var body: String
    public var date: Date
    public var read: Bool
    public var kind: String

    public init(id: UUID = UUID(), title: String, body: String, date: Date = Date(), read: Bool = false, kind: String = "系统") {
        self.id = id
        self.title = title
        self.body = body
        self.date = date
        self.read = read
        self.kind = kind
    }

    public static var samples: [AppMessage] {
        [
            AppMessage(title: "欢迎使用豆包输入法（复刻）", body: "这是净室复刻版本，所有数据默认保存在本机。前往“键盘类型”选择你喜欢的布局。", date: Date().addingTimeInterval(-3600 * 5), read: false, kind: "系统"),
            AppMessage(title: "离线语音包已可用", body: "在语音设置中可模拟下载离线语音包，无网络时也能查看离线识别流程。", date: Date().addingTimeInterval(-3600 * 30), read: false, kind: "功能"),
            AppMessage(title: "隐私提示", body: "智能输入模式会按你的设置调用云服务；基础输入模式仅在本机处理输入。", date: Date().addingTimeInterval(-3600 * 72), read: true, kind: "隐私"),
            AppMessage(title: "键盘扩展启用指引", body: "设置 → 通用 → 键盘 → 键盘 → 添加新键盘 → 豆包输入法（iOS 复刻），然后在输入框长按地球键切换。", date: Date().addingTimeInterval(-3600 * 96), read: true, kind: "帮助")
        ]
    }
}

public struct FeedbackEntry: Codable, Identifiable, Equatable {
    public var id: UUID
    public var kind: String
    public var text: String
    public var contact: String
    public var date: Date

    public init(id: UUID = UUID(), kind: String, text: String, contact: String = "", date: Date = Date()) {
        self.id = id
        self.kind = kind
        self.text = text
        self.contact = contact
        self.date = date
    }
}

public struct DeviceRecord: Codable, Identifiable, Equatable {
    public var id: UUID
    public var name: String
    public var kind: String
    public var lastSeen: String

    public init(id: UUID = UUID(), name: String, kind: String, lastSeen: String) {
        self.id = id
        self.name = name
        self.kind = kind
        self.lastSeen = lastSeen
    }
}

public enum KeyboardKind: String, CaseIterable, Codable, Identifiable {
    case pinyin26
    case pinyin9
    case handwriting
    case stroke
    case shuangpin
    case wubi

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .pinyin26: return "拼音26键"
        case .pinyin9: return "拼音9键"
        case .handwriting: return "手写键盘"
        case .stroke: return "笔画键盘"
        case .shuangpin: return "双拼键盘"
        case .wubi: return "五笔键盘"
        }
    }

    public var shortTitle: String {
        switch self {
        case .pinyin26: return "26键"
        case .pinyin9: return "9键"
        case .handwriting: return "手写"
        case .stroke: return "笔画"
        case .shuangpin: return "双拼"
        case .wubi: return "五笔"
        }
    }

    public var symbol: String {
        switch self {
        case .pinyin26: return "keyboard"
        case .pinyin9: return "square.grid.3x3"
        case .handwriting: return "scribble"
        case .stroke: return "pencil.tip"
        case .shuangpin: return "rectangle.split.3x1"
        case .wubi: return "character.book.closed"
        }
    }
}

public enum FuzzyConfig {
    public static let initialOptions: [(String, String)] = [
        ("z", "zh"), ("c", "ch"), ("s", "sh"),
        ("f", "h"), ("n", "l"), ("r", "l")
    ]
    public static let finalOptions: [(String, String)] = [
        ("an", "ang"), ("en", "eng"), ("in", "ing"),
        ("ian", "iang"), ("uan", "uang"), ("un", "ong"),
        ("eng", "ong"), ("ie", "ei"), ("uo", "ou")
    ]
    public static let syllableOptions: [(String, String)] = [
        ("hui", "fei"), ("huang", "wang")
    ]
}
