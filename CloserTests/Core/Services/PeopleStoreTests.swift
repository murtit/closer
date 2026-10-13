import Foundation
import Testing
@testable import Closer

@MainActor
struct PeopleStoreTests {
    private let store: PeopleStore

    init() {
        store = PeopleStore(
            fileURL: FileManager.default.temporaryDirectory
                .appending(path: "CloserTests-\(UUID().uuidString)")
                .appending(path: "people.json")
        )
    }

    @Test func loadReturnsEmptyListWhenNothingWasSaved() throws {
        #expect(try store.load().isEmpty)
    }

    @Test func saveThenLoadRoundTrips() throws {
        let people = [
            Person(name: "Sara", relationship: .partner, reminders: [Reminder(title: "Blumen kaufen", emoji: "💐")]),
            Person(name: "Opa", relationship: .family, phoneNumber: "+41 79 123 45 67"),
        ]
        try store.save(people)
        #expect(try store.load() == people)
    }

    @Test func loadThrowsOnCorruptData() throws {
        try FileManager.default.createDirectory(at: store.fileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        try Data("kein json".utf8).write(to: store.fileURL)
        #expect(throws: (any Error).self) { try store.load() }
    }
}
