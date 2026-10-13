import Foundation
import Observation

/// Owns all people and their reminders, persists them and keeps local notifications in sync.
@Observable
final class PeopleViewModel {
    private(set) var people: [Person] = []
    var showPermissionAlert = false
    /// Set when saved data could not be read or written.
    var storageError: String?

    /// Storage key of the global reminders from 0.1.0 (before reminders belonged to a person).
    static let legacyStorageKey = "reminders_v1"

    private let store: PeopleStore
    private let notifications: any NotificationScheduling
    private let defaults: UserDefaults

    /// Notification work runs in order; tests await this to observe the result.
    @ObservationIgnored
    private(set) var pendingNotificationWork: Task<Void, Never>?

    init(
        store: PeopleStore = PeopleStore(),
        notifications: any NotificationScheduling = UserNotificationScheduler(),
        defaults: UserDefaults = .standard
    ) {
        self.store = store
        self.notifications = notifications
        self.defaults = defaults
        load()
        migrateLegacyReminders()
    }

    // MARK: - Queries

    func person(withID id: Person.ID) -> Person? {
        people.first { $0.id == id }
    }

    /// People ordered by relationship (partner, family, friends, others) and then by name.
    var sortedPeople: [Person] {
        people.sorted {
            ($0.relationship.sortIndex, $0.name.localizedLowercase) < ($1.relationship.sortIndex, $1.name.localizedLowercase)
        }
    }

    var activeReminderCount: Int { people.reduce(0) { $0 + $1.activeReminderCount } }

    struct Upcoming: Identifiable {
        var id: Reminder.ID { reminder.id }
        let person: Person
        let reminder: Reminder
        let date: Date
    }

    /// All upcoming reminders across people, soonest first.
    func upcoming(after date: Date = Date(), limit: Int = 5, calendar: Calendar = .current) -> [Upcoming] {
        let all = people.flatMap { person in
            person.reminders.compactMap { reminder in
                reminder.nextOccurrence(after: date, calendar: calendar)
                    .map { Upcoming(person: person, reminder: reminder, date: $0) }
            }
        }
        return Array(all.sorted { $0.date < $1.date }.prefix(limit))
    }

    // MARK: - People

    func add(_ person: Person) {
        people.append(person)
        persist()
        guard person.reminders.contains(where: \.isEnabled) else { return }
        enqueue(requestingPermission: true) { scheduler in
            for reminder in person.reminders where reminder.isEnabled {
                await scheduler.schedule(reminder, for: person)
            }
        }
    }

    func update(_ person: Person) {
        guard let index = people.firstIndex(where: { $0.id == person.id }) else { return }
        let previousIDs = people[index].reminders.map(\.id)
        people[index] = person
        persist()
        reschedule(person, cancelling: previousIDs)
    }

    func delete(_ person: Person) {
        guard let index = people.firstIndex(where: { $0.id == person.id }) else { return }
        let ids = people[index].reminders.map(\.id)
        people.remove(at: index)
        persist()
        enqueue { $0.cancel(ids) }
    }

    // MARK: - Reminders

    /// Adds the reminder to the person, or replaces it if one with the same ID exists.
    func save(_ reminder: Reminder, for personID: Person.ID) {
        guard var person = person(withID: personID) else { return }
        if let index = person.reminders.firstIndex(where: { $0.id == reminder.id }) {
            person.reminders[index] = reminder
        } else {
            person.reminders.append(reminder)
        }
        update(person)
    }

    func deleteReminder(_ reminderID: Reminder.ID, for personID: Person.ID) {
        guard var person = person(withID: personID) else { return }
        person.reminders.removeAll { $0.id == reminderID }
        update(person)
    }

    func setReminder(_ reminderID: Reminder.ID, enabled: Bool, for personID: Person.ID) {
        guard var person = person(withID: personID),
              let index = person.reminders.firstIndex(where: { $0.id == reminderID }) else { return }
        person.reminders[index].isEnabled = enabled
        update(person)
    }

    // MARK: - Notifications

    /// Rebuilds all pending notifications from the stored data. Called on launch so that the
    /// system state matches the app even after a restore or a failed schedule. Never prompts.
    func syncNotifications() {
        let snapshot = people
        enqueue { scheduler in
            guard await scheduler.isAuthorized() else { return }
            scheduler.cancelAll()
            for person in snapshot {
                for reminder in person.reminders where reminder.isEnabled {
                    await scheduler.schedule(reminder, for: person)
                }
            }
        }
    }

    private func reschedule(_ person: Person, cancelling previousIDs: [UUID]) {
        enqueue { $0.cancel(previousIDs) }
        let enabled = person.reminders.filter(\.isEnabled)
        guard !enabled.isEmpty else { return }
        enqueue(requestingPermission: true) { scheduler in
            for reminder in enabled {
                await scheduler.schedule(reminder, for: person)
            }
        }
    }

    /// Runs `work` after all previously enqueued notification work. When `requestingPermission`
    /// is set, the user is asked first and `work` only runs if notifications are allowed;
    /// cancellations should therefore not depend on it.
    private func enqueue(
        requestingPermission: Bool = false,
        _ work: @escaping (any NotificationScheduling) async -> Void
    ) {
        let previous = pendingNotificationWork
        let scheduler = notifications
        pendingNotificationWork = Task { [weak self] in
            await previous?.value
            if requestingPermission {
                guard await scheduler.requestAuthorization() else {
                    self?.showPermissionAlert = true
                    return
                }
            }
            await work(scheduler)
        }
    }

    // MARK: - Persistence

    private func load() {
        do {
            people = try store.load()
        } catch {
            storageError = "Gespeicherte Personen konnten nicht geladen werden."
        }
    }

    private func persist() {
        do {
            try store.save(people)
        } catch {
            storageError = "Änderungen konnten nicht gespeichert werden."
        }
    }

    /// Reminders from 0.1.0 were not tied to a person and cannot be mapped to one.
    /// Their notifications are cancelled and the old data is removed.
    private func migrateLegacyReminders() {
        guard let data = defaults.data(forKey: Self.legacyStorageKey) else { return }
        struct LegacyReminder: Decodable { let id: UUID }
        let ids = ((try? JSONDecoder().decode([LegacyReminder].self, from: data)) ?? []).map(\.id)
        defaults.removeObject(forKey: Self.legacyStorageKey)
        enqueue { $0.cancel(ids) }
    }
}
