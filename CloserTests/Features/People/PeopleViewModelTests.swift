import Foundation
import Testing
@testable import Closer

@MainActor
struct PeopleViewModelTests {
    private let store: PeopleStore
    private let defaults: UserDefaults
    private let notifications: FakeNotificationScheduler

    init() {
        notifications = FakeNotificationScheduler()
        store = PeopleStore(
            fileURL: FileManager.default.temporaryDirectory
                .appending(path: "CloserTests-\(UUID().uuidString)")
                .appending(path: "people.json")
        )
        let suiteName = "CloserTests.\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
    }

    private func makeViewModel() -> PeopleViewModel {
        PeopleViewModel(store: store, notifications: notifications, defaults: defaults)
    }

    private func grandpa() -> Person {
        Person(
            name: "Opa",
            relationship: .family,
            phoneNumber: "+41 79 123 45 67",
            reminders: [
                Reminder(title: "Anrufen", emoji: "📞", schedule: .init(frequency: .weekly, hour: 18, weekday: 1)),
                Reminder(title: "Vorbeischauen", emoji: "🏡", isEnabled: false, schedule: .init(frequency: .monthly)),
            ]
        )
    }

    // MARK: - People

    @Test func startsEmpty() {
        let viewModel = makeViewModel()
        #expect(viewModel.people.isEmpty)
        #expect(viewModel.activeReminderCount == 0)
        #expect(viewModel.storageError == nil)
    }

    @Test func addedPersonIsPersistedAndEnabledRemindersAreScheduled() async {
        let viewModel = makeViewModel()
        let person = grandpa()
        viewModel.add(person)
        await viewModel.pendingNotificationWork?.value

        #expect(makeViewModel().people == [person])
        #expect(Set(notifications.pending.keys) == [person.reminders[0].id])
        #expect(notifications.authorizationRequests == 1)
        #expect(viewModel.activeReminderCount == 1)
    }

    @Test func deniedPermissionShowsAlertAndSchedulesNothing() async {
        notifications.isPermissionGranted = false
        let viewModel = makeViewModel()
        viewModel.add(grandpa())
        await viewModel.pendingNotificationWork?.value

        #expect(notifications.pending.isEmpty)
        #expect(viewModel.showPermissionAlert)
        #expect(viewModel.people.count == 1)
    }

    @Test func personWithoutEnabledRemindersDoesNotAskForPermission() async {
        let viewModel = makeViewModel()
        viewModel.add(Person(name: "Lukas", relationship: .friend))
        await viewModel.pendingNotificationWork?.value

        #expect(notifications.authorizationRequests == 0)
    }

    @Test func updateReplacesPersonAndReschedules() async {
        let viewModel = makeViewModel()
        var person = grandpa()
        viewModel.add(person)

        person.name = "Grossvater"
        person.reminders.removeFirst()
        viewModel.update(person)
        await viewModel.pendingNotificationWork?.value

        #expect(viewModel.person(withID: person.id)?.name == "Grossvater")
        #expect(makeViewModel().people == [person])
        #expect(notifications.pending.isEmpty)
    }

    @Test func deletePersonCancelsAllTheirReminders() async {
        let viewModel = makeViewModel()
        let person = grandpa()
        viewModel.add(person)
        viewModel.delete(person)
        await viewModel.pendingNotificationWork?.value

        #expect(viewModel.people.isEmpty)
        #expect(makeViewModel().people.isEmpty)
        #expect(notifications.pending.isEmpty)
        #expect(Set(notifications.cancelledIDs).isSuperset(of: person.reminders.map(\.id)))
    }

    // MARK: - Reminders

    @Test func saveAppendsNewReminder() async {
        let viewModel = makeViewModel()
        let person = grandpa()
        viewModel.add(person)

        let reminder = Reminder(title: "Fotos zeigen", emoji: "📸", schedule: .init(frequency: .daily))
        viewModel.save(reminder, for: person.id)
        await viewModel.pendingNotificationWork?.value

        #expect(viewModel.person(withID: person.id)?.reminders.last == reminder)
        #expect(notifications.pending[reminder.id] == reminder)
    }

    @Test func saveReplacesExistingReminder() async {
        let viewModel = makeViewModel()
        let person = grandpa()
        viewModel.add(person)

        var edited = person.reminders[0]
        edited.title = "Anrufen und fragen, wie es geht"
        edited.schedule.hour = 19
        viewModel.save(edited, for: person.id)
        await viewModel.pendingNotificationWork?.value

        #expect(viewModel.person(withID: person.id)?.reminders.count == 2)
        #expect(viewModel.person(withID: person.id)?.reminders[0] == edited)
        #expect(notifications.pending[edited.id] == edited)
    }

    @Test func disablingReminderCancelsItsNotification() async {
        let viewModel = makeViewModel()
        let person = grandpa()
        let reminderID = person.reminders[0].id
        viewModel.add(person)

        viewModel.setReminder(reminderID, enabled: false, for: person.id)
        await viewModel.pendingNotificationWork?.value

        #expect(viewModel.person(withID: person.id)?.reminders[0].isEnabled == false)
        #expect(notifications.pending[reminderID] == nil)
    }

    @Test func enablingReminderSchedulesIt() async {
        let viewModel = makeViewModel()
        let person = grandpa()
        let reminderID = person.reminders[1].id
        viewModel.add(person)

        viewModel.setReminder(reminderID, enabled: true, for: person.id)
        await viewModel.pendingNotificationWork?.value

        #expect(notifications.pending[reminderID] != nil)
        #expect(viewModel.activeReminderCount == 2)
    }

    @Test func deleteReminderRemovesAndCancelsIt() async {
        let viewModel = makeViewModel()
        let person = grandpa()
        let reminderID = person.reminders[0].id
        viewModel.add(person)

        viewModel.deleteReminder(reminderID, for: person.id)
        await viewModel.pendingNotificationWork?.value

        #expect(viewModel.person(withID: person.id)?.reminders.map(\.id) == [person.reminders[1].id])
        #expect(notifications.pending[reminderID] == nil)
    }

    // MARK: - Queries

    @Test func sortedPeopleGroupsByRelationshipThenName() {
        let viewModel = makeViewModel()
        viewModel.add(Person(name: "Lukas", relationship: .friend))
        viewModel.add(Person(name: "Zoe", relationship: .other("Nachbarin")))
        viewModel.add(Person(name: "Opa", relationship: .family))
        viewModel.add(Person(name: "Sara", relationship: .partner))
        viewModel.add(Person(name: "Mama", relationship: .family))

        #expect(viewModel.sortedPeople.map(\.name) == ["Sara", "Mama", "Opa", "Lukas", "Zoe"])
    }

    @Test func upcomingIsSortedAcrossPeopleAndSkipsDisabled() {
        let viewModel = makeViewModel()
        let calendar = TestCalendar.zurich
        let monday = TestCalendar.date(2026, 10, 12, 10)

        let sara = Person(name: "Sara", relationship: .partner, reminders: [
            Reminder(title: "Date", emoji: "🍷", schedule: .init(frequency: .weekly, hour: 12, weekday: 4)),
        ])
        let opa = Person(name: "Opa", relationship: .family, reminders: [
            Reminder(title: "Anrufen", emoji: "📞", schedule: .init(frequency: .daily, hour: 18)),
            Reminder(title: "Aus", emoji: "⏸️", isEnabled: false, schedule: .init(frequency: .daily, hour: 11)),
        ])
        viewModel.add(sara)
        viewModel.add(opa)

        let upcoming = viewModel.upcoming(after: monday, calendar: calendar)
        #expect(upcoming.map(\.reminder.title) == ["Anrufen", "Date"])
        #expect(upcoming.first?.person.id == opa.id)
        #expect(upcoming.first?.date == TestCalendar.date(2026, 10, 12, 18))
    }

    // MARK: - Partner

    @Test func onlyOnePartnerCanBeAdded() {
        let viewModel = makeViewModel()
        let sara = Person(name: "Sara", relationship: .partner)
        #expect(viewModel.canBePartner(nil))
        #expect(viewModel.add(sara))

        #expect(!viewModel.canBePartner(nil))
        #expect(viewModel.canBePartner(sara.id))
        #expect(!viewModel.add(Person(name: "Lea", relationship: .partner)))
        #expect(viewModel.people.map(\.name) == ["Sara"])
        #expect(viewModel.partner?.id == sara.id)
    }

    @Test func nobodyElseCanBecomeThePartner() {
        let viewModel = makeViewModel()
        viewModel.add(Person(name: "Sara", relationship: .partner))
        var lukas = Person(name: "Lukas", relationship: .friend)
        viewModel.add(lukas)

        lukas.relationship = .partner
        #expect(!viewModel.update(lukas))
        #expect(viewModel.person(withID: lukas.id)?.relationship == .friend)
    }

    @Test func partnerCanBeEditedAndReplacedAfterwards() {
        let viewModel = makeViewModel()
        var sara = Person(name: "Sara", relationship: .partner)
        viewModel.add(sara)

        sara.name = "Sara Keller"
        #expect(viewModel.update(sara))

        sara.relationship = .friend
        #expect(viewModel.update(sara))
        #expect(viewModel.partner == nil)
        #expect(viewModel.add(Person(name: "Lea", relationship: .partner)))
    }

    @Test func settingTheAnniversarySchedulesItsReminders() async {
        let viewModel = makeViewModel()
        let sara = Person(name: "Sara", relationship: .partner)
        viewModel.add(sara)

        let anniversary = Anniversary(date: TestCalendar.date(2021, 2, 14))
        viewModel.setAnniversary(anniversary, for: sara.id)
        await viewModel.pendingNotificationWork?.value

        #expect(makeViewModel().partner?.anniversary == anniversary)
        #expect(Set(notifications.pending.keys) == Set(anniversary.reminderIDs))
        #expect(notifications.pending[anniversary.reminderID]?.schedule.frequency == .yearly)
    }

    @Test func removingAHeadsUpCancelsItsNotification() async {
        let viewModel = makeViewModel()
        var anniversary = Anniversary(date: TestCalendar.date(2021, 2, 14))
        let sara = Person(name: "Sara", relationship: .partner, anniversary: anniversary)
        viewModel.add(sara)
        let threeDays = anniversary.headsUps[1].id

        anniversary.setHeadsUp(3, enabled: false)
        viewModel.setAnniversary(anniversary, for: sara.id)
        await viewModel.pendingNotificationWork?.value

        #expect(notifications.pending[threeDays] == nil)
        #expect(notifications.cancelledIDs.contains(threeDays))
        #expect(notifications.pending.count == 2)
    }

    @Test func removingTheAnniversaryOrThePartnerCancelsEverything() async {
        let viewModel = makeViewModel()
        let anniversary = Anniversary(date: TestCalendar.date(2021, 2, 14))
        let sara = Person(name: "Sara", relationship: .partner, anniversary: anniversary)
        viewModel.add(sara)

        viewModel.setAnniversary(nil, for: sara.id)
        await viewModel.pendingNotificationWork?.value
        #expect(notifications.pending.isEmpty)

        viewModel.setAnniversary(anniversary, for: sara.id)
        viewModel.delete(sara)
        await viewModel.pendingNotificationWork?.value
        #expect(notifications.pending.isEmpty)
    }

    @Test func onlyThePartnerCanHaveAnAnniversary() {
        let viewModel = makeViewModel()
        let opa = grandpa()
        viewModel.add(opa)
        viewModel.setAnniversary(Anniversary(date: TestCalendar.date(2021, 2, 14)), for: opa.id)
        #expect(viewModel.person(withID: opa.id)?.anniversary == nil)
    }

    @Test func upcomingIncludesAnniversaryReminders() {
        let viewModel = makeViewModel()
        viewModel.add(Person(name: "Sara", relationship: .partner, anniversary: Anniversary(date: TestCalendar.date(2021, 10, 20))))

        let upcoming = viewModel.upcoming(after: TestCalendar.date(2026, 10, 12, 10), calendar: TestCalendar.zurich)
        #expect(upcoming.map(\.date) == [TestCalendar.date(2026, 10, 17, 9), TestCalendar.date(2026, 10, 20, 9), TestCalendar.date(2027, 10, 6, 9)])
    }

    // MARK: - Notification sound

    @Test func remindersAreScheduledWithThePersonsSound() async {
        let viewModel = makeViewModel()
        var person = grandpa()
        person.sound = .gruss
        viewModel.add(person)
        await viewModel.pendingNotificationWork?.value

        #expect(notifications.sounds[person.reminders[0].id] == .gruss)
    }

    @Test func changingTheSoundReschedulesWithTheNewSound() async {
        let viewModel = makeViewModel()
        var person = grandpa()
        viewModel.add(person)
        await viewModel.pendingNotificationWork?.value
        #expect(notifications.sounds[person.reminders[0].id] == .standard)

        person.sound = .tropfen
        viewModel.update(person)
        await viewModel.pendingNotificationWork?.value

        #expect(notifications.sounds[person.reminders[0].id] == .tropfen)
        #expect(makeViewModel().person(withID: person.id)?.sound == .tropfen)
    }

    @Test func anniversaryRemindersPlayThePartnersSound() async {
        let viewModel = makeViewModel()
        var partner = Person(name: "Sara", relationship: .partner, anniversary: Anniversary(date: TestCalendar.date(2021, 2, 14)))
        partner.sound = .naehe
        viewModel.add(partner)
        await viewModel.pendingNotificationWork?.value

        let ids = partner.anniversary?.reminderIDs ?? []
        #expect(!ids.isEmpty)
        #expect(ids.allSatisfy { notifications.sounds[$0] == .naehe })
    }

    // MARK: - Notifications & migration

    @Test func syncReschedulesEverythingWhenAuthorized() async {
        let viewModel = makeViewModel()
        let person = grandpa()
        viewModel.add(person)
        await viewModel.pendingNotificationWork?.value

        viewModel.syncNotifications()
        await viewModel.pendingNotificationWork?.value

        #expect(notifications.cancelAllCount == 1)
        #expect(Set(notifications.pending.keys) == [person.reminders[0].id])
    }

    @Test func syncAlsoSchedulesTheAnniversary() async {
        let viewModel = makeViewModel()
        let anniversary = Anniversary(date: TestCalendar.date(2021, 2, 14))
        viewModel.add(Person(name: "Sara", relationship: .partner, anniversary: anniversary))
        await viewModel.pendingNotificationWork?.value

        viewModel.syncNotifications()
        await viewModel.pendingNotificationWork?.value

        #expect(Set(notifications.pending.keys) == Set(anniversary.reminderIDs))
    }

    @Test func syncDoesNothingWithoutPermission() async {
        notifications.isPermissionGranted = false
        let viewModel = makeViewModel()
        viewModel.syncNotifications()
        await viewModel.pendingNotificationWork?.value

        #expect(notifications.cancelAllCount == 0)
        #expect(notifications.authorizationRequests == 0)
    }

    @Test func legacyGlobalRemindersAreCancelledAndRemoved() async throws {
        let legacyID = UUID()
        let legacyJSON = #"[{"id":"\#(legacyID.uuidString)","title":"Blumen kaufen","emoji":"🌸","isEnabled":true,"time":0,"isCustom":false}]"#
        defaults.set(Data(legacyJSON.utf8), forKey: PeopleViewModel.legacyStorageKey)

        let viewModel = makeViewModel()
        await viewModel.pendingNotificationWork?.value

        #expect(defaults.data(forKey: PeopleViewModel.legacyStorageKey) == nil)
        #expect(notifications.cancelledIDs.contains(legacyID))
    }
}
