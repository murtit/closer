import Testing
@testable import Closer

@MainActor
struct IdeaCategoryTests {
    @Test func dateIsOnlyCalledDateForThePartner() {
        #expect(IdeaCategory.date.title(for: .partner) == "Date")
        #expect(IdeaCategory.date.title(for: .family) == "Treffen")
        #expect(IdeaCategory.date.title(for: .friend) == "Treffen")
        #expect(IdeaCategory.gift.title(for: .friend) == "Geschenk")
    }

    @Test func partnerStartsWithDatesOthersWithActivities() {
        #expect(IdeaCategory.preferred(for: .partner) == .date)
        #expect(IdeaCategory.preferred(for: .family) == .activity)
        #expect(IdeaCategory.preferred(for: .other("Nachbarin")) == .activity)
    }

    @Test func everyCategoryHasAFallbackSearch() {
        for category in IdeaCategory.allCases {
            #expect(!category.fallbackPlaceSearch.isEmpty)
            #expect(!category.emoji.isEmpty)
        }
    }
}
