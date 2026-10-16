import Foundation
import Testing
@testable import Closer

@MainActor
struct IdeaPromptTests {
    private let calendar = TestCalendar.zurich
    /// Monday, 12 October 2026, 10:00.
    private let monday = TestCalendar.date(2026, 10, 12, 10)

    // MARK: - Request from a person

    @Test func requestUsesTheFirstNameAndTheAnniversary() {
        let lea = Person(
            name: "Lea Brunner",
            relationship: .partner,
            anniversary: Anniversary(date: TestCalendar.date(2023, 11, 4))
        )
        let request = IdeaRequest(person: lea, category: .gift, budget: .small, now: monday, calendar: calendar)

        #expect(request.name == "Lea")
        #expect(request.yearsTogether == 2)
        #expect(request.daysUntilAnniversary == 23)
    }

    @Test func requestIgnoresAnniversaryOfSomeoneWhoIsNotThePartner() {
        let mama = Person(name: "Mama", relationship: .family, anniversary: Anniversary(date: TestCalendar.date(2020, 1, 1)))
        let request = IdeaRequest(person: mama, category: .activity, budget: .medium, now: monday, calendar: calendar)

        #expect(request.name == "Mama")
        #expect(request.yearsTogether == nil)
        #expect(request.daysUntilAnniversary == nil)
    }

    @Test func firstNameOfASingleWordIsTheWord() {
        #expect(IdeaRequest.firstName(of: "  Opa ") == "Opa")
        #expect(IdeaRequest.firstName(of: "Anna Maria Muster") == "Anna")
    }

    // MARK: - Prompt text

    @Test func promptDescribesTaskRelationshipAndBudget() {
        let request = IdeaRequest(name: "Lea", relationship: .partner, category: .date, budget: .generous)
        let prompt = IdeaPrompt.prompt(for: request)

        #expect(prompt.contains("Schlage 5 Ideen für ein Date mit Lea vor."))
        #expect(prompt.contains("meine Partnerin oder mein Partner"))
        #expect(prompt.contains(IdeaBudget.generous.promptText))
    }

    @Test func dateWithFamilyIsAGetTogether() {
        let request = IdeaRequest(name: "Mama", relationship: .family, category: .date, budget: .small)
        #expect(IdeaPrompt.prompt(for: request).contains("Ideen für ein Treffen mit Mama vor"))
    }

    @Test func customRelationshipUsesItsLabel() {
        let request = IdeaRequest(name: "Sara", relationship: .other("Nachbarin"), category: .gift, budget: .small)
        #expect(IdeaPrompt.prompt(for: request).contains("Sara ist für mich: Nachbarin."))
    }

    @Test func promptMentionsAnUpcomingAnniversaryAndYears() {
        let request = IdeaRequest(name: "Lea", relationship: .partner, category: .gift, budget: .medium,
                                  yearsTogether: 3, daysUntilAnniversary: 12)
        let prompt = IdeaPrompt.prompt(for: request)

        #expect(prompt.contains("seit 3 Jahren zusammen"))
        #expect(prompt.contains("In 12 Tagen ist unser Jahrestag."))
    }

    @Test func distantAnniversaryIsLeftOut() {
        let request = IdeaRequest(name: "Lea", relationship: .partner, category: .gift, budget: .medium,
                                  yearsTogether: 1, daysUntilAnniversary: 200)
        let prompt = IdeaPrompt.prompt(for: request)

        #expect(prompt.contains("seit 1 Jahr zusammen"))
        #expect(!prompt.contains("Jahrestag"))
    }

    @Test func noteAndExcludedTitlesAreIncludedOnlyWhenPresent() {
        var request = IdeaRequest(name: "Lea", relationship: .partner, category: .date, budget: .medium)
        #expect(!IdeaPrompt.prompt(for: request).contains("Das weiss ich"))
        #expect(!IdeaPrompt.prompt(for: request).contains("noch einmal"))

        request.note = "  mag Sushi und wandert gern \n"
        request.excludedTitles = ["Pasta-Abend", "Kino"]
        let prompt = IdeaPrompt.prompt(for: request)

        #expect(prompt.contains("Das weiss ich über Lea: mag Sushi und wandert gern"))
        #expect(prompt.contains("Pasta-Abend; Kino"))
    }

    @Test func instructionsAskForGermanAndAMapsSearchTerm() {
        #expect(IdeaPrompt.instructions.contains("Deutsch"))
        #expect(IdeaPrompt.instructions.contains("Apple Karten"))
    }
}
