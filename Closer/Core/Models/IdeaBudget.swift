import Foundation

/// Roughly how much an idea may cost.
enum IdeaBudget: String, CaseIterable, Identifiable {
    case small
    case medium
    case generous

    var id: String { rawValue }

    var title: String {
        switch self {
        case .small: "Günstig"
        case .medium: "Mittel"
        case .generous: "Grosszügig"
        }
    }

    /// How the budget is described to the language model.
    var promptText: String {
        switch self {
        case .small: "klein, höchstens etwa 30 Franken oder gratis"
        case .medium: "mittel, etwa 30 bis 100 Franken"
        case .generous: "grosszügig, gern auch über 100 Franken"
        }
    }
}
