import Foundation

/// Deterministic calendar and dates so schedule tests do not depend on the machine's settings.
enum TestCalendar {
    static let zurich: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/Zurich")!
        calendar.locale = Locale(identifier: "de_CH")
        return calendar
    }()

    static func date(_ year: Int, _ month: Int, _ day: Int, _ hour: Int = 0, _ minute: Int = 0) -> Date {
        zurich.date(from: DateComponents(year: year, month: month, day: day, hour: hour, minute: minute))!
    }
}
