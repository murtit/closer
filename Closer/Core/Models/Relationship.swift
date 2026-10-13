import Foundation

/// How the user relates to a person. Drives icon, colour and the reminder suggestions offered.
enum Relationship: Codable, Equatable, Hashable {
    case partner
    case family
    case friend
    /// Free text, e.g. "Arbeitskollege" or "Nachbarin".
    case other(String)

    /// The built-in choices shown in the picker (plus "Andere" for `.other`).
    static let builtIn: [Relationship] = [.partner, .family, .friend]

    var title: String {
        switch self {
        case .partner: "Partner:in"
        case .family:  "Familie"
        case .friend:  "Freunde"
        case .other(let label):
            label.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Andere" : label
        }
    }

    var emoji: String {
        switch self {
        case .partner: "❤️"
        case .family:  "🏡"
        case .friend:  "🤝"
        case .other:   "⭐"
        }
    }

    var isOther: Bool {
        if case .other = self { return true }
        return false
    }

    /// Sort order for grouping in lists.
    var sortIndex: Int {
        switch self {
        case .partner: 0
        case .family:  1
        case .friend:  2
        case .other:   3
        }
    }

    // MARK: - Suggestions

    /// Ready-made reminder ideas for this kind of relationship. The user picks which ones to keep
    /// and can edit title, emoji and schedule afterwards.
    var suggestions: [ReminderSuggestion] {
        switch self {
        case .partner:
            [
                ReminderSuggestion(title: "Blumen kaufen", emoji: "💐",
                                   schedule: .init(frequency: .monthly, hour: 17, dayOfMonth: 1)),
                ReminderSuggestion(title: "Spontanes Date planen", emoji: "🍷",
                                   schedule: .init(frequency: .weekly, hour: 12, weekday: 4)),
                ReminderSuggestion(title: "Ein Kompliment machen", emoji: "💬",
                                   schedule: .init(frequency: .daily, hour: 9)),
                ReminderSuggestion(title: "Sagen, was du an ihr/ihm liebst", emoji: "❤️",
                                   schedule: .init(frequency: .weekly, hour: 20, weekday: 1), isPreselected: false),
                ReminderSuggestion(title: "Ein altes gemeinsames Foto schicken", emoji: "📸",
                                   schedule: .init(frequency: .weekly, hour: 11, weekday: 6), isPreselected: false),
                ReminderSuggestion(title: "Eine liebe Nachricht senden", emoji: "💌",
                                   schedule: .init(frequency: .weekly, hour: 15, weekday: 3), isPreselected: false),
            ]
        case .family:
            [
                ReminderSuggestion(title: "Anrufen und fragen, wie es geht", emoji: "📞",
                                   schedule: .init(frequency: .weekly, hour: 18, weekday: 1)),
                ReminderSuggestion(title: "Vorbeischauen", emoji: "🏡",
                                   schedule: .init(frequency: .monthly, hour: 10, dayOfMonth: 15)),
                ReminderSuggestion(title: "Ein Foto schicken", emoji: "📸",
                                   schedule: .init(frequency: .weekly, hour: 19, weekday: 4), isPreselected: false),
                ReminderSuggestion(title: "Fragen, ob Hilfe gebraucht wird", emoji: "🤲",
                                   schedule: .init(frequency: .monthly, hour: 18, dayOfMonth: 1), isPreselected: false),
            ]
        case .friend:
            [
                ReminderSuggestion(title: "Melden und etwas abmachen", emoji: "👋",
                                   schedule: .once(in: 14)),
                ReminderSuggestion(title: "Fragen, wie es so läuft", emoji: "💬",
                                   schedule: .init(frequency: .monthly, hour: 19, dayOfMonth: 1), isPreselected: false),
                ReminderSuggestion(title: "Auf ein Bier oder einen Kaffee treffen", emoji: "🍻",
                                   schedule: .init(frequency: .monthly, hour: 17, dayOfMonth: 20), isPreselected: false),
            ]
        case .other:
            [
                ReminderSuggestion(title: "Melden und fragen, wie es geht", emoji: "👋",
                                   schedule: .init(frequency: .monthly, hour: 18, dayOfMonth: 1)),
                ReminderSuggestion(title: "Gemeinsam etwas unternehmen", emoji: "✨",
                                   schedule: .once(in: 14), isPreselected: false),
            ]
        }
    }
}

/// A template from which a `Reminder` is created.
struct ReminderSuggestion: Identifiable, Equatable {
    var id: String { title }
    let title: String
    let emoji: String
    let schedule: ReminderSchedule
    /// Whether the suggestion is ticked by default when adding a person.
    var isPreselected: Bool = true

    func makeReminder() -> Reminder {
        Reminder(title: title, emoji: emoji, isEnabled: true, schedule: schedule)
    }
}
