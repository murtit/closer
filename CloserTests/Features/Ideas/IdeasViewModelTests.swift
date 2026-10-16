import Foundation
import Testing
@testable import Closer

@MainActor
struct IdeasViewModelTests {
    private let generator = FakeIdeaGenerator()
    private let lea = Person(name: "Lea Brunner", relationship: .partner)

    private func makeViewModel(person: Person? = nil) -> IdeasViewModel {
        IdeasViewModel(person: person ?? lea, generator: generator, now: { TestCalendar.date(2026, 10, 12, 10) })
    }

    private func ideas(_ titles: String...) -> [Idea] {
        titles.map { Idea(emoji: "✨", title: $0, detail: "", placeSearch: "Restaurant") }
    }

    @Test func startsWithTheCategoryThatFitsThePerson() {
        #expect(makeViewModel().category == .date)
        #expect(makeViewModel(person: Person(name: "Mama", relationship: .family)).category == .activity)
        #expect(makeViewModel().phase == .idle)
        #expect(makeViewModel().name == "Lea")
    }

    @Test func generatedIdeasAreShown() async {
        generator.result = .success(ideas("Pasta-Abend", "Picknick"))
        let viewModel = makeViewModel()
        viewModel.budget = .small
        viewModel.note = "mag Sushi"

        await viewModel.generate()

        #expect(viewModel.phase == .loaded)
        #expect(viewModel.ideas.map(\.title) == ["Pasta-Abend", "Picknick"])
        let request = generator.requests.last
        #expect(request?.name == "Lea")
        #expect(request?.category == .date)
        #expect(request?.budget == .small)
        #expect(request?.note == "mag Sushi")
        #expect(request?.excludedTitles == [])
    }

    @Test func moreIdeasLeaveOutEverythingShownSoFar() async {
        let viewModel = makeViewModel()
        generator.result = .success(ideas("Pasta-Abend"))
        await viewModel.generate()
        generator.result = .success(ideas("Picknick"))
        await viewModel.generate(more: true)
        generator.result = .success(ideas("Kino"))
        await viewModel.generate(more: true)

        #expect(generator.requests.map(\.excludedTitles) == [[], ["Pasta-Abend"], ["Pasta-Abend", "Picknick"]])
        #expect(viewModel.ideas.map(\.title) == ["Kino"])
    }

    @Test func generatingAfreshForgetsShownTitles() async {
        let viewModel = makeViewModel()
        generator.result = .success(ideas("Pasta-Abend"))
        await viewModel.generate()
        await viewModel.generate()

        #expect(generator.requests.last?.excludedTitles == [])
    }

    @Test func changingTheCategoryStartsOver() async {
        let viewModel = makeViewModel()
        generator.result = .success(ideas("Pasta-Abend"))
        await viewModel.generate()

        viewModel.category = .gift

        #expect(viewModel.ideas.isEmpty)
        #expect(viewModel.phase == .idle)
        generator.result = .success(ideas("Buch"))
        await viewModel.generate(more: true)
        #expect(generator.requests.last?.excludedTitles == [])
        #expect(generator.requests.last?.category == .gift)
    }

    @Test func settingTheSameCategoryKeepsTheIdeas() async {
        let viewModel = makeViewModel()
        generator.result = .success(ideas("Pasta-Abend"))
        await viewModel.generate()

        viewModel.category = .date

        #expect(viewModel.ideas.count == 1)
        #expect(viewModel.phase == .loaded)
    }

    @Test func generationErrorsAreShown() async {
        generator.result = .failure(IdeaGenerationError.declined)
        let viewModel = makeViewModel()

        await viewModel.generate()

        #expect(viewModel.phase == .failed(.declined))
    }

    @Test func unknownErrorsCountAsFailed() async {
        struct Unexpected: Error { }
        generator.result = .failure(Unexpected())
        let viewModel = makeViewModel()

        await viewModel.generate()

        #expect(viewModel.phase == .failed(.failed))
    }

    @Test func cancellingKeepsWhatWasShown() async {
        let viewModel = makeViewModel()
        generator.result = .success(ideas("Pasta-Abend"))
        await viewModel.generate()

        generator.result = .failure(CancellationError())
        await viewModel.generate(more: true)

        #expect(viewModel.phase == .loaded)
        #expect(viewModel.ideas.map(\.title) == ["Pasta-Abend"])
    }

    @Test func savedIdeasAreRemembered() async {
        generator.result = .success(ideas("Pasta-Abend", "Picknick"))
        let viewModel = makeViewModel()
        await viewModel.generate()

        viewModel.markSaved(viewModel.ideas[0])

        #expect(viewModel.isSaved(viewModel.ideas[0]))
        #expect(!viewModel.isSaved(viewModel.ideas[1]))
    }

    @Test func everyErrorHasAMessage() {
        for error in [IdeaGenerationError.declined, .unsupportedLanguage, .unavailable, .failed] {
            #expect(!error.message.isEmpty)
        }
    }
}
