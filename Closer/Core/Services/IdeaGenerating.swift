import Foundation

/// Abstraction over the language model, so views and tests do not depend on Foundation Models.
protocol IdeaGenerating {
    /// Read freshly each time: the user can turn Apple Intelligence on, or the model finishes
    /// downloading, while the app is running.
    var availability: IdeaAvailability { get }
    /// Throws an `IdeaGenerationError`.
    func ideas(for request: IdeaRequest) async throws -> [Idea]
}
