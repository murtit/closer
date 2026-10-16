import Foundation

/// The three checks Closer shows for Apple Intelligence: does this iPhone support it, is it turned
/// on, and is the language model loaded.
struct AppleIntelligenceCheck: Identifiable, Equatable {
    enum State: Equatable {
        case passed
        case failed
        case inProgress
        /// An earlier check failed, so this one cannot be answered.
        case skipped
    }

    let title: String
    let state: State

    var id: String { title }
}

extension IdeaAvailability {
    /// One short word for the overall state, shown next to the checks.
    var statusTitle: String {
        switch self {
        case .available: "Bereit"
        case .notEnabled: "Ausgeschaltet"
        case .notReady: "Wird geladen"
        case .unsupported: "Nicht unterstützt"
        }
    }

    /// What the state means and what to do about it.
    var statusMessage: String {
        switch self {
        case .available:
            "Apple Intelligence ist eingeschaltet und das Sprachmodell ist geladen. Closer kann Ideen finden."
        case .notEnabled:
            "Dieses iPhone unterstützt Apple Intelligence, es ist aber ausgeschaltet. Schalte es in den Einstellungen unter „Apple Intelligence & Siri“ ein."
        case .notReady:
            "Apple Intelligence ist eingeschaltet, das Sprachmodell wird aber noch auf dein iPhone geladen. Am schnellsten geht es mit WLAN und am Strom. Den Fortschritt siehst du in den Einstellungen unter „Apple Intelligence & Siri“."
        case .unsupported:
            "Dieses iPhone unterstützt Apple Intelligence nicht, deshalb gibt es hier keine Ideen. Dafür braucht es zum Beispiel ein iPhone 15 Pro oder neuer."
        }
    }

    /// Supported, turned on, loaded: each check only counts once the one before it passed.
    var checks: [AppleIntelligenceCheck] {
        let supported: AppleIntelligenceCheck.State = self == .unsupported ? .failed : .passed
        let enabled: AppleIntelligenceCheck.State = switch self {
        case .available, .notReady: .passed
        case .notEnabled: .failed
        case .unsupported: .skipped
        }
        let loaded: AppleIntelligenceCheck.State = switch self {
        case .available: .passed
        case .notReady: .inProgress
        case .notEnabled, .unsupported: .skipped
        }
        return [
            AppleIntelligenceCheck(title: "Von diesem iPhone unterstützt", state: supported),
            AppleIntelligenceCheck(title: "Eingeschaltet", state: enabled),
            AppleIntelligenceCheck(title: "Sprachmodell geladen", state: loaded),
        ]
    }

    /// Whether a button to the Settings app helps: only when the user can change something there.
    var offersSettings: Bool {
        self == .notEnabled || self == .notReady
    }
}
