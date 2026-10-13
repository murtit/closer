import Foundation
import Testing
@testable import Closer

@MainActor
struct ReminderTests {
    @Test func predefinedRemindersAreDisabledAndNotCustom() {
        #expect(!Reminder.predefined.isEmpty)
        #expect(Reminder.predefined.allSatisfy { !$0.isEnabled && !$0.isCustom })
    }

    @Test func predefinedRemindersHaveUniqueIDs() {
        let ids = Set(Reminder.predefined.map(\.id))
        #expect(ids.count == Reminder.predefined.count)
    }

    @Test func codableRoundTripPreservesAllFields() throws {
        let original = Reminder(title: "Anrufen", emoji: "📞", isEnabled: true, isCustom: true)
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(Reminder.self, from: data)
        #expect(decoded == original)
    }
}
