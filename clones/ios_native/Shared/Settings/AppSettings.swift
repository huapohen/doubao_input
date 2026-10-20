import SwiftUI
import Foundation
import Combine
import UIKit

/// UserDefaults backed store shared by the SwiftUI app and the keyboard extension.
/// The App Group container is used when available; otherwise both processes fall back
/// to their own standard defaults (the keyboard then uses its bundled defaults).
enum SharedStore {
    static let appGroupID = "group.com.huapohen.doubaoinput"

    static var defaults: UserDefaults {
        UserDefaults(suiteName: appGroupID) ?? .standard
    }

    static func data<T: Decodable>(_ type: T.Type, forKey key: String, fallback: T) -> T {
        guard let data = defaults.data(forKey: key),
              let value = try? JSONDecoder().decode(T.self, from: data) else { return fallback }
        return value
    }

    static func save<T: Encodable>(_ value: T, forKey key: String) {
        if let data = try? JSONEncoder().encode(value) {
            defaults.set(data, forKey: key)
            defaults.synchronize()
        }
    }

    static func stringArray(_ key: String) -> [String] {
        defaults.stringArray(forKey: key) ?? []
    }
}

/// The single source of truth for user settings. Every mutation writes through to the
/// shared defaults immediately; SwiftUI observes the @Published properties.
final class AppSettings: ObservableObject {
    static let shared = AppSettings()

    let defaults: UserDefaults

    // MARK: Onboarding / identity
    @Published var onboardingDone: Bool { didSet { defaults.set(onboardingDone, forKey: "onboarding_done") } }
    @Published var privacyAccepted: Bool { didSet { defaults.set(privacyAccepted, forKey: "privacy_accepted") } }
    @Published var privacyMode: String { didSet { defaults.set(privacyMode, forKey: "privacy_mode") } }
    @Published var keyboardType: KeyboardKind { didSet { defaults.set(keyboardType.rawValue, forKey: "keyboard_type") } }
    @Published var keyboardTypePicked: Bool { didSet { defaults.set(keyboardTypePicked, forKey: "keyboard_type_picked") } }

    // MARK: Appearance / layout
    @Published var themeMode: String { didSet { defaults.set(themeMode, forKey: "theme_mode") } }
    @Published var candidateFontSize: Double { didSet { defaults.set(candidateFontSize, forKey: "candidate_font_size") } }
    @Published var pinyinLocation: String { didSet { defaults.set(pinyinLocation, forKey: "pinyin_location") } }
    @Published var numberSymbolCombined: Bool { didSet { defaults.set(numberSymbolCombined, forKey: "layout_number_symbol_combined") } }
    @Published var commaPeriodSeparate: Bool { didSet { defaults.set(commaPeriodSeparate, forKey: "layout_comma_period_separate") } }
    @Published var cnEnPosition: String { didSet { defaults.set(cnEnPosition, forKey: "layout_cnen_position") } }
    @Published var swipeNumberSymbols: Bool { didSet { defaults.set(swipeNumberSymbols, forKey: "layout_swipe_number_symbols") } }
    @Published var sideSymbols: [String] { didSet { SharedStore.save(sideSymbols, forKey: "layout_side_symbols") } }
    @Published var enterSend: Bool { didSet { defaults.set(enterSend, forKey: "enter_send") } }
    @Published var keyboardHeight: Double { didSet { defaults.set(keyboardHeight, forKey: "keyboard_height") } }
    @Published var oneHand: String { didSet { defaults.set(oneHand, forKey: "one_hand") } }
    @Published var floating: Bool { didSet { defaults.set(floating, forKey: "floating") } }

    // MARK: Input engine
    @Published var inputMode: String { didSet { defaults.set(inputMode, forKey: "input_mode") } }
    @Published var fuzzyEnabled: Bool { didSet { defaults.set(fuzzyEnabled, forKey: "fuzzy_enabled") } }
    @Published var fuzzyInitials: [String] { didSet { SharedStore.save(fuzzyInitials, forKey: "fuzzy_initials") } }
    @Published var fuzzyFinals: [String] { didSet { SharedStore.save(fuzzyFinals, forKey: "fuzzy_finals") } }
    @Published var fuzzySyllables: [String] { didSet { SharedStore.save(fuzzySyllables, forKey: "fuzzy_syllables") } }
    @Published var associationEnabled: Bool { didSet { defaults.set(associationEnabled, forKey: "association_enabled") } }
    @Published var predictionEmoji: Bool { didSet { defaults.set(predictionEmoji, forKey: "prediction_emoji") } }
    @Published var predictionImage: Bool { didSet { defaults.set(predictionImage, forKey: "prediction_image") } }
    @Published var predictionKaomoji: Bool { didSet { defaults.set(predictionKaomoji, forKey: "prediction_kaomoji") } }
    @Published var keySound: Bool { didSet { defaults.set(keySound, forKey: "key_sound") } }
    @Published var keyVibrate: Bool { didSet { defaults.set(keyVibrate, forKey: "key_vibrate") } }
    @Published var keyVibrateLevel: Double { didSet { defaults.set(keyVibrateLevel, forKey: "key_vibrate_level") } }
    @Published var keyVolume: Double { didSet { defaults.set(keyVolume, forKey: "key_volume") } }
    @Published var keyBubble: Bool { didSet { defaults.set(keyBubble, forKey: "key_bubble") } }
    @Published var keyResponse: String { didSet { defaults.set(keyResponse, forKey: "key_response") } }
    @Published var quickSpace: Bool { didSet { defaults.set(quickSpace, forKey: "quick_space") } }
    @Published var quickCapitalize: Bool { didSet { defaults.set(quickCapitalize, forKey: "quick_capitalize") } }
    @Published var quickDoubleSpacePeriod: Bool { didSet { defaults.set(quickDoubleSpacePeriod, forKey: "quick_double_space_period") } }
    @Published var doublePinyinScheme: String { didSet { defaults.set(doublePinyinScheme, forKey: "double_pinyin_scheme") } }
    @Published var wubiHint: Bool { didSet { defaults.set(wubiHint, forKey: "wubi_hint") } }
    @Published var wubiMixed: Bool { didSet { defaults.set(wubiMixed, forKey: "wubi_mixed") } }
    @Published var wubiFourUnique: Bool { didSet { defaults.set(wubiFourUnique, forKey: "wubi_four_unique") } }
    @Published var wubiFifthFirst: Bool { didSet { defaults.set(wubiFifthFirst, forKey: "wubi_fifth_first") } }

    // MARK: Voice
    @Published var voiceSmartOrganize: Bool { didSet { defaults.set(voiceSmartOrganize, forKey: "voice_smart_organize") } }
    @Published var voiceParagraphBlank: Bool { didSet { defaults.set(voiceParagraphBlank, forKey: "voice_paragraph_blank") } }
    @Published var voicePunctuationStyle: String { didSet { defaults.set(voicePunctuationStyle, forKey: "voice_punctuation") } }
    @Published var voiceFiller: String { didSet { defaults.set(voiceFiller, forKey: "voice_filler") } }
    @Published var voiceOffline: Bool { didSet { defaults.set(voiceOffline, forKey: "voice_offline") } }
    @Published var voiceOfflineProgress: Double { didSet { defaults.set(voiceOfflineProgress, forKey: "voice_offline_progress") } }
    @Published var voiceEarphone: Bool { didSet { defaults.set(voiceEarphone, forKey: "voice_earphone") } }
    @Published var voiceWeakNetwork: Bool { didSet { defaults.set(voiceWeakNetwork, forKey: "voice_weak_network") } }
    @Published var voiceActionEnabled: Bool { didSet { defaults.set(voiceActionEnabled, forKey: "voice_action_enabled") } }
    @Published var voiceActions: [String] { didSet { SharedStore.save(voiceActions, forKey: "voice_actions") } }
    @Published var customVoiceActions: [String] { didSet { SharedStore.save(customVoiceActions, forKey: "voice_custom_actions") } }

    // MARK: Tools
    @Published var superTransferEnabled: Bool { didSet { defaults.set(superTransferEnabled, forKey: "super_transfer_enabled") } }
    @Published var clipboardCandidate: Bool { didSet { defaults.set(clipboardCandidate, forKey: "clipboard_candidate") } }
    @Published var clipboardHistory: Bool { didSet { defaults.set(clipboardHistory, forKey: "clipboard_history") } }
    @Published var clipboardItems: [ClipboardItem] { didSet { SharedStore.save(clipboardItems, forKey: "clipboard_items") } }
    @Published var verificationFill: Bool { didSet { defaults.set(verificationFill, forKey: "verification_fill") } }
    @Published var contactsImport: Bool { didSet { defaults.set(contactsImport, forKey: "contacts_import") } }
    @Published var auxiliaryInput: Bool { didSet { defaults.set(auxiliaryInput, forKey: "auxiliary_input") } }
    @Published var personalLexicon: [LexiconEntry] { didSet { SharedStore.save(personalLexicon, forKey: "personal_lexicon") } }
    @Published var commonPhrases: [Phrase] { didSet { SharedStore.save(commonPhrases, forKey: "common_phrases") } }
    @Published var customToolbar: [String] { didSet { SharedStore.save(customToolbar, forKey: "custom_toolbar") } }

    // MARK: Privacy / smart input
    @Published var smartCloudInput: Bool { didSet { defaults.set(smartCloudInput, forKey: "smart_cloud_input") } }
    @Published var smartCloudLexicon: Bool { didSet { defaults.set(smartCloudLexicon, forKey: "smart_cloud_lexicon") } }
    @Published var feedbackEnabled: Bool { didSet { defaults.set(feedbackEnabled, forKey: "experience_program") } }

    // MARK: AI
    @Published var aiBaseURL: String { didSet { defaults.set(aiBaseURL, forKey: "ai_base_url") } }
    @Published var aiModel: String { didSet { defaults.set(aiModel, forKey: "ai_model") } }
    @Published var aiKeyPresent: Bool

    // MARK: Account / transfers
    @Published var accountLoggedIn: Bool { didSet { defaults.set(accountLoggedIn, forKey: "account_logged_in") } }
    @Published var accountName: String { didSet { defaults.set(accountName, forKey: "account_name") } }
    @Published var syncSettings: Bool { didSet { defaults.set(syncSettings, forKey: "sync_settings") } }
    @Published var syncLexicon: Bool { didSet { defaults.set(syncLexicon, forKey: "sync_lexicon") } }
    @Published var syncPhrases: Bool { didSet { defaults.set(syncPhrases, forKey: "sync_phrases") } }
    @Published var messages: [AppMessage] { didSet { SharedStore.save(messages, forKey: "app_messages") } }
    @Published var devices: [DeviceRecord] { didSet { SharedStore.save(devices, forKey: "transfer_devices") } }
    @Published var feedbacks: [FeedbackEntry] { didSet { SharedStore.save(feedbacks, forKey: "feedback_entries") } }

    // MARK: Lifecycle
    private init() {
        let d = SharedStore.defaults
        defaults = d

        // Debug/screenshot launch flag: start from a clean install.
        if ProcessInfo.processInfo.arguments.contains("-reset") {
            if let bundleID = Bundle.main.bundleIdentifier {
                UserDefaults.standard.removePersistentDomain(forName: bundleID)
                d.removePersistentDomain(forName: bundleID)
            }
            d.removePersistentDomain(forName: SharedStore.appGroupID)
            d.synchronize()
        }

        onboardingDone = d.bool(forKey: "onboarding_done")
        privacyAccepted = d.bool(forKey: "privacy_accepted")
        privacyMode = d.string(forKey: "privacy_mode") ?? "smart"
        keyboardType = KeyboardKind(rawValue: d.string(forKey: "keyboard_type") ?? "") ?? .pinyin26
        keyboardTypePicked = d.bool(forKey: "keyboard_type_picked")

        themeMode = d.string(forKey: "theme_mode") ?? "system"
        candidateFontSize = d.object(forKey: "candidate_font_size") as? Double ?? 22
        pinyinLocation = d.string(forKey: "pinyin_location") ?? "candidate"
        numberSymbolCombined = d.object(forKey: "layout_number_symbol_combined") as? Bool ?? true
        commaPeriodSeparate = d.object(forKey: "layout_comma_period_separate") as? Bool ?? false
        cnEnPosition = d.string(forKey: "layout_cnen_position") ?? "left"
        swipeNumberSymbols = d.object(forKey: "layout_swipe_number_symbols") as? Bool ?? true
        sideSymbols = SharedStore.stringArray("layout_side_symbols").isEmpty ? ["，", "。", "？", "！"] : SharedStore.stringArray("layout_side_symbols")
        enterSend = d.object(forKey: "enter_send") as? Bool ?? false
        keyboardHeight = d.object(forKey: "keyboard_height") as? Double ?? 300
        oneHand = d.string(forKey: "one_hand") ?? "off"
        floating = d.bool(forKey: "floating")

        inputMode = d.string(forKey: "input_mode") ?? "smart"
        fuzzyEnabled = d.bool(forKey: "fuzzy_enabled")
        fuzzyInitials = SharedStore.stringArray("fuzzy_initials")
        fuzzyFinals = SharedStore.stringArray("fuzzy_finals")
        fuzzySyllables = SharedStore.stringArray("fuzzy_syllables")
        associationEnabled = d.object(forKey: "association_enabled") as? Bool ?? true
        predictionEmoji = d.object(forKey: "prediction_emoji") as? Bool ?? true
        predictionImage = d.object(forKey: "prediction_image") as? Bool ?? true
        predictionKaomoji = d.object(forKey: "prediction_kaomoji") as? Bool ?? true
        keySound = d.object(forKey: "key_sound") as? Bool ?? true
        keyVibrate = d.object(forKey: "key_vibrate") as? Bool ?? true
        keyVibrateLevel = d.object(forKey: "key_vibrate_level") as? Double ?? 0.6
        keyVolume = d.object(forKey: "key_volume") as? Double ?? 0.7
        keyBubble = d.object(forKey: "key_bubble") as? Bool ?? true
        keyResponse = d.string(forKey: "key_response") ?? "follow"
        quickSpace = d.object(forKey: "quick_space") as? Bool ?? true
        quickCapitalize = d.object(forKey: "quick_capitalize") as? Bool ?? true
        quickDoubleSpacePeriod = d.object(forKey: "quick_double_space_period") as? Bool ?? true
        doublePinyinScheme = d.string(forKey: "double_pinyin_scheme") ?? "xiaohe"
        wubiHint = d.object(forKey: "wubi_hint") as? Bool ?? true
        wubiMixed = d.object(forKey: "wubi_mixed") as? Bool ?? true
        wubiFourUnique = d.object(forKey: "wubi_four_unique") as? Bool ?? false
        wubiFifthFirst = d.object(forKey: "wubi_fifth_first") as? Bool ?? false

        voiceSmartOrganize = d.object(forKey: "voice_smart_organize") as? Bool ?? true
        voiceParagraphBlank = d.object(forKey: "voice_paragraph_blank") as? Bool ?? false
        voicePunctuationStyle = d.string(forKey: "voice_punctuation") ?? "smart"
        voiceFiller = d.string(forKey: "voice_filler") ?? "normal"
        voiceOffline = d.bool(forKey: "voice_offline")
        voiceOfflineProgress = d.object(forKey: "voice_offline_progress") as? Double ?? 0
        voiceEarphone = d.object(forKey: "voice_earphone") as? Bool ?? true
        voiceWeakNetwork = d.object(forKey: "voice_weak_network") as? Bool ?? true
        voiceActionEnabled = d.object(forKey: "voice_action_enabled") as? Bool ?? true
        voiceActions = SharedStore.stringArray("voice_actions").isEmpty ? ["帮我发送", "我说完了", "立即发送", "发送发送", "overover"] : SharedStore.stringArray("voice_actions")
        customVoiceActions = SharedStore.stringArray("voice_custom_actions")

        superTransferEnabled = d.bool(forKey: "super_transfer_enabled")
        clipboardCandidate = d.object(forKey: "clipboard_candidate") as? Bool ?? true
        clipboardHistory = d.object(forKey: "clipboard_history") as? Bool ?? true
        clipboardItems = SharedStore.data([ClipboardItem].self, forKey: "clipboard_items", fallback: [])
        verificationFill = d.object(forKey: "verification_fill") as? Bool ?? false
        contactsImport = d.object(forKey: "contacts_import") as? Bool ?? false
        auxiliaryInput = d.object(forKey: "auxiliary_input") as? Bool ?? true
        personalLexicon = SharedStore.data([LexiconEntry].self, forKey: "personal_lexicon", fallback: [])
        commonPhrases = SharedStore.data([Phrase].self, forKey: "common_phrases", fallback: [
            Phrase(text: "收到，谢谢！", category: "工作"),
            Phrase(text: "稍等，我看一下", category: "工作"),
            Phrase(text: "好的，没问题", category: "通用"),
            Phrase(text: "我马上到", category: "生活"),
            Phrase(text: "新年快乐，万事顺意", category: "祝福")
        ])
        customToolbar = SharedStore.stringArray("custom_toolbar").isEmpty ? ["voice", "clipboard", "emoji", "phrases", "switch", "onehand", "height", "dismiss"] : SharedStore.stringArray("custom_toolbar")

        smartCloudInput = d.object(forKey: "smart_cloud_input") as? Bool ?? true
        smartCloudLexicon = d.object(forKey: "smart_cloud_lexicon") as? Bool ?? true
        feedbackEnabled = d.object(forKey: "experience_program") as? Bool ?? true

        aiBaseURL = d.string(forKey: "ai_base_url") ?? "https://api.deepseek.com"
        aiModel = d.string(forKey: "ai_model") ?? "deepseek-chat"
        aiKeyPresent = KeychainStore.read() != nil

        accountLoggedIn = d.bool(forKey: "account_logged_in")
        accountName = d.string(forKey: "account_name") ?? ""
        syncSettings = d.object(forKey: "sync_settings") as? Bool ?? true
        syncLexicon = d.object(forKey: "sync_lexicon") as? Bool ?? true
        syncPhrases = d.object(forKey: "sync_phrases") as? Bool ?? true
        messages = SharedStore.data([AppMessage].self, forKey: "app_messages", fallback: AppMessage.samples)
        devices = SharedStore.data([DeviceRecord].self, forKey: "transfer_devices", fallback: [])
        feedbacks = SharedStore.data([FeedbackEntry].self, forKey: "feedback_entries", fallback: [])

        // Screenshot/demo overrides passed as launch arguments. These are not persisted
        // because property observers do not run during initialization.
        let launch = UserDefaults.standard
        if let raw = launch.string(forKey: "kbType"), let kind = KeyboardKind(rawValue: raw) {
            keyboardType = kind
            keyboardTypePicked = true
        }
        if let theme = launch.string(forKey: "theme"), ["light", "dark", "system"].contains(theme) {
            themeMode = theme
        }
        if let hand = launch.string(forKey: "oneHand"), ["off", "left", "right"].contains(hand) {
            oneHand = hand
        }
    }

    // MARK: - Helpers

    func binding<T>(_ keyPath: ReferenceWritableKeyPath<AppSettings, T>) -> Binding<T> {
        Binding<T>(
            get: { self[keyPath: keyPath] },
            set: { self[keyPath: keyPath] = $0 }
        )
    }

    var isSmartMode: Bool { privacyMode == "smart" && inputMode == "smart" }

    func completeOnboarding() {
        onboardingDone = true
        defaults.set(true, forKey: "onboarding_done")
    }

    // MARK: Clipboard
    func captureClipboard() {
        guard clipboardHistory else { return }
        let pasteboard = UIPasteboard.general
        guard let text = pasteboard.string, !text.isEmpty else { return }
        addClipboard(text)
    }

    func addClipboard(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        var items = clipboardItems.filter { $0.text != trimmed }
        items.insert(ClipboardItem(text: trimmed), at: 0)
        if items.count > 50 { items = Array(items.prefix(50)) }
        clipboardItems = items
        UIPasteboard.general.string = text
    }

    func deleteClipboard(_ item: ClipboardItem) {
        clipboardItems.removeAll { $0.id == item.id }
    }

    func clearClipboard() {
        clipboardItems = []
    }

    // MARK: Lexicon
    func addLexicon(word: String, pinyin: String) {
        let w = word.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !w.isEmpty else { return }
        if let idx = personalLexicon.firstIndex(where: { $0.word == w }) {
            personalLexicon[idx].pinyin = pinyin
        } else {
            personalLexicon.insert(LexiconEntry(word: w, pinyin: pinyin), at: 0)
        }
    }

    func deleteLexicon(_ entry: LexiconEntry) {
        personalLexicon.removeAll { $0.id == entry.id }
    }

    // MARK: Phrases
    func addPhrase(text: String, category: String) {
        let t = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !t.isEmpty else { return }
        commonPhrases.insert(Phrase(text: t, category: category), at: 0)
    }

    func deletePhrase(_ phrase: Phrase) {
        commonPhrases.removeAll { $0.id == phrase.id }
    }

    func usePhrase(_ phrase: Phrase) {
        if let idx = commonPhrases.firstIndex(where: { $0.id == phrase.id }) {
            commonPhrases[idx].useCount += 1
        }
    }

    // MARK: Voice actions
    func addVoiceAction(_ text: String) {
        let t = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !t.isEmpty, !customVoiceActions.contains(t) else { return }
        customVoiceActions.append(t)
    }

    func removeVoiceAction(_ text: String) {
        customVoiceActions.removeAll { $0 == text }
    }

    // MARK: Messages
    func markMessageRead(_ message: AppMessage) {
        if let idx = messages.firstIndex(where: { $0.id == message.id }) {
            messages[idx].read = true
        }
    }

    func deleteMessage(_ message: AppMessage) {
        messages.removeAll { $0.id == message.id }
    }

    var unreadMessageCount: Int { messages.filter { !$0.read }.count }

    // MARK: Devices
    func addDevice(_ name: String, kind: String) {
        devices.append(DeviceRecord(name: name, kind: kind, lastSeen: "刚刚"))
    }

    // MARK: Account
    func signIn(name: String) {
        accountLoggedIn = true
        accountName = name.isEmpty ? "豆包用户" : name
    }

    func signOut() {
        accountLoggedIn = false
        accountName = ""
        superTransferEnabled = false
    }
}


