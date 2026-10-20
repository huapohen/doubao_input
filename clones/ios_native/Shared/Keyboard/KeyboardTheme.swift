import UIKit

struct KeyboardTheme {
    let background: UIColor
    let key: UIColor
    let keyPressed: UIColor
    let keyFunction: UIColor
    let keyFunctionPressed: UIColor
    let text: UIColor
    let secondaryText: UIColor
    let accent: UIColor
    let divider: UIColor
    let panel: UIColor

    static func current(dark: Bool) -> KeyboardTheme {
        if dark {
            return KeyboardTheme(
                background: UIColor(red: 0.10, green: 0.11, blue: 0.13, alpha: 1),
                key: UIColor(red: 0.27, green: 0.28, blue: 0.31, alpha: 1),
                keyPressed: UIColor(red: 0.40, green: 0.42, blue: 0.46, alpha: 1),
                keyFunction: UIColor(red: 0.17, green: 0.18, blue: 0.21, alpha: 1),
                keyFunctionPressed: UIColor(red: 0.28, green: 0.30, blue: 0.34, alpha: 1),
                text: .white,
                secondaryText: UIColor(white: 0.72, alpha: 1),
                accent: UIColor(red: 0.34, green: 0.55, blue: 1.0, alpha: 1),
                divider: UIColor(white: 1, alpha: 0.10),
                panel: UIColor(red: 0.15, green: 0.16, blue: 0.19, alpha: 1)
            )
        }
        return KeyboardTheme(
            background: UIColor(red: 0.92, green: 0.92, blue: 0.93, alpha: 1),
            key: .white,
            keyPressed: UIColor(red: 0.84, green: 0.86, blue: 0.89, alpha: 1),
            keyFunction: UIColor(red: 0.74, green: 0.76, blue: 0.78, alpha: 1),
            keyFunctionPressed: UIColor(red: 0.66, green: 0.68, blue: 0.71, alpha: 1),
            text: UIColor(red: 0.07, green: 0.07, blue: 0.07, alpha: 1),
            secondaryText: UIColor(red: 0.40, green: 0.40, blue: 0.40, alpha: 1),
            accent: UIColor(red: 0.31, green: 0.52, blue: 1.0, alpha: 1),
            divider: UIColor(white: 0, alpha: 0.08),
            panel: .white
        )
    }

    static func resolvedDark(themeMode: String, traits: UITraitCollection) -> Bool {
        switch themeMode {
        case "light": return false
        case "dark": return true
        default: return traits.userInterfaceStyle == .dark
        }
    }
}

enum KeyboardMetrics {
    static let toolbarHeight: CGFloat = 40
    static let candidateHeight: CGFloat = 46
    static let gap: CGFloat = 5
    static let sideInset: CGFloat = 4
    static let maxWidth: CGFloat = 960
    static let corner: CGFloat = 8

    static func preferredHeight(idiom: UIUserInterfaceIdiom, landscape: Bool, stored: Double) -> CGFloat {
        if idiom == .pad { return max(320, min(420, CGFloat(stored) + 60)) }
        let base = CGFloat(stored)
        if landscape { return max(230, min(300, base - 40)) }
        return max(255, min(360, base))
    }
}
