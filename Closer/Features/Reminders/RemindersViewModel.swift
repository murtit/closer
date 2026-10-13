import Foundation
import UserNotifications
import Observation

@Observable
@MainActor
final class RemindersViewModel {
    var reminders: [Reminder] = []
    var showPermissionAlert = false

    /// Storage key is intentionally unchanged from the pre-rename app to keep the persisted format stable.
    static let storageKey = "reminders_v1"

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        load()
    }

    // MARK: - Persistence

    private func load() {
        if let data = defaults.data(forKey: Self.storageKey),
           let decoded = try? JSONDecoder().decode([Reminder].self, from: data) {
            reminders = decoded
        } else {
            reminders = Reminder.predefined
            persist()
        }
    }

    private func persist() {
        guard let data = try? JSONEncoder().encode(reminders) else { return }
        defaults.set(data, forKey: Self.storageKey)
    }

    // MARK: - CRUD

    func add(_ reminder: Reminder) {
        reminders.append(reminder)
        persist()
        if reminder.isEnabled {
            Task { await scheduleIfPermitted(reminder) }
        }
    }

    func update(_ reminder: Reminder) {
        guard let idx = reminders.firstIndex(where: { $0.id == reminder.id }) else { return }
        reminders[idx] = reminder
        persist()
        cancelNotification(id: reminder.id)
        if reminder.isEnabled {
            Task { await scheduleIfPermitted(reminder) }
        }
    }

    func delete(_ reminder: Reminder) {
        reminders.removeAll { $0.id == reminder.id }
        cancelNotification(id: reminder.id)
        persist()
    }

    func toggle(_ reminder: Reminder) {
        guard let idx = reminders.firstIndex(where: { $0.id == reminder.id }) else { return }
        var updated = reminders[idx]
        updated.isEnabled.toggle()
        reminders[idx] = updated
        persist()

        if updated.isEnabled {
            Task {
                let granted = await requestPermission()
                if granted {
                    schedule(updated)
                } else {
                    showPermissionAlert = true
                }
            }
        } else {
            cancelNotification(id: updated.id)
        }
    }

    // MARK: - Computed

    var activeCount: Int { reminders.filter { $0.isEnabled }.count }
    var totalCount: Int  { reminders.count }
    var predefined: [Reminder] { reminders.filter { !$0.isCustom } }
    var custom: [Reminder]     { reminders.filter { $0.isCustom } }

    // MARK: - Notifications

    private func requestPermission() async -> Bool {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        switch settings.authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            return true
        case .notDetermined:
            return (try? await center.requestAuthorization(options: [.alert, .sound, .badge])) ?? false
        default:
            return false
        }
    }

    private func scheduleIfPermitted(_ reminder: Reminder) async {
        guard await requestPermission() else {
            showPermissionAlert = true
            return
        }
        schedule(reminder)
    }

    private func schedule(_ reminder: Reminder) {
        let content = UNMutableNotificationContent()
        content.title = "\(reminder.emoji) \(reminder.title)"
        content.body = "Zeig deiner liebsten Person, wie viel sie dir bedeutet. 💕"
        content.sound = .default

        let components = Calendar.current.dateComponents([.hour, .minute], from: reminder.time)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(
            identifier: reminder.id.uuidString,
            content: content,
            trigger: trigger
        )
        UNUserNotificationCenter.current().add(request)
    }

    private func cancelNotification(id: UUID) {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: [id.uuidString])
    }
}
