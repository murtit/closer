import Foundation
import UserNotifications

/// Abstraction over local notifications so the ViewModel can be tested without `UNUserNotificationCenter`.
protocol NotificationScheduling {
    /// Asks for permission if not yet determined. Returns whether notifications may be delivered.
    func requestAuthorization() async -> Bool
    /// Current permission without prompting.
    func isAuthorized() async -> Bool
    func schedule(_ reminder: Reminder, for person: Person) async
    func cancel(_ reminderIDs: [UUID])
    func cancelAll()
}

/// Production implementation backed by `UNUserNotificationCenter`.
final class UserNotificationScheduler: NotificationScheduling {
    private let center: UNUserNotificationCenter

    init(center: UNUserNotificationCenter = .current()) {
        self.center = center
    }

    func requestAuthorization() async -> Bool {
        switch await center.notificationSettings().authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            return true
        case .notDetermined:
            return (try? await center.requestAuthorization(options: [.alert, .sound, .badge])) ?? false
        default:
            return false
        }
    }

    func isAuthorized() async -> Bool {
        switch await center.notificationSettings().authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            return true
        default:
            return false
        }
    }

    func schedule(_ reminder: Reminder, for person: Person) async {
        guard reminder.nextOccurrence() != nil else { return }

        let content = UNMutableNotificationContent()
        content.title = person.name
        content.body = "\(reminder.emoji) \(reminder.title)"
        content.sound = person.sound.userNotificationSound
        content.threadIdentifier = person.id.uuidString
        content.userInfo = ["personID": person.id.uuidString]

        let trigger = UNCalendarNotificationTrigger(
            dateMatching: reminder.schedule.triggerComponents(),
            repeats: reminder.schedule.repeats
        )
        let request = UNNotificationRequest(identifier: reminder.id.uuidString, content: content, trigger: trigger)
        try? await center.add(request)
    }

    func cancel(_ reminderIDs: [UUID]) {
        guard !reminderIDs.isEmpty else { return }
        center.removePendingNotificationRequests(withIdentifiers: reminderIDs.map(\.uuidString))
    }

    func cancelAll() {
        center.removeAllPendingNotificationRequests()
    }
}
