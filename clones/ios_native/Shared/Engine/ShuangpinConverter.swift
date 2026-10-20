import Foundation

/// Double-pinyin key conversion for the two schemes shown in the original UI.
/// Coverage is deliberately demo-grade: unknown pairs fall back to the raw letters so
/// the keyboard remains usable instead of silently dropping input.
enum ShuangpinConverter {
    // Xiaohe (小鹤双拼) final key mapping.
    private static let xiaohe: [Character: String] = [
        "a": "a", "o": "o", "e": "e", "i": "i", "u": "u", "v": "v",
        "d": "ai", "w": "ei", "c": "ao", "z": "ou",
        "j": "an", "f": "en", "b": "in", "y": "un",
        "h": "ang", "g": "eng", "k": "ing", "s": "ong",
        "x": "ia", "n": "iao", "p": "ie", "q": "iu", "m": "ian",
        "l": "iang", "r": "uan", "t": "ue"
    ]

    // Natural code (自然码) final mapping.
    private static let natural: [Character: String] = [
        "a": "a", "o": "o", "e": "e", "i": "i", "u": "u", "v": "v",
        "l": "ai", "z": "ei", "c": "ao", "s": "ou",
        "j": "an", "f": "en", "b": "in", "y": "un",
        "h": "ang", "g": "eng", "k": "ing", "d": "ong",
        "x": "ia", "n": "iao", "p": "ie", "q": "iu", "m": "ian",
        "t": "ue", "r": "uan", "w": "ua"
    ]

    private static let zeroInitialFinals: [Character: String] = [
        "a": "a", "o": "o", "e": "e", "i": "i", "u": "u", "v": "v"
    ]

    static func convert(_ keys: String, scheme: String) -> String {
        let map = scheme == "natural" ? natural : xiaohe
        let chars = Array(keys.lowercased().filter { $0.isLetter })
        guard !chars.isEmpty else { return "" }
        var syllables: [String] = []
        var i = 0
        while i < chars.count {
            let first = chars[i]
            if "aoe".contains(first) {
                // Zero-initial syllable: one key is the whole final.
                if i + 1 < chars.count, let final = map[chars[i + 1]], first == "a" || first == "o" || first == "e" {
                    // "ah" => ang, "aj" => an etc. Prefer two-key finals.
                    if first == "a" && ["h", "j", "i", "o", "n"].contains(chars[i + 1]) {
                        syllables.append(String(first) + final)
                        i += 2
                        continue
                    }
                }
                syllables.append(String(first))
                i += 1
                continue
            }
            if i + 1 < chars.count, let final = map[chars[i + 1]] {
                syllables.append(String(first) + final)
                i += 2
            } else {
                syllables.append(String(first))
                i += 1
            }
        }
        return syllables.joined()
    }
}
