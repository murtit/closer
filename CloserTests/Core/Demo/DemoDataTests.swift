import Foundation
import Testing
@testable import Closer

@MainActor
struct DemoDataTests {
    private let now = TestCalendar.date(2026, 10, 13, 20, 48)

    @Test func coversEveryRelationship() {
        let relationships = DemoData.people(now: now, calendar: TestCalendar.zurich).map(\.relationship.sortIndex)
        #expect(Set(relationships) == [0, 1, 2, 3])
    }

    @Test func idsAreUnique() {
        let people = DemoData.people(now: now, calendar: TestCalendar.zurich)
        let reminderIDs = people.flatMap { $0.reminders.map(\.id) }
        #expect(Set(people.map(\.id)).count == people.count)
        #expect(Set(reminderIDs).count == reminderIDs.count)
    }

    @Test func upcomingOrderIsStableAtAnyTimeOfDay() throws {
        for hour in [0, 7, 12, 23] {
            let reference = TestCalendar.date(2026, 10, 13, hour, 30)
            let people = DemoData.people(now: reference, calendar: TestCalendar.zurich)
            let viewModel = PeopleViewModel(
                store: PeopleStore(fileURL: FileManager.default.temporaryDirectory
                    .appending(path: "CloserTests-\(UUID().uuidString)")
                    .appending(path: "people.json")),
                notifications: FakeNotificationScheduler(),
                defaults: try #require(UserDefaults(suiteName: "DemoDataTests-\(UUID().uuidString)"))
            )
            for person in people { viewModel.add(person) }

            let upcoming = viewModel.upcoming(after: reference, limit: 4, calendar: TestCalendar.zurich)
            #expect(upcoming.map(\.reminder.title) == [
                "Spontanes Date planen",
                "Melden und etwas abmachen",
                "Anrufen und fragen, wie es geht",
                "Auf ein Bier oder einen Kaffee treffen",
            ])
            // Next full hour, one day later.
            let expected = TestCalendar.zurich.date(byAdding: .hour, value: 25, to: TestCalendar.date(2026, 10, 13, hour))
            #expect(upcoming.first?.date == expected)
        }
    }

    @Test func partnerHasAnAnniversaryInThreeWeeks() throws {
        let people = DemoData.people(now: now, calendar: TestCalendar.zurich)
        #expect(people.filter(\.isPartner).count == 1)
        let anniversary = try #require(people.first(where: \.isPartner)?.anniversary)
        #expect(anniversary.daysUntilNext(from: now, calendar: TestCalendar.zurich) == 23)
        #expect(anniversary.nextNumber(from: now, calendar: TestCalendar.zurich) == 3)
    }

    @Test func viewModelStartsWithDemoPeople() {
        let viewModel = DemoData.makeViewModel(now: now)
        #expect(viewModel.people.count == DemoData.people(now: now).count)
        #expect(viewModel.storageError == nil)
    }
}
