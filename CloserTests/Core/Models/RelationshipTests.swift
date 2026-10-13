import Foundation
import Testing
@testable import Closer

@MainActor
struct RelationshipTests {
    private let all: [Relationship] = Relationship.builtIn + [.other("Nachbarin")]

    @Test func everyRelationshipOffersSuggestionsWithAtLeastOnePreselected() {
        for relationship in all {
            #expect(!relationship.suggestions.isEmpty, "\(relationship.title)")
            #expect(relationship.suggestions.contains(where: \.isPreselected), "\(relationship.title)")
        }
    }

    @Test func suggestionTitlesAreUniquePerRelationship() {
        for relationship in all {
            let titles = relationship.suggestions.map(\.title)
            #expect(Set(titles).count == titles.count, "\(relationship.title)")
        }
    }

    @Test func partnerSuggestionsCoverTheClassics() {
        let titles = Relationship.partner.suggestions.map(\.title)
        #expect(titles.contains("Blumen kaufen"))
        #expect(titles.contains("Spontanes Date planen"))
        #expect(titles.contains("Ein Kompliment machen"))
    }

    @Test func familySuggestsAWeeklyCall() {
        let call = Relationship.family.suggestions.first
        #expect(call?.emoji == "📞")
        #expect(call?.schedule.frequency == .weekly)
    }

    @Test func friendSuggestsAOneOffNudgeToFollowUp() {
        let first = Relationship.friend.suggestions.first
        #expect(first?.schedule.frequency == .once)
        #expect(first?.isPreselected == true)
    }

    @Test func otherUsesItsLabelAsTitle() {
        #expect(Relationship.other("Arbeitskollege").title == "Arbeitskollege")
        #expect(Relationship.other("  ").title == "Andere")
        #expect(Relationship.other("x").isOther)
        #expect(!Relationship.partner.isOther)
    }

    @Test func codableRoundTripKeepsCustomLabel() throws {
        let original: [Relationship] = [.partner, .family, .friend, .other("Nachbarin")]
        let data = try JSONEncoder().encode(original)
        #expect(try JSONDecoder().decode([Relationship].self, from: data) == original)
    }

    @Test func suggestionCreatesEnabledReminderWithItsSchedule() {
        let suggestion = Relationship.family.suggestions[0]
        let reminder = suggestion.makeReminder()
        #expect(reminder.title == suggestion.title)
        #expect(reminder.emoji == suggestion.emoji)
        #expect(reminder.schedule == suggestion.schedule)
        #expect(reminder.isEnabled)
    }
}
