#if DEBUG
import Foundation

/// Used with demo data: always available and answers with fixed ideas, so screenshots look the
/// same on every Mac, with or without Apple Intelligence.
struct DemoIdeaGenerator: IdeaGenerating {
    var availability: IdeaAvailability { .available }

    func ideas(for request: IdeaRequest) async throws -> [Idea] {
        switch request.category {
        case .date:
            [
                Idea(emoji: "🍝", title: "Pasta-Abend wie in Rom",
                     detail: "Reserviert einen Tisch beim Italiener um die Ecke und teilt euch zum Dessert ein Tiramisu.",
                     placeSearch: "Italienisches Restaurant"),
                Idea(emoji: "🌅", title: "Sonnenuntergang am See",
                     detail: "Packt eine Decke und etwas Feines ein und schaut zu, wie die Sonne hinter den Hügeln verschwindet.",
                     placeSearch: "Aussichtspunkt"),
                Idea(emoji: "🎨", title: "Gemeinsam töpfern",
                     detail: "Ein Kurs zu zweit, bei dem ihr euch gegenseitig eine Tasse formt.",
                     placeSearch: "Töpferkurs"),
            ]
        case .gift:
            [
                Idea(emoji: "💐", title: "Ein Strauss ihrer Lieblingsblumen",
                     detail: "Lass ihn mit einer handgeschriebenen Karte binden, die an euren ersten Abend erinnert.",
                     placeSearch: "Blumenladen"),
                Idea(emoji: "📚", title: "Ein Buch mit Widmung",
                     detail: "Such einen Roman aus, der zu ihr passt, und schreib vorne hinein, warum.",
                     placeSearch: "Buchhandlung"),
            ]
        case .activity:
            [
                Idea(emoji: "🧗", title: "Bouldern zum Ausprobieren",
                     detail: "Ein Schnupperabend in der Kletterhalle, danach ein Feierabendbier.",
                     placeSearch: "Kletterhalle"),
                Idea(emoji: "🛶", title: "Kanu auf dem Fluss",
                     detail: "Mietet ein Kanu für zwei Stunden und lasst euch treiben.",
                     placeSearch: "Bootsvermietung"),
            ]
        }
    }
}
#endif
