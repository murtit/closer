import Foundation

/// Finds the files of notification sounds and keeps the sounds the user added.
///
/// Custom sounds live in `Library/Sounds`, the one folder besides the app bundle where iOS looks
/// up `UNNotificationSound(named:)`. Their names are kept next to them in `custom-sounds.json`.
final class SoundLibrary {
    let directory: URL
    private let bundle: Bundle
    private(set) var customSounds: [CustomSound] = []

    init(directory: URL = SoundLibrary.defaultDirectory, bundle: Bundle = .main) {
        self.directory = directory
        self.bundle = bundle
        customSounds = (try? load()) ?? []
    }

    static var defaultDirectory: URL {
        URL.libraryDirectory.appending(path: "Sounds")
    }

    private var indexURL: URL { directory.appending(path: "custom-sounds.json") }

    // MARK: - Lookup

    func customSound(withID id: UUID) -> CustomSound? {
        customSounds.first { $0.id == id }
    }

    /// The sound's file: in the bundle for Closer's sounds, in `directory` for custom ones. `nil`
    /// for the system default or a missing file.
    func url(for sound: NotificationSound) -> URL? {
        guard let fileName = sound.fileName else { return nil }
        if case .custom(let id) = sound {
            guard customSound(withID: id) != nil else { return nil }
            let url = directory.appending(path: fileName)
            return FileManager.default.fileExists(atPath: url.path()) ? url : nil
        }
        let name = (fileName as NSString).deletingPathExtension
        let ext = (fileName as NSString).pathExtension
        return bundle.url(forResource: name, withExtension: ext)
    }

    // MARK: - Changes

    /// Converts the audio file at `source` into a notification sound and adds it. `source` may be
    /// outside the app's sandbox, e.g. picked in the Files app.
    func importSound(from source: URL) async throws -> CustomSound {
        let isScoped = source.startAccessingSecurityScopedResource()
        defer { if isScoped { source.stopAccessingSecurityScopedResource() } }

        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let id = UUID()
        guard let fileName = NotificationSound.custom(id).fileName else { throw CocoaError(.fileWriteUnknown) }
        let destination = directory.appending(path: fileName)
        let duration = try await Task.detached {
            try SoundFileConverter.convert(source, to: destination)
        }.value

        let sound = CustomSound(id: id, name: CustomSound.name(forFile: source), duration: duration)
        customSounds.append(sound)
        do {
            try save()
        } catch {
            customSounds.removeLast()
            try? FileManager.default.removeItem(at: destination)
            throw error
        }
        return sound
    }

    func delete(_ id: UUID) throws {
        if let fileName = NotificationSound.custom(id).fileName {
            try? FileManager.default.removeItem(at: directory.appending(path: fileName))
        }
        customSounds.removeAll { $0.id == id }
        try save()
    }

    // MARK: - Persistence

    private func load() throws -> [CustomSound] {
        guard FileManager.default.fileExists(atPath: indexURL.path()) else { return [] }
        return try JSONDecoder().decode([CustomSound].self, from: Data(contentsOf: indexURL))
    }

    private func save() throws {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try JSONEncoder().encode(customSounds).write(to: indexURL, options: .atomic)
    }
}
