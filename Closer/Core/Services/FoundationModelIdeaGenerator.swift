import Foundation
import FoundationModels

/// Generates ideas with Apple's on-device language model (Apple Intelligence). Free, offline and
/// private: nothing leaves the iPhone. Devices without Apple Intelligence report `.unsupported`.
final class FoundationModelIdeaGenerator: IdeaGenerating {
    private let model: SystemLanguageModel

    init(model: SystemLanguageModel = .default) {
        self.model = model
    }

    var availability: IdeaAvailability {
        let availability = model.availability
        if case .available = availability { return .available }
        if case .unavailable(.appleIntelligenceNotEnabled) = availability { return .notEnabled }
        if case .unavailable(.modelNotReady) = availability { return .notReady }
        return .unsupported
    }

    func ideas(for request: IdeaRequest) async throws -> [Idea] {
        guard availability == .available else { throw IdeaGenerationError.unavailable }

        // A fresh session per request: ideas do not build on each other, and a long transcript
        // would only eat into the model's small context window.
        let session = LanguageModelSession(instructions: IdeaPrompt.instructions)
        do {
            let response = try await session.respond(
                to: IdeaPrompt.prompt(for: request),
                generating: GeneratedIdeaList.self,
                options: GenerationOptions(temperature: 0.9)
            )
            let ideas = response.content.ideas.compactMap { generated in
                Idea.cleaned(
                    emoji: generated.emoji,
                    title: generated.title,
                    detail: generated.detail,
                    placeSearch: generated.placeSearch,
                    category: request.category
                )
            }
            guard !ideas.isEmpty else { throw IdeaGenerationError.failed }
            return Array(ideas.prefix(request.count))
        } catch let error as LanguageModelSession.GenerationError {
            throw Self.map(error)
        }
    }

    private static func map(_ error: LanguageModelSession.GenerationError) -> IdeaGenerationError {
        switch error {
        case .guardrailViolation: .declined
        case .unsupportedLanguageOrLocale: .unsupportedLanguage
        case .assetsUnavailable: .unavailable
        default: .failed
        }
    }
}
