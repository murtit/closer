import Foundation
@testable import Closer

/// Returns prepared ideas or an error and records every request.
@MainActor
final class FakeIdeaGenerator: IdeaGenerating {
    var availability: IdeaAvailability = .available
    var result: Result<[Idea], Error> = .success([])
    private(set) var requests: [IdeaRequest] = []

    func ideas(for request: IdeaRequest) async throws -> [Idea] {
        requests.append(request)
        return try result.get()
    }
}
