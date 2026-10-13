import Foundation
@testable import Closer

/// Records what would be scheduled instead of talking to `UNUserNotificationCenter`.
@MainActor
final class FakeNotificationScheduler: NotificationScheduling {
    var isPermissionGranted = true
    private(set) var authorizationRequests = 0
    private(set) var pending: [UUID: Reminder] = [:]
    private(set) var cancelledIDs: [UUID] = []
    private(set) var cancelAllCount = 0

    func requestAuthorization() async -> Bool {
        authorizationRequests += 1
        return isPermissionGranted
    }

    func isAuthorized() async -> Bool {
        isPermissionGranted
    }

    func schedule(_ reminder: Reminder, for person: Person) async {
        pending[reminder.id] = reminder
    }

    func cancel(_ reminderIDs: [UUID]) {
        cancelledIDs += reminderIDs
        for id in reminderIDs { pending[id] = nil }
    }

    func cancelAll() {
        cancelAllCount += 1
        pending.removeAll()
    }
}
