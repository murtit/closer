import Foundation
import Testing
@testable import Closer

@MainActor
struct PersonTests {
    @Test func initialsUseFirstTwoWords() {
        #expect(Person.initials(for: "Anna Muster") == "AM")
        #expect(Person.initials(for: "opa") == "O")
        #expect(Person.initials(for: "Hans Peter Muster") == "HP")
        #expect(Person.initials(for: "  ") == "?")
    }

    @Test func dialableStripsFormatting() {
        #expect(Person.dialable("+41 79 123 45 67") == "+41791234567")
        #expect(Person.dialable("(044) 123-45-67") == "0441234567")
    }

    @Test func contactURLsAreBuiltFromPhoneAndEmail() {
        let person = Person(name: "Opa", relationship: .family, phoneNumber: "+41 79 123 45 67", email: "opa@example.ch")
        #expect(person.phoneURL?.absoluteString == "tel:+41791234567")
        #expect(person.messageURL?.absoluteString == "sms:+41791234567")
        #expect(person.emailURL?.absoluteString == "mailto:opa@example.ch")
    }

    @Test func contactURLsAreNilWithoutData() {
        let person = Person(name: "Opa", relationship: .family, phoneNumber: "", email: nil)
        #expect(person.phoneURL == nil)
        #expect(person.messageURL == nil)
        #expect(person.emailURL == nil)
    }

    @Test func openSuggestionsSkipExistingRemindersCaseInsensitively() {
        let person = Person(
            name: "Sara",
            relationship: .partner,
            reminders: [Reminder(title: "blumen kaufen", emoji: "💐")]
        )
        #expect(!person.openSuggestions.map(\.title).contains("Blumen kaufen"))
        #expect(person.openSuggestions.count == Relationship.partner.suggestions.count - 1)
    }

    @Test func nextReminderPicksTheSoonestEnabledOne() {
        let calendar = TestCalendar.zurich
        let monday = TestCalendar.date(2026, 10, 12, 10)
        let daily = Reminder(title: "Kompliment", emoji: "💬", schedule: .init(frequency: .daily, hour: 9))
        let weekly = Reminder(title: "Date", emoji: "🍷", schedule: .init(frequency: .weekly, hour: 12, weekday: 3))
        let paused = Reminder(title: "Pausiert", emoji: "⏸️", isEnabled: false, schedule: .init(frequency: .daily, hour: 11))
        let person = Person(name: "Sara", relationship: .partner, reminders: [weekly, paused, daily])

        let next = person.nextReminder(after: monday, calendar: calendar)
        #expect(next?.reminder == daily)
        #expect(next?.date == TestCalendar.date(2026, 10, 13, 9))
    }

    @Test func codableRoundTripPreservesAllFields() throws {
        let original = Person(
            name: "Lukas",
            relationship: .other("Studienkollege"),
            phoneNumber: "+41 79 000 00 00",
            email: "lukas@example.ch",
            photoData: Data([0x01, 0x02, 0x03]),
            contactIdentifier: "ABC-123",
            reminders: [Reminder(title: "Melden", emoji: "👋", schedule: .once(in: 14))]
        )
        let data = try JSONEncoder().encode(original)
        #expect(try JSONDecoder().decode(Person.self, from: data) == original)
    }
}
