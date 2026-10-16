import Foundation

/// A suggestion for a date, a gift or something to do together, written by the on-device model.
struct Idea: Identifiable, Equatable, Hashable {
    var id: UUID
    var emoji: String
    var title: String
    var detail: String
    /// Search term for Apple Maps that finds matching shops, restaurants or places nearby.
    var placeSearch: String

    init(id: UUID = UUID(), emoji: String, title: String, detail: String, placeSearch: String) {
        self.id = id
        self.emoji = emoji
        self.title = title
        self.detail = detail
        self.placeSearch = placeSearch
    }

    /// Tidies what the model returned: trims whitespace and quotes, keeps only the first emoji
    /// and falls back to the category's emoji and search term where something is missing.
    /// Returns `nil` for an idea without a title.
    static func cleaned(
        emoji: String,
        title: String,
        detail: String,
        placeSearch: String,
        category: IdeaCategory
    ) -> Idea? {
        let title = tidy(title)
        guard !title.isEmpty else { return nil }
        let search = tidy(placeSearch)
        return Idea(
            emoji: firstEmoji(in: emoji) ?? category.emoji,
            title: title,
            detail: tidy(detail),
            placeSearch: search.isEmpty ? category.fallbackPlaceSearch : search
        )
    }

    /// A reminder to put the idea into practice, a week from now.
    func makeReminder(now: Date = Date(), calendar: Calendar = .current) -> Reminder {
        Reminder(title: title, emoji: emoji, schedule: .once(in: 7, from: now, calendar: calendar))
    }

    // MARK: - Helpers

    private static func tidy(_ text: String) -> String {
        text.trimmingCharacters(in: .whitespacesAndNewlines.union(CharacterSet(charactersIn: "\"„“”«»")))
    }

    static func firstEmoji(in text: String) -> String? {
        text.first { character in
            character.unicodeScalars.contains { $0.properties.isEmojiPresentation }
                || (character.unicodeScalars.count > 1 && character.unicodeScalars.first?.properties.isEmoji == true)
        }
        .map { String($0) }
    }
}
