import SwiftUI

enum AppTheme {
    static let primary = Color(red: 79 / 255, green: 132 / 255, blue: 1.0)
    static let primaryPressed = Color(red: 48 / 255, green: 81 / 255, blue: 242 / 255)
    static let danger = Color(red: 1.0, green: 83 / 255, blue: 83 / 255)

    static let pageBg = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.055, green: 0.067, blue: 0.09, alpha: 1)
            : UIColor(red: 0.949, green: 0.969, blue: 1.0, alpha: 1)
    })
    static let card = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark ? UIColor(red: 0.11, green: 0.12, blue: 0.15, alpha: 1) : .white
    })
    static let cardAlt = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark ? UIColor(red: 0.16, green: 0.17, blue: 0.21, alpha: 1) : UIColor(red: 0.965, green: 0.975, blue: 0.99, alpha: 1)
    })
    static let text = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark ? .white : UIColor(red: 0.067, green: 0.067, blue: 0.067, alpha: 1)
    })
    static let textSecondary = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark ? UIColor(white: 0.68, alpha: 1) : UIColor(red: 0.4, green: 0.4, blue: 0.4, alpha: 1)
    })
    static let divider = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark ? UIColor(white: 1, alpha: 0.10) : UIColor(red: 0.1, green: 0.22, blue: 0.3, alpha: 0.1)
    })
    static let accentSoft = Color(red: 79 / 255, green: 132 / 255, blue: 1.0).opacity(0.12)
}

extension View {
    func cardStyle(padding: CGFloat = 16, radius: CGFloat = 18) -> some View {
        self
            .padding(padding)
            .background(AppTheme.card)
            .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
    }

    func pageBackground() -> some View {
        self.background(AppTheme.pageBg.ignoresSafeArea())
    }

    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

struct Card<Content: View>: View {
    var padding: CGFloat = 16
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(padding)
        .background(AppTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

struct SectionTitle: View {
    var title: String
    var icon: String?

    var body: some View {
        HStack(spacing: 6) {
            if let icon {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(AppTheme.text)
            }
            Text(title)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(AppTheme.text)
        }
        .padding(.top, 10)
        .padding(.bottom, 2)
    }
}

struct NavRow: View {
    var title: String
    var subtitle: String? = nil
    var value: String? = nil
    var icon: String? = nil
    var badge: String? = nil
    var isLast: Bool = false
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                if let icon {
                    Image(systemName: icon)
                        .font(.system(size: 17, weight: .medium))
                        .foregroundColor(AppTheme.primary)
                        .frame(width: 26)
                }
                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(AppTheme.text)
                    if let subtitle, !subtitle.isEmpty {
                        Text(subtitle)
                            .font(.system(size: 13))
                            .foregroundColor(AppTheme.textSecondary)
                            .lineLimit(2)
                    }
                }
                Spacer(minLength: 4)
                if let badge {
                    Text(badge)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(AppTheme.primary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(AppTheme.accentSoft)
                        .clipShape(Capsule())
                }
                if let value {
                    Text(value)
                        .font(.system(size: 14))
                        .foregroundColor(AppTheme.textSecondary)
                        .lineLimit(1)
                }
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(AppTheme.textSecondary.opacity(0.6))
            }
            .padding(.vertical, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(RowButtonStyle())
        .overlay(alignment: .bottom) {
            if !isLast {
                Rectangle().fill(AppTheme.divider).frame(height: 0.5).padding(.leading, icon == nil ? 0 : 38)
            }
        }
    }
}

struct ToggleRow: View {
    var title: String
    var subtitle: String? = nil
    @Binding var isOn: Bool
    var isLast: Bool = false
    var onChange: ((Bool) -> Void)? = nil

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(AppTheme.text)
                if let subtitle, !subtitle.isEmpty {
                    Text(subtitle)
                        .font(.system(size: 13))
                        .foregroundColor(AppTheme.textSecondary)
                        .lineLimit(2)
                }
            }
            Spacer(minLength: 8)
            Toggle("", isOn: $isOn)
                .labelsHidden()
                .tint(AppTheme.primary)
                .onChange(of: isOn) { newValue in
                    onChange?(newValue)
                }
        }
        .padding(.vertical, 11)
        .overlay(alignment: .bottom) {
            if !isLast {
                Rectangle().fill(AppTheme.divider).frame(height: 0.5)
            }
        }
    }
}

struct ActionRow: View {
    var title: String
    var subtitle: String? = nil
    var destructive: Bool = false
    var icon: String? = nil
    var isLast: Bool = false
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                if let icon {
                    Image(systemName: icon)
                        .font(.system(size: 16))
                        .foregroundColor(destructive ? AppTheme.danger : AppTheme.primary)
                        .frame(width: 24)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(destructive ? AppTheme.danger : AppTheme.text)
                    if let subtitle {
                        Text(subtitle)
                            .font(.system(size: 12))
                            .foregroundColor(AppTheme.textSecondary)
                    }
                }
                Spacer()
            }
            .padding(.vertical, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(RowButtonStyle())
        .overlay(alignment: .bottom) {
            if !isLast { Rectangle().fill(AppTheme.divider).frame(height: 0.5) }
        }
    }
}

struct RowButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(configuration.isPressed ? AppTheme.primary.opacity(0.06) : Color.clear)
    }
}

struct PrimaryButton: View {
    var title: String
    var icon: String? = nil
    var enabled: Bool = true
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if let icon { Image(systemName: icon) }
                Text(title)
            }
            .font(.system(size: 16, weight: .semibold))
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 48)
            .background(enabled ? AppTheme.primary : AppTheme.primary.opacity(0.35))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(ScaleButtonStyle())
        .disabled(!enabled)
    }
}

struct SecondaryButton: View {
    var title: String
    var icon: String? = nil
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if let icon { Image(systemName: icon) }
                Text(title)
            }
            .font(.system(size: 15, weight: .medium))
            .foregroundColor(AppTheme.primary)
            .frame(maxWidth: .infinity)
            .frame(height: 44)
            .background(AppTheme.accentSoft)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .opacity(configuration.isPressed ? 0.9 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

struct ChoiceChip: View {
    var title: String
    var selected: Bool
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: selected ? .semibold : .regular))
                .foregroundColor(selected ? AppTheme.primary : AppTheme.text)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(selected ? AppTheme.primary.opacity(0.12) : AppTheme.card)
                .overlay(
                    RoundedRectangle(cornerRadius: 999)
                        .stroke(selected ? AppTheme.primary : AppTheme.divider, lineWidth: selected ? 1 : 0.5)
                )
                .clipShape(Capsule())
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

struct RadioCircle: View {
    var selected: Bool

    var body: some View {
        ZStack {
            Circle()
                .stroke(selected ? AppTheme.primary : AppTheme.textSecondary.opacity(0.5), lineWidth: selected ? 2 : 1)
                .frame(width: 20, height: 20)
            if selected {
                Circle().fill(AppTheme.primary).frame(width: 10, height: 10)
            }
        }
    }
}

struct OptionRow: View {
    var title: String
    var subtitle: String? = nil
    var selected: Bool
    var isLast: Bool = false
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 15))
                        .foregroundColor(AppTheme.text)
                    if let subtitle {
                        Text(subtitle).font(.system(size: 12)).foregroundColor(AppTheme.textSecondary)
                    }
                }
                Spacer()
                RadioCircle(selected: selected)
            }
            .padding(.vertical, 11)
            .contentShape(Rectangle())
        }
        .buttonStyle(RowButtonStyle())
        .overlay(alignment: .bottom) {
            if !isLast { Rectangle().fill(AppTheme.divider).frame(height: 0.5) }
        }
    }
}

struct EmptyStateView: View {
    var icon: String
    var title: String
    var message: String

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 34))
                .foregroundColor(AppTheme.textSecondary.opacity(0.5))
            Text(title).font(.system(size: 16, weight: .medium)).foregroundColor(AppTheme.text)
            Text(message)
                .font(.system(size: 13))
                .foregroundColor(AppTheme.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 36)
    }
}

// MARK: - Toasts

final class ToastCenter: ObservableObject {
    static let shared = ToastCenter()
    @Published var message: String?
    private var token = UUID()

    func show(_ text: String) {
        let newToken = UUID()
        token = newToken
        message = text
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) { [weak self] in
            guard let self, self.token == newToken else { return }
            withAnimation(.easeOut(duration: 0.2)) { self.message = nil }
        }
    }
}

struct ToastOverlay: View {
    @ObservedObject var center = ToastCenter.shared

    var body: some View {
        VStack {
            if let message = center.message {
                Text(message)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 9)
                    .background(Color.black.opacity(0.82))
                    .clipShape(Capsule())
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .padding(.top, 8)
            }
            Spacer()
        }
        .animation(.easeOut(duration: 0.2), value: center.message)
        .allowsHitTesting(false)
    }
}

func showToast(_ message: String) {
    ToastCenter.shared.show(message)
}
