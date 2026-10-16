import Foundation
import FoundationModels

/// The model's whole answer: a list of ideas.
@Generable
nonisolated struct GeneratedIdeaList {
    @Guide(description: "Die vorgeschlagenen Ideen, alle verschieden")
    var ideas: [GeneratedIdea]
}
