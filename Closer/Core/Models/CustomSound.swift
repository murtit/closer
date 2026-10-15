import Foundation

/// A notification sound the user added from a file, stored by `SoundLibrary`.
struct CustomSound: Identifiable, Codable, Equatable, Hashable {
    var id: UUID
    /// Shown in the sound picker; taken from the imported file's name.
    var name: String
    /// Length in seconds after trimming.
    var duration: TimeInterval
    var createdAt: Date

    init(id: UUID = UUID(), name: String, duration: TimeInterval, createdAt: Date = Date()) {
        self.id = id
        self.name = name
        self.duration = duration
        self.createdAt = createdAt
    }

    var sound: NotificationSound { .custom(id) }

    /// Display name for an imported file: its name without extension, at most 40 characters.
    static func name(forFile url: URL) -> String {
        let name = url.deletingPathExtension().lastPathComponent.trimmingCharacters(in: .whitespacesAndNewlines)
        return name.isEmpty ? "Eigener Ton" : String(name.prefix(40))
    }
}
