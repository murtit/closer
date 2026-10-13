import Foundation
import Testing
@testable import Closer

@MainActor
struct ReminderScheduleTests {
    private let calendar = TestCalendar.zurich
    /// Monday, 12 October 2026, 10:00.
    private let monday = TestCalendar.date(2026, 10, 12, 10)

    @Test func dailyTriggerOnlyContainsTimeAndRepeats() {
        let schedule = ReminderSchedule(frequency: .daily, hour: 9, minute: 30)
        let components = schedule.triggerComponents(calendar: calendar)
        #expect(components.hour == 9)
        #expect(components.minute == 30)
        #expect(components.weekday == nil)
        #expect(components.day == nil)
        #expect(schedule.repeats)
    }

    @Test func weeklyTriggerContainsWeekday() {
        let schedule = ReminderSchedule(frequency: .weekly, hour: 18, weekday: 1)
        let components = schedule.triggerComponents(calendar: calendar)
        #expect(components.weekday == 1)
        #expect(components.day == nil)
    }

    @Test func monthlyTriggerContainsDayOfMonth() {
        let schedule = ReminderSchedule(frequency: .monthly, hour: 17, dayOfMonth: 15)
        let components = schedule.triggerComponents(calendar: calendar)
        #expect(components.day == 15)
        #expect(components.weekday == nil)
    }

    @Test func onceTriggerContainsFullDateAndDoesNotRepeat() {
        let schedule = ReminderSchedule(frequency: .once, hour: 19, minute: 15, date: TestCalendar.date(2026, 10, 26))
        let components = schedule.triggerComponents(calendar: calendar)
        #expect(components.year == 2026)
        #expect(components.month == 10)
        #expect(components.day == 26)
        #expect(components.hour == 19)
        #expect(components.minute == 15)
        #expect(!schedule.repeats)
    }

    @Test func weeklyNextOccurrenceIsComingSunday() {
        let schedule = ReminderSchedule(frequency: .weekly, hour: 18, weekday: 1)
        #expect(schedule.nextOccurrence(after: monday, calendar: calendar) == TestCalendar.date(2026, 10, 18, 18))
    }

    @Test func dailyNextOccurrenceIsTomorrowWhenTimeHasPassed() {
        let schedule = ReminderSchedule(frequency: .daily, hour: 9)
        #expect(schedule.nextOccurrence(after: monday, calendar: calendar) == TestCalendar.date(2026, 10, 13, 9))
    }

    @Test func monthlyNextOccurrenceRollsIntoNextMonth() {
        let schedule = ReminderSchedule(frequency: .monthly, hour: 17, dayOfMonth: 1)
        #expect(schedule.nextOccurrence(after: monday, calendar: calendar) == TestCalendar.date(2026, 11, 1, 17))
    }

    @Test func onceInTheFutureHasNextOccurrence() {
        let schedule = ReminderSchedule(frequency: .once, hour: 18, date: TestCalendar.date(2026, 10, 26))
        #expect(schedule.nextOccurrence(after: monday, calendar: calendar) == TestCalendar.date(2026, 10, 26, 18))
    }

    @Test func onceInThePastHasNoNextOccurrence() {
        let schedule = ReminderSchedule(frequency: .once, hour: 8, date: TestCalendar.date(2026, 10, 12))
        #expect(schedule.nextOccurrence(after: monday, calendar: calendar) == nil)
    }

    @Test func onceInDaysIsRelativeToNow() {
        let schedule = ReminderSchedule.once(in: 14, from: monday, calendar: calendar)
        #expect(schedule.frequency == .once)
        #expect(calendar.isDate(schedule.date, inSameDayAs: TestCalendar.date(2026, 10, 26)))
    }

    @Test func disabledReminderHasNoNextOccurrence() {
        let reminder = Reminder(title: "Anrufen", emoji: "📞", isEnabled: false,
                                schedule: ReminderSchedule(frequency: .daily))
        #expect(reminder.nextOccurrence(after: monday, calendar: calendar) == nil)
    }

    @Test func dailySummary() {
        let schedule = ReminderSchedule(frequency: .daily, hour: 9, minute: 5)
        #expect(schedule.summary(calendar: calendar) == "Täglich um 09:05")
    }

    @Test func weeklySummary() {
        let schedule = ReminderSchedule(frequency: .weekly, hour: 18, weekday: 1)
        #expect(schedule.summary(calendar: calendar) == "Jeden Sonntag um 18:00")
    }

    @Test func monthlySummary() {
        let schedule = ReminderSchedule(frequency: .monthly, hour: 17, dayOfMonth: 1)
        #expect(schedule.summary(calendar: calendar) == "Jeden 1. des Monats um 17:00")
    }

    @Test func onceSummaryContainsDateAndTime() {
        let schedule = ReminderSchedule(frequency: .once, hour: 18, date: TestCalendar.date(2026, 10, 26))
        let summary = schedule.summary(calendar: calendar)
        #expect(summary.hasPrefix("Am "))
        #expect(summary.contains("26"))
        #expect(summary.hasSuffix("um 18:00"))
    }
}
