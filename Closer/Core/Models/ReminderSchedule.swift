import Foundation

/// When a reminder fires. Kept deliberately small: one-off, daily, weekly, monthly or yearly at a fixed time.
struct ReminderSchedule: Codable, Equatable, Hashable {
    enum Frequency: String, Codable, CaseIterable, Identifiable {
        case once
        case daily
        case weekly
        case monthly
        case yearly

        var id: String { rawValue }

        var title: String {
            switch self {
            case .once:    "Einmalig"
            case .daily:   "Täglich"
            case .weekly:  "Wöchentlich"
            case .monthly: "Monatlich"
            case .yearly:  "Jährlich"
            }
        }
    }

    var frequency: Frequency
    var hour: Int
    var minute: Int
    /// Gregorian weekday, 1 = Sunday … 7 = Saturday. Used for `.weekly`.
    var weekday: Int
    /// Day of month, 1…28 so that every month has it. Used for `.monthly`.
    var dayOfMonth: Int
    /// Calendar day of a one-off reminder, or month and day of a yearly one. Only the date part is
    /// used, time comes from `hour`/`minute`.
    var date: Date

    init(
        frequency: Frequency = .weekly,
        hour: Int = 18,
        minute: Int = 0,
        weekday: Int = 1,
        dayOfMonth: Int = 1,
        date: Date = Date()
    ) {
        self.frequency = frequency
        self.hour = hour
        self.minute = minute
        self.weekday = weekday
        self.dayOfMonth = dayOfMonth
        self.date = date
    }

    static func once(in days: Int, hour: Int = 18, minute: Int = 0, from now: Date = Date(), calendar: Calendar = .current) -> Self {
        let day = calendar.date(byAdding: .day, value: days, to: now) ?? now
        return ReminderSchedule(frequency: .once, hour: hour, minute: minute, date: day)
    }

    // MARK: - Trigger

    /// Date components for `UNCalendarNotificationTrigger`. Repeats for everything but `.once`.
    func triggerComponents(calendar: Calendar = .current) -> DateComponents {
        var components = DateComponents(hour: hour, minute: minute)
        switch frequency {
        case .once:
            let day = calendar.dateComponents([.year, .month, .day], from: date)
            components.year = day.year
            components.month = day.month
            components.day = day.day
        case .daily:
            break
        case .weekly:
            components.weekday = weekday
        case .monthly:
            components.day = dayOfMonth
        case .yearly:
            let day = calendar.dateComponents([.month, .day], from: date)
            components.month = day.month
            // A trigger for 29 February would only fire in leap years.
            components.day = day.month == 2 && day.day == 29 ? 28 : day.day
        }
        return components
    }

    var repeats: Bool { frequency != .once }

    /// Next matching date strictly after `date`, or `nil` for a one-off that already passed.
    func nextOccurrence(after reference: Date = Date(), calendar: Calendar = .current) -> Date? {
        let components = triggerComponents(calendar: calendar)
        if frequency == .once {
            guard let fireDate = calendar.date(from: components), fireDate > reference else { return nil }
            return fireDate
        }
        return calendar.nextDate(after: reference, matching: components, matchingPolicy: .nextTime)
    }

    // MARK: - Display

    /// Human readable summary, e.g. "Jeden Sonntag um 18:00".
    func summary(calendar: Calendar = .current, locale: Locale = Locale(identifier: "de_CH")) -> String {
        let time = String(format: "%02d:%02d", hour, minute)
        switch frequency {
        case .once:
            let formatter = DateFormatter()
            formatter.locale = locale
            formatter.calendar = calendar
            formatter.timeZone = calendar.timeZone
            formatter.setLocalizedDateFormatFromTemplate("EEEEdMMMM")
            return "Am \(formatter.string(from: date)) um \(time)"
        case .daily:
            return "Täglich um \(time)"
        case .weekly:
            return "Jeden \(Self.weekdayName(weekday, locale: locale)) um \(time)"
        case .monthly:
            return "Jeden \(dayOfMonth). des Monats um \(time)"
        case .yearly:
            let formatter = DateFormatter()
            formatter.locale = locale
            formatter.calendar = calendar
            formatter.timeZone = calendar.timeZone
            formatter.setLocalizedDateFormatFromTemplate("dMMMM")
            return "Jedes Jahr am \(formatter.string(from: date)) um \(time)"
        }
    }

    static func weekdayName(_ weekday: Int, locale: Locale = Locale(identifier: "de_CH")) -> String {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = locale
        let symbols = calendar.weekdaySymbols
        return symbols[(max(1, min(7, weekday)) - 1) % symbols.count]
    }
}
