#if DEBUG
import Foundation

/// Fixed sample people for UI tests and the CI screenshots, enabled with the `-demo-data`
/// launch argument (Debug builds only).
///
/// Dates are placed relative to `now`, so every run shows the same people in the same order
/// with the same relative dates ("morgen", "in 2 Tagen", …) on the home screen.
enum DemoData {
    static let launchArgument = "-demo-data"

    static var isRequested: Bool {
        ProcessInfo.processInfo.arguments.contains(launchArgument)
    }

    /// `"light"` or `"dark"` from the `-demo-appearance <value>` launch argument. Forces the
    /// appearance from inside the app, because switching the simulator's appearance from a UI
    /// test does not reliably reach the app.
    static var appearance: String? {
        UserDefaults.standard.string(forKey: "demo-appearance")
    }

    /// A view model on a fresh temporary store that never touches saved data, real
    /// notifications or the permission prompt.
    static func makeViewModel(now: Date = Date()) -> PeopleViewModel {
        let store = PeopleStore(fileURL: FileManager.default.temporaryDirectory.appending(path: "demo-people.json"))
        try? store.save(people(now: now))
        let soundsDirectory = FileManager.default.temporaryDirectory.appending(path: "demo-sounds")
        try? FileManager.default.removeItem(at: soundsDirectory)
        return PeopleViewModel(
            store: store,
            notifications: DemoNotificationScheduler(),
            defaults: UserDefaults(suiteName: "ch.murtit.closer.app.demo") ?? .standard,
            sounds: SoundLibrary(directory: soundsDirectory)
        )
    }

    static func people(now: Date = Date(), calendar: Calendar = .current) -> [Person] {
        // All reminders fire at the start of the next full hour, `days` days from now. This keeps
        // the home screen order stable no matter what time of day the screenshots are taken.
        let startOfHour = calendar.dateInterval(of: .hour, for: now)?.start ?? now
        let base = calendar.date(byAdding: .hour, value: 1, to: startOfHour) ?? now
        let hour = calendar.component(.hour, from: base)

        func day(_ days: Int) -> Date {
            calendar.date(byAdding: .day, value: days, to: base) ?? base
        }
        func once(in days: Int) -> ReminderSchedule {
            ReminderSchedule(frequency: .once, hour: hour, date: day(days))
        }
        func weekly(in days: Int) -> ReminderSchedule {
            ReminderSchedule(frequency: .weekly, hour: hour, weekday: calendar.component(.weekday, from: day(days)))
        }
        func monthly(in days: Int) -> ReminderSchedule {
            ReminderSchedule(frequency: .monthly, hour: hour, dayOfMonth: min(28, calendar.component(.day, from: day(days))))
        }

        // Together for almost three years: the third anniversary is 23 days away.
        let inThreeWeeks = calendar.date(byAdding: .day, value: 23, to: calendar.startOfDay(for: now)) ?? now
        let gotTogether = calendar.date(byAdding: .year, value: -3, to: inThreeWeeks) ?? now

        return [
            Person(
                name: "Lea Brunner",
                relationship: .partner,
                phoneNumber: "+41 79 123 45 67",
                email: "lea@example.ch",
                reminders: [
                    Reminder(title: "Spontanes Date planen", emoji: "🍷", schedule: once(in: 1)),
                    Reminder(title: "Blumen kaufen", emoji: "💐", schedule: monthly(in: 9)),
                    Reminder(title: "Ein Kompliment machen", emoji: "💬", isEnabled: false,
                             schedule: ReminderSchedule(frequency: .daily, hour: 9)),
                ],
                anniversary: Anniversary(date: gotTogether),
                notificationSound: .naehe
            ),
            Person(
                name: "Mama",
                relationship: .family,
                phoneNumber: "+41 78 987 65 43",
                reminders: [
                    Reminder(title: "Anrufen und fragen, wie es geht", emoji: "📞", schedule: weekly(in: 4)),
                    Reminder(title: "Vorbeischauen", emoji: "🏡", schedule: once(in: 12)),
                ]
            ),
            Person(
                name: "Opa Ernst",
                relationship: .family,
                reminders: [
                    Reminder(title: "Ein Foto schicken", emoji: "📸", schedule: monthly(in: 16)),
                ]
            ),
            Person(
                name: "Jonas Meier",
                relationship: .friend,
                phoneNumber: "+41 76 555 12 34",
                email: "jonas@example.ch",
                reminders: [
                    Reminder(title: "Melden und etwas abmachen", emoji: "👋", schedule: once(in: 2)),
                ]
            ),
            Person(
                name: "Sara Keller",
                relationship: .friend,
                reminders: [
                    Reminder(title: "Auf ein Bier oder einen Kaffee treffen", emoji: "🍻", schedule: once(in: 6)),
                ]
            ),
            Person(
                name: "Marco Rossi",
                relationship: .other("Arbeitskollege"),
                email: "marco@example.ch",
                reminders: [
                    Reminder(title: "Gemeinsam etwas unternehmen", emoji: "✨", schedule: once(in: 20)),
                ]
            ),
        ]
    }
}
#endif
