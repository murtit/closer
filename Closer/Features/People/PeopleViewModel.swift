import Foundation
import Observation

/// Owns all people and their reminders, persists them and keeps local notifications in sync.
@Observable
final class PeopleViewModel {
    private(set) var people: [Person] = []
    /// Notification sounds the user added, oldest first.
    private(set) var customSounds: [CustomSound] = []
    var showPermissionAlert = false
    /// Set when saved data could not be read or written.
    var storageError: String?

    /// Storage key of the global reminders from 0.1.0 (before reminders belonged to a person).
    static let legacyStorageKey = "reminders_v1"

    private let store: PeopleStore
    private let notifications: any NotificationScheduling
    private let defaults: UserDefaults
    private let sounds: SoundLibrary

    /// Notification work runs in order; tests await this to observe the result.
    @ObservationIgnored
    private(set) var pendingNotificationWork: Task<Void, Never>?

    init(
        store: PeopleStore = PeopleStore(),
        notifications: any NotificationScheduling = UserNotificationScheduler(),
        defaults: UserDefaults = .standard,
        sounds: SoundLibrary = SoundLibrary()
    ) {
        self.store = store
        self.notifications = notifications
        self.defaults = defaults
        self.sounds = sounds
        customSounds = sounds.customSounds
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

    /// There is only one partner. Should older data contain several, the one added first counts.
    var partner: Person? {
        people.filter(\.isPartner).min { $0.createdAt < $1.createdAt }
    }

    /// Whether the person with `id` (or a new person, for `nil`) may be the partner: only if
    /// nobody else is.
    func canBePartner(_ id: Person.ID?) -> Bool {
        !people.contains { $0.isPartner && $0.id != id }
    }

    struct Upcoming: Identifiable {
        var id: Reminder.ID { reminder.id }
        let person: Person
        let reminder: Reminder
        let date: Date
    }

    /// All upcoming reminders across people, soonest first.
    func upcoming(after date: Date = Date(), limit: Int = 5, calendar: Calendar = .current) -> [Upcoming] {
        let all = people.flatMap { person in
            person.allReminders(calendar: calendar).compactMap { reminder in
                reminder.nextOccurrence(after: date, calendar: calendar)
                    .map { Upcoming(person: person, reminder: reminder, date: $0) }
            }
        }
        return Array(all.sorted { $0.date < $1.date }.prefix(limit))
    }

    // MARK: - People

    /// Adds the person. Returns `false`, and adds nothing, for a second partner.
    @discardableResult
    func add(_ person: Person) -> Bool {
        guard !person.isPartner || canBePartner(person.id) else { return false }
        people.append(person)
        persist()
        let enabled = person.allReminders().filter(\.isEnabled)
        guard !enabled.isEmpty else { return true }
        enqueue(requestingPermission: true) { scheduler in
            for reminder in enabled {
                await scheduler.schedule(reminder, for: person)
            }
        }
        return true
    }

    /// Replaces the person with the same ID. Returns `false`, and changes nothing, when someone
    /// would become a second partner.
    @discardableResult
    func update(_ person: Person) -> Bool {
        guard let index = people.firstIndex(where: { $0.id == person.id }) else { return false }
        let becomesPartner = person.isPartner && !people[index].isPartner
        guard !becomesPartner || canBePartner(person.id) else { return false }
        let previousIDs = people[index].notificationIDs
        people[index] = person
        persist()
        reschedule(person, cancelling: previousIDs)
        return true
    }

    func delete(_ person: Person) {
        guard let index = people.firstIndex(where: { $0.id == person.id }) else { return }
        let ids = people[index].notificationIDs
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

    // MARK: - Anniversary

    /// Sets, changes or (with `nil`) removes the partner's anniversary.
    func setAnniversary(_ anniversary: Anniversary?, for personID: Person.ID) {
        guard var person = person(withID: personID), person.isPartner else { return }
        person.anniversary = anniversary
        update(person)
    }

    // MARK: - Sounds

    /// Name shown for a sound. A custom sound that no longer exists plays the system default and
    /// is shown as such.
    func title(for sound: NotificationSound) -> String {
        guard case .custom(let id) = sound else { return sound.title }
        return sounds.customSound(withID: id)?.name ?? NotificationSound.standard.title
    }

    /// File to preview the sound with, `nil` for the system default.
    func soundURL(for sound: NotificationSound) -> URL? {
        sounds.url(for: sound)
    }

    /// Adds the audio file at `url` as a custom sound, cut to under 30 seconds.
    func importSound(from url: URL) async throws -> CustomSound {
        let sound = try await sounds.importSound(from: url)
        customSounds = sounds.customSounds
        return sound
    }

    /// Removes a custom sound. People who used it go back to the system default.
    func deleteSound(_ sound: CustomSound) {
        do {
            try sounds.delete(sound.id)
        } catch {
            storageError = "Der Ton konnte nicht gelöscht werden."
        }
        customSounds = sounds.customSounds
        for var person in people where person.sound == sound.sound {
            person.sound = .standard
            update(person)
        }
    }

    // MARK: - Notifications

    /// Rebuilds all pending notifications from the stored data. Called on launch so that the
    /// system state matches the app even after a restore or a failed schedule. Never prompts.
    func syncNotifications() {
        let snapshot = people.map { (person: $0, reminders: $0.allReminders().filter(\.isEnabled)) }
        enqueue { scheduler in
            guard await scheduler.isAuthorized() else { return }
            scheduler.cancelAll()
            for (person, reminders) in snapshot {
                for reminder in reminders {
                    await scheduler.schedule(reminder, for: person)
                }
            }
        }
    }

    private func reschedule(_ person: Person, cancelling previousIDs: [UUID]) {
        enqueue { $0.cancel(previousIDs) }
        let enabled = person.allReminders().filter(\.isEnabled)
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
