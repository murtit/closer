import Foundation

/// The day the user and their partner got together, and how Closer reminds them of it.
///
/// Closer reminds on the day itself and, so there is time to plan a date or buy a gift, a few days
/// before (`headsUps`). The notifications are derived as yearly `Reminder`s with fixed IDs, so they
/// can be cancelled and rescheduled whenever the anniversary changes.
struct Anniversary: Codable, Equatable, Hashable {
    /// A reminder some days before the anniversary.
    struct HeadsUp: Identifiable, Codable, Equatable, Hashable {
        var id: UUID
        var daysBefore: Int

        init(id: UUID = UUID(), daysBefore: Int) {
            self.id = id
            self.daysBefore = daysBefore
        }
    }

    /// The day they got together. Only the date part is used.
    var date: Date
    var isEnabled: Bool
    /// Time of day the reminders fire.
    var hour: Int
    var minute: Int
    var headsUps: [HeadsUp]
    /// Notification ID of the reminder on the day itself.
    var reminderID: UUID

    /// Lead times the user can pick from, in days.
    static let headsUpChoices = [1, 3, 7, 14, 30]
    /// Two weeks to organise a gift, three days to book a table.
    static let defaultHeadsUpDays = [14, 3]

    init(
        date: Date,
        isEnabled: Bool = true,
        hour: Int = 9,
        minute: Int = 0,
        headsUps: [HeadsUp] = Anniversary.defaultHeadsUpDays.map { HeadsUp(daysBefore: $0) },
        reminderID: UUID = UUID()
    ) {
        self.date = date
        self.isEnabled = isEnabled
        self.hour = hour
        self.minute = minute
        self.headsUps = headsUps
        self.reminderID = reminderID
    }

    /// Lead times in days, largest first.
    var headsUpDays: [Int] { headsUps.map(\.daysBefore).sorted(by: >) }

    /// Turns a lead time on or off, keeping the ID of an existing one.
    mutating func setHeadsUp(_ daysBefore: Int, enabled: Bool) {
        let exists = headsUps.contains { $0.daysBefore == daysBefore }
        guard enabled != exists else { return }
        headsUps.removeAll { $0.daysBefore == daysBefore }
        if enabled {
            headsUps.append(HeadsUp(daysBefore: daysBefore))
            headsUps.sort { $0.daysBefore > $1.daysBefore }
        }
    }

    // MARK: - Dates

    /// The anniversary in `year`. 29 February falls on the 28th in other years.
    func occurrence(inYear year: Int, calendar: Calendar = .current) -> Date? {
        let original = calendar.dateComponents([.month, .day], from: date)
        guard let month = original.month, let day = original.day,
              let firstOfMonth = calendar.date(from: DateComponents(year: year, month: month, day: 1)),
              let daysInMonth = calendar.range(of: .day, in: .month, for: firstOfMonth)?.count
        else { return nil }
        return calendar.date(from: DateComponents(year: year, month: month, day: min(day, daysInMonth)))
    }

    /// Start of the next anniversary on or after the day of `reference`. Today counts.
    func nextDate(onOrAfter reference: Date = Date(), calendar: Calendar = .current) -> Date? {
        let today = calendar.startOfDay(for: reference)
        let year = calendar.component(.year, from: today)
        let startYear = max(year, calendar.component(.year, from: date) + 1)
        for candidateYear in startYear...(startYear + 1) {
            if let candidate = occurrence(inYear: candidateYear, calendar: calendar), candidate >= today {
                return candidate
            }
        }
        return nil
    }

    /// Whole days until the next anniversary, 0 on the day itself.
    func daysUntilNext(from reference: Date = Date(), calendar: Calendar = .current) -> Int? {
        guard let next = nextDate(onOrAfter: reference, calendar: calendar) else { return nil }
        return calendar.dateComponents([.day], from: calendar.startOfDay(for: reference), to: next).day
    }

    /// Which anniversary comes next, e.g. 3 for the third.
    func nextNumber(from reference: Date = Date(), calendar: Calendar = .current) -> Int? {
        guard let next = nextDate(onOrAfter: reference, calendar: calendar) else { return nil }
        return calendar.component(.year, from: next) - calendar.component(.year, from: date)
    }

    /// Whether today is the anniversary.
    func isToday(_ reference: Date = Date(), calendar: Calendar = .current) -> Bool {
        daysUntilNext(from: reference, calendar: calendar) == 0
    }

    /// Days since they got together, 0 on the first day.
    func daysTogether(on reference: Date = Date(), calendar: Calendar = .current) -> Int {
        let days = calendar.dateComponents(
            [.day],
            from: calendar.startOfDay(for: date),
            to: calendar.startOfDay(for: reference)
        ).day ?? 0
        return max(0, days)
    }

    // MARK: - Reminders

    /// Yearly reminders for the day itself and each lead time. Empty when disabled.
    ///
    /// The texts stay the same every year because the notifications repeat without the app
    /// running; the number of the anniversary is shown in the app instead.
    func reminders(calendar: Calendar = .current) -> [Reminder] {
        guard isEnabled else { return [] }
        let onTheDay = Reminder(
            id: reminderID,
            title: "Heute ist euer Jahrestag. Feiert euch!",
            emoji: "❤️",
            schedule: yearlySchedule(daysBefore: 0, calendar: calendar)
        )
        let before = headsUps.sorted { $0.daysBefore > $1.daysBefore }.map { headsUp in
            Reminder(
                id: headsUp.id,
                title: Self.headsUpTitle(daysBefore: headsUp.daysBefore),
                emoji: Self.headsUpEmoji(daysBefore: headsUp.daysBefore),
                schedule: yearlySchedule(daysBefore: headsUp.daysBefore, calendar: calendar)
            )
        }
        return before + [onTheDay]
    }

    /// IDs of every notification this anniversary may have scheduled, enabled or not.
    var reminderIDs: [UUID] { [reminderID] + headsUps.map(\.id) }

    private func yearlySchedule(daysBefore: Int, calendar: Calendar) -> ReminderSchedule {
        let day = calendar.date(byAdding: .day, value: -daysBefore, to: calendar.startOfDay(for: date)) ?? date
        return ReminderSchedule(frequency: .yearly, hour: hour, minute: minute, date: day)
    }

    static func headsUpTitle(daysBefore: Int) -> String {
        switch daysBefore {
        case 1:
            "Morgen ist euer Jahrestag. Ist alles bereit?"
        case 2...6:
            "In \(daysBefore) Tagen ist euer Jahrestag. Zeit, ein Date zu planen"
        case 7:
            "In einer Woche ist euer Jahrestag. Plane ein Date oder eine Überraschung"
        case 14:
            "In zwei Wochen ist euer Jahrestag. Zeit für ein Geschenk"
        default:
            "In \(daysBefore) Tagen ist euer Jahrestag. Zeit für ein Geschenk"
        }
    }

    static func headsUpEmoji(daysBefore: Int) -> String {
        switch daysBefore {
        case 1:     "💐"
        case 2...7: "🍷"
        default:    "🎁"
        }
    }

    /// Label of a lead time in pickers, e.g. "2 Wochen vorher".
    static func headsUpLabel(daysBefore: Int) -> String {
        switch daysBefore {
        case 1:  "1 Tag vorher"
        case 7:  "1 Woche vorher"
        case 14: "2 Wochen vorher"
        case 30: "1 Monat vorher"
        default: "\(daysBefore) Tage vorher"
        }
    }
}

// MARK: - Display

extension Anniversary {
    /// E.g. "Seit 1’234 Tagen zusammen".
    func togetherText(on reference: Date = Date(), calendar: Calendar = .current) -> String {
        let days = daysTogether(on: reference, calendar: calendar)
        switch days {
        case 0:  return "Seit heute zusammen"
        case 1:  return "Seit einem Tag zusammen"
        default: return "Seit \(days.formatted(.number.locale(Locale(identifier: "de_CH")))) Tagen zusammen"
        }
    }

    /// E.g. "3. Jahrestag in 23 Tagen", "Morgen ist euer 3. Jahrestag" or "Heute ist euer 3. Jahrestag".
    func countdownText(from reference: Date = Date(), calendar: Calendar = .current) -> String? {
        guard let days = daysUntilNext(from: reference, calendar: calendar),
              let number = nextNumber(from: reference, calendar: calendar) else { return nil }
        switch days {
        case 0:  return "Heute ist euer \(number). Jahrestag"
        case 1:  return "Morgen ist euer \(number). Jahrestag"
        default: return "\(number). Jahrestag in \(days) Tagen"
        }
    }

    /// E.g. "Am Tag selbst, 2 Wochen und 3 Tage vorher" or "Keine Erinnerung".
    var remindersSummary: String {
        guard isEnabled else { return "Keine Erinnerung" }
        let before = headsUpDays.map { Self.headsUpLabel(daysBefore: $0).replacingOccurrences(of: " vorher", with: "") }
        guard !before.isEmpty else { return "Erinnerung am Tag selbst" }
        let list = before.count == 1
            ? before[0]
            : before.dropLast().joined(separator: ", ") + " und " + before[before.count - 1]
        return "Erinnerung am Tag selbst, \(list) vorher"
    }
}
