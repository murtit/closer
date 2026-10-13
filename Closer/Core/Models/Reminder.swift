import Foundation

struct Reminder: Identifiable, Codable, Equatable {
    var id: UUID
    var title: String
    var emoji: String
    var isEnabled: Bool
    var time: Date
    var isCustom: Bool

    init(
        id: UUID = UUID(),
        title: String,
        emoji: String,
        isEnabled: Bool = false,
        time: Date = Self.noon(),
        isCustom: Bool = false
    ) {
        self.id = id
        self.title = title
        self.emoji = emoji
        self.isEnabled = isEnabled
        self.time = time
        self.isCustom = isCustom
    }

    // MARK: - Predefined gestures

    static let predefined: [Reminder] = [
        Reminder(title: "Ein Kompliment machen",
                 emoji: "💬", time: hour(9)),
        Reminder(title: "Blumen kaufen",
                 emoji: "🌸", time: hour(10)),
        Reminder(title: "Ein altes gemeinsames Foto schicken",
                 emoji: "📸", time: hour(11)),
        Reminder(title: "Ich musste gerade an dich denken",
                 emoji: "💭", time: hour(12)),
        Reminder(title: "Sagen, warum du sie liebst",
                 emoji: "❤️", time: hour(14)),
        Reminder(title: "Eine liebe Nachricht senden",
                 emoji: "💌", time: hour(16)),
        Reminder(title: "Gemeinsam etwas unternehmen",
                 emoji: "✨", time: hour(18)),
    ]

    // MARK: - Helpers

    private static func hour(_ h: Int) -> Date {
        Calendar.current.date(bySettingHour: h, minute: 0, second: 0, of: Date()) ?? Date()
    }

    private static func noon() -> Date {
        Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: Date()) ?? Date()
    }
}
