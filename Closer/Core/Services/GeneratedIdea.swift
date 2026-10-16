import Foundation
import FoundationModels

/// One idea as the model generates it. Converted into `Idea` by `FoundationModelIdeaGenerator`.
@Generable
nonisolated struct GeneratedIdea {
    @Guide(description: "Genau ein passendes Emoji")
    var emoji: String

    @Guide(description: "Kurzer, einladender Titel mit höchstens sechs Wörtern")
    var title: String

    @Guide(description: "Ein bis zwei Sätze: was man konkret macht und warum es Freude macht")
    var detail: String

    @Guide(description: "Suchbegriff für Apple Karten mit ein bis drei Wörtern, z. B. Blumenladen oder Sushi-Restaurant")
    var placeSearch: String
}
