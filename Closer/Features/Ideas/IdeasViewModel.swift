import Foundation
import Observation

/// State of the ideas screen for one person: what to ask for, and the ideas the model returned.
@Observable
final class IdeasViewModel {
    enum Phase: Equatable {
        case idle
        case loading
        case loaded
        case failed(IdeaGenerationError)
    }

    let person: Person

    /// Changing the category starts over, the ideas shown belong to the old one.
    var category: IdeaCategory {
        didSet {
            guard category != oldValue else { return }
            reset()
        }
    }
    var budget: IdeaBudget = .medium
    /// Optional hint about the person, e.g. "mag Sushi und wandert gern".
    var note = ""

    private(set) var ideas: [Idea] = []
    private(set) var phase: Phase = .idle
    /// Ideas the user turned into a reminder.
    private(set) var savedIdeaIDs: Set<Idea.ID> = []

    /// Every title shown for the current category, so "Neue Ideen" does not repeat them.
    @ObservationIgnored private var shownTitles: [String] = []
    private let generator: any IdeaGenerating
    private let now: () -> Date

    init(person: Person, generator: any IdeaGenerating, now: @escaping () -> Date = Date.init) {
        self.person = person
        self.generator = generator
        self.now = now
        category = .preferred(for: person.relationship)
    }

    var isLoading: Bool { phase == .loading }

    /// The first name, used in titles and the prompt.
    var name: String { IdeaRequest.firstName(of: person.name) }

    /// Asks the model for ideas. With `more`, the ideas already shown are left out.
    func generate(more: Bool = false) async {
        guard !isLoading else { return }
        if !more { shownTitles = [] }

        let request = IdeaRequest(
            person: person,
            category: category,
            budget: budget,
            note: note,
            excludedTitles: shownTitles,
            now: now()
        )
        phase = .loading

        do {
            let result = try await generator.ideas(for: request)
            // The user may have switched category while waiting; those ideas are stale.
            guard request.category == category else { return }
            ideas = result
            shownTitles += result.map(\.title)
            phase = .loaded
        } catch is CancellationError {
            phase = ideas.isEmpty ? .idle : .loaded
        } catch {
            guard request.category == category else { return }
            phase = .failed(error as? IdeaGenerationError ?? .failed)
        }
    }

    func markSaved(_ idea: Idea) {
        savedIdeaIDs.insert(idea.id)
    }

    func isSaved(_ idea: Idea) -> Bool {
        savedIdeaIDs.contains(idea.id)
    }

    private func reset() {
        ideas = []
        shownTitles = []
        phase = .idle
    }
}
