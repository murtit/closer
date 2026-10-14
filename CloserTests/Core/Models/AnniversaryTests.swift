import Foundation
import Testing
@testable import Closer

@MainActor
struct AnniversaryTests {
    private let calendar = TestCalendar.zurich
    /// Monday, 12 October 2026, 10:00.
    private let monday = TestCalendar.date(2026, 10, 12, 10)

    // MARK: - Dates

    @Test func nextDateIsLaterThisYear() {
        let anniversary = Anniversary(date: TestCalendar.date(2021, 11, 4))
        #expect(anniversary.nextDate(onOrAfter: monday, calendar: calendar) == TestCalendar.date(2026, 11, 4))
        #expect(anniversary.daysUntilNext(from: monday, calendar: calendar) == 23)
        #expect(anniversary.nextNumber(from: monday, calendar: calendar) == 5)
    }

    @Test func nextDateRollsIntoNextYearOncePassed() {
        let anniversary = Anniversary(date: TestCalendar.date(2021, 2, 14))
        #expect(anniversary.nextDate(onOrAfter: monday, calendar: calendar) == TestCalendar.date(2027, 2, 14))
        #expect(anniversary.nextNumber(from: monday, calendar: calendar) == 6)
    }

    @Test func todayCountsAsTheAnniversary() {
        let anniversary = Anniversary(date: TestCalendar.date(2023, 10, 12))
        #expect(anniversary.isToday(monday, calendar: calendar))
        #expect(anniversary.daysUntilNext(from: monday, calendar: calendar) == 0)
        #expect(anniversary.nextNumber(from: monday, calendar: calendar) == 3)
    }

    @Test func firstAnniversaryOfACoupleThatJustGotTogether() {
        let anniversary = Anniversary(date: TestCalendar.date(2026, 10, 12))
        #expect(anniversary.nextDate(onOrAfter: monday, calendar: calendar) == TestCalendar.date(2027, 10, 12))
        #expect(anniversary.nextNumber(from: monday, calendar: calendar) == 1)
        #expect(anniversary.daysTogether(on: monday, calendar: calendar) == 0)
    }

    @Test func leapDayIsCelebratedOnTheTwentyEighthInOtherYears() {
        let anniversary = Anniversary(date: TestCalendar.date(2024, 2, 29))
        #expect(anniversary.nextDate(onOrAfter: monday, calendar: calendar) == TestCalendar.date(2027, 2, 28))
        #expect(anniversary.occurrence(inYear: 2028, calendar: calendar) == TestCalendar.date(2028, 2, 29))
    }

    @Test func daysTogetherCountsWholeDays() {
        let anniversary = Anniversary(date: TestCalendar.date(2026, 1, 1, 23))
        #expect(anniversary.daysTogether(on: monday, calendar: calendar) == 284)
    }

    // MARK: - Reminders

    @Test func defaultsRemindOnTheDayAndTwoWeeksAndThreeDaysBefore() {
        let anniversary = Anniversary(date: TestCalendar.date(2021, 11, 4))
        #expect(anniversary.isEnabled)
        #expect(anniversary.headsUpDays == [14, 3])

        let reminders = anniversary.reminders(calendar: calendar)
        #expect(reminders.map(\.id) == [anniversary.headsUps[0].id, anniversary.headsUps[1].id, anniversary.reminderID])
        #expect(reminders.allSatisfy { $0.schedule.frequency == .yearly && $0.schedule.hour == 9 && $0.isEnabled })
        #expect(reminders.map { $0.nextOccurrence(after: monday, calendar: calendar) } == [
            TestCalendar.date(2026, 10, 21, 9),
            TestCalendar.date(2026, 11, 1, 9),
            TestCalendar.date(2026, 11, 4, 9),
        ])
        #expect(reminders[0].emoji == "🎁")
        #expect(reminders[0].title.contains("Geschenk"))
        #expect(reminders[1].title.contains("Date"))
    }

    @Test func headsUpAcrossTheTurnOfTheYear() {
        let anniversary = Anniversary(date: TestCalendar.date(2021, 1, 5), headsUps: [.init(daysBefore: 14)])
        let headsUp = anniversary.reminders(calendar: calendar)[0]
        let components = headsUp.schedule.triggerComponents(calendar: calendar)
        #expect(components.month == 12)
        #expect(components.day == 22)
    }

    @Test func disabledAnniversaryHasNoRemindersButKeepsItsIDs() {
        let anniversary = Anniversary(date: TestCalendar.date(2021, 11, 4), isEnabled: false)
        #expect(anniversary.reminders(calendar: calendar).isEmpty)
        #expect(anniversary.reminderIDs.count == 3)
    }

    @Test func remindersUseTheChosenTime() {
        let anniversary = Anniversary(date: TestCalendar.date(2021, 11, 4), hour: 19, minute: 30, headsUps: [])
        let reminder = anniversary.reminders(calendar: calendar)[0]
        #expect(reminder.nextOccurrence(after: monday, calendar: calendar) == TestCalendar.date(2026, 11, 4, 19, 30))
    }

    @Test func settingAHeadsUpKeepsExistingIDsAndOrder() {
        var anniversary = Anniversary(date: TestCalendar.date(2021, 11, 4))
        let twoWeeks = anniversary.headsUps[0].id

        anniversary.setHeadsUp(14, enabled: true)
        anniversary.setHeadsUp(30, enabled: true)
        anniversary.setHeadsUp(3, enabled: false)

        #expect(anniversary.headsUpDays == [30, 14])
        #expect(anniversary.headsUps.first { $0.daysBefore == 14 }?.id == twoWeeks)
    }

    // MARK: - Display

    @Test func togetherText() {
        let start = TestCalendar.date(2026, 10, 12)
        let anniversary = Anniversary(date: start)
        #expect(anniversary.togetherText(on: monday, calendar: calendar) == "Seit heute zusammen")
        #expect(anniversary.togetherText(on: TestCalendar.date(2026, 10, 13), calendar: calendar) == "Seit einem Tag zusammen")
        #expect(anniversary.togetherText(on: TestCalendar.date(2027, 1, 20), calendar: calendar) == "Seit 100 Tagen zusammen")
    }

    @Test func countdownText() {
        let anniversary = Anniversary(date: TestCalendar.date(2023, 10, 12))
        #expect(anniversary.countdownText(from: monday, calendar: calendar) == "Heute ist euer 3. Jahrestag")
        #expect(anniversary.countdownText(from: TestCalendar.date(2026, 10, 11), calendar: calendar) == "Morgen ist euer 3. Jahrestag")
        #expect(anniversary.countdownText(from: TestCalendar.date(2026, 9, 19), calendar: calendar) == "3. Jahrestag in 23 Tagen")
    }

    @Test func remindersSummary() {
        var anniversary = Anniversary(date: TestCalendar.date(2021, 11, 4))
        #expect(anniversary.remindersSummary == "Erinnerung am Tag selbst, 2 Wochen und 3 Tage vorher")
        anniversary.setHeadsUp(1, enabled: true)
        #expect(anniversary.remindersSummary == "Erinnerung am Tag selbst, 2 Wochen, 3 Tage und 1 Tag vorher")
        anniversary.headsUps = []
        #expect(anniversary.remindersSummary == "Erinnerung am Tag selbst")
        anniversary.isEnabled = false
        #expect(anniversary.remindersSummary == "Keine Erinnerung")
    }
}
