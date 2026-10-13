import Foundation

/// A recurring (or one-off) nudge to do something for a specific person.
struct Reminder: Identifiable, Codable, Equatable, Hashable {
    var id: UUID
    var title: String
    var emoji: String
    var isEnabled: Bool
    var schedule: ReminderSchedule

    init(
        id: UUID = UUID(),
        title: String,
        emoji: String,
        isEnabled: Bool = true,
        schedule: ReminderSchedule = ReminderSchedule()
    ) {
        self.id = id
        self.title = title
        self.emoji = emoji
        self.isEnabled = isEnabled
        self.schedule = schedule
    }

    /// Next time this reminder fires, or `nil` if it is disabled or a one-off in the past.
    func nextOccurrence(after date: Date = Date(), calendar: Calendar = .current) -> Date? {
        guard isEnabled else { return nil }
        return schedule.nextOccurrence(after: date, calendar: calendar)
    }
}
