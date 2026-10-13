import Foundation

/// Persists people (incl. their reminders and photos) as a JSON file in Application Support.
///
/// A file instead of `UserDefaults` because contact photos would bloat the defaults plist.
struct PeopleStore {
    let fileURL: URL

    init(fileURL: URL = PeopleStore.defaultURL) {
        self.fileURL = fileURL
    }

    static var defaultURL: URL {
        URL.applicationSupportDirectory.appending(path: "people.json")
    }

    /// Returns an empty list when nothing was saved yet.
    func load() throws -> [Person] {
        guard FileManager.default.fileExists(atPath: fileURL.path()) else { return [] }
        let data = try Data(contentsOf: fileURL)
        return try JSONDecoder().decode([Person].self, from: data)
    }

    func save(_ people: [Person]) throws {
        try FileManager.default.createDirectory(
            at: fileURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        let data = try JSONEncoder().encode(people)
        try data.write(to: fileURL, options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication])
    }
}
