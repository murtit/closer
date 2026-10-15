import UserNotifications

extension NotificationSound {
    /// The sound for `UNNotificationContent.sound`. iOS looks the file up in the app bundle and
    /// plays the default sound if it is missing or longer than 30 seconds.
    var userNotificationSound: UNNotificationSound {
        fileName.map { UNNotificationSound(named: UNNotificationSoundName($0)) } ?? .default
    }
}
