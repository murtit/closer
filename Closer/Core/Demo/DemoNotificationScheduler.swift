#if DEBUG
import Foundation

/// Used with demo data: reports notifications as allowed so no permission prompt or alert
/// appears, and schedules nothing.
struct DemoNotificationScheduler: NotificationScheduling {
    func requestAuthorization() async -> Bool { true }
    func isAuthorized() async -> Bool { true }
    func schedule(_ reminder: Reminder, for person: Person) async { }
    func cancel(_ reminderIDs: [UUID]) { }
    func cancelAll() { }
}
#endif
