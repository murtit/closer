import Foundation

/// Someone the user wants to stay close to, with their own set of reminders.
struct Person: Identifiable, Codable, Equatable, Hashable {
    var id: UUID
    var name: String
    var relationship: Relationship
    var phoneNumber: String?
    var email: String?
    /// Downscaled JPEG taken from the contact, if any.
    var photoData: Data?
    /// `CNContact.identifier` of the imported contact, so it can be refreshed later.
    var contactIdentifier: String?
    var reminders: [Reminder]
    var createdAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        relationship: Relationship,
        phoneNumber: String? = nil,
        email: String? = nil,
        photoData: Data? = nil,
        contactIdentifier: String? = nil,
        reminders: [Reminder] = [],
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.relationship = relationship
        self.phoneNumber = phoneNumber
        self.email = email
        self.photoData = photoData
        self.contactIdentifier = contactIdentifier
        self.reminders = reminders
        self.createdAt = createdAt
    }

    /// Up to two initials for the avatar placeholder, e.g. "Anna Muster" → "AM".
    var initials: String { Self.initials(for: name) }

    static func initials(for name: String) -> String {
        let parts = name.split(whereSeparator: \.isWhitespace).prefix(2)
        let letters = parts.compactMap(\.first).map { String($0).uppercased() }
        return letters.isEmpty ? "?" : letters.joined()
    }

    var activeReminderCount: Int { reminders.filter(\.isEnabled).count }

    /// The earliest upcoming reminder of this person.
    func nextReminder(after date: Date = Date(), calendar: Calendar = .current) -> (reminder: Reminder, date: Date)? {
        reminders
            .compactMap { reminder in reminder.nextOccurrence(after: date, calendar: calendar).map { (reminder: reminder, date: $0) } }
            .min { $0.date < $1.date }
    }

    /// Suggestions for this person's relationship that are not yet among their reminders.
    var openSuggestions: [ReminderSuggestion] {
        let existing = Set(reminders.map { $0.title.lowercased() })
        return relationship.suggestions.filter { !existing.contains($0.title.lowercased()) }
    }

    // MARK: - Contact actions

    var phoneURL: URL? { Self.url(scheme: "tel", value: phoneNumber.map(Self.dialable)) }
    var messageURL: URL? { Self.url(scheme: "sms", value: phoneNumber.map(Self.dialable)) }
    var emailURL: URL? { Self.url(scheme: "mailto", value: email?.trimmingCharacters(in: .whitespaces)) }

    /// Strips formatting so `tel:` / `sms:` URLs are valid: "+41 79 123 45 67" → "+41791234567".
    static func dialable(_ number: String) -> String {
        number.filter { $0.isNumber || $0 == "+" }
    }

    private static func url(scheme: String, value: String?) -> URL? {
        guard let value, !value.isEmpty else { return nil }
        return URL(string: "\(scheme):\(value)")
    }
}
