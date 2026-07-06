import SwiftUI

/// Ghosted's identity: cool slate-navy backdrop with an electric-violet
/// accent and a cyan "still there" signal, evoking texts fading into the
/// void. Distinct from every sibling app's palette.
enum GHTheme {
    static let backdrop = Color(red: 0.071, green: 0.078, blue: 0.114)   // slate-navy
    static let surface = Color(red: 0.110, green: 0.118, blue: 0.161)
    static let surfaceRaised = Color(red: 0.153, green: 0.161, blue: 0.212)
    static let ink = Color(red: 0.941, green: 0.937, blue: 0.965)
    static let inkFaded = Color(red: 0.941, green: 0.937, blue: 0.965).opacity(0.58)
    static let rule = Color.white.opacity(0.09)

    static let violet = Color(red: 0.573, green: 0.408, blue: 0.933)
    static let violetBright = Color(red: 0.671, green: 0.514, blue: 0.973)
    static let cyan = Color(red: 0.286, green: 0.827, blue: 0.816)
    static let danger = Color(red: 0.882, green: 0.365, blue: 0.427)

    static let titleFont = Font.system(.title2, design: .rounded).weight(.bold)
    static let headlineFont = Font.system(.headline, design: .rounded).weight(.semibold)
    static let displayFont = Font.system(size: 44, weight: .bold, design: .rounded).monospacedDigit()
}

struct DismissKeyboardOnTap: ViewModifier {
    func body(content: Content) -> some View {
        content.simultaneousGesture(
            TapGesture().onEnded {
                UIApplication.shared.sendAction(
                    #selector(UIResponder.resignFirstResponder),
                    to: nil, from: nil, for: nil
                )
            }
        )
    }
}

extension View {
    func dismissKeyboardOnTap() -> some View {
        modifier(DismissKeyboardOnTap())
    }
}

enum Haptics {
    static var enabled: Bool = true

    static func light() {
        guard enabled else { return }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    static func medium() {
        guard enabled else { return }
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }

    static func success() {
        guard enabled else { return }
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    static func warning() {
        guard enabled else { return }
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
    }
}
