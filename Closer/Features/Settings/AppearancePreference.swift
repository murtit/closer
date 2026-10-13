import SwiftUI

/// Light, dark or follow the iPhone setting, chosen in the app's settings.
nonisolated enum AppearancePreference: String, CaseIterable, Identifiable {
    case system
    case light
    case dark

    /// `UserDefaults` / `@AppStorage` key.
    static let storageKey = "appearance"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .system: "Automatisch"
        case .light: "Hell"
        case .dark: "Dunkel"
        }
    }

    var systemImage: String {
        switch self {
        case .system: "circle.lefthalf.filled"
        case .light: "sun.max.fill"
        case .dark: "moon.fill"
        }
    }

    /// `nil` lets the app follow the system setting.
    var colorScheme: ColorScheme? {
        switch self {
        case .system: nil
        case .light: .light
        case .dark: .dark
        }
    }

    /// Reads a stored value; unknown or missing values fall back to `.system`.
    init(storedValue: String?) {
        self = storedValue.flatMap(Self.init(rawValue:)) ?? .system
    }
}
