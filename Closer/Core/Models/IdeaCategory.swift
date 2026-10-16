import Foundation

/// What the user wants ideas for.
enum IdeaCategory: String, CaseIterable, Identifiable {
    case date
    case gift
    case activity

    var id: String { rawValue }

    /// "Date" only fits the partner; for everyone else it is a get-together.
    func title(for relationship: Relationship) -> String {
        switch self {
        case .date: relationship == .partner ? "Date" : "Treffen"
        case .gift: "Geschenk"
        case .activity: "Unternehmung"
        }
    }

    var emoji: String {
        switch self {
        case .date: "🍷"
        case .gift: "🎁"
        case .activity: "🎟️"
        }
    }

    /// Searched in Apple Maps when the model gives no search term of its own.
    var fallbackPlaceSearch: String {
        switch self {
        case .date: "Restaurant"
        case .gift: "Geschenkladen"
        case .activity: "Freizeitaktivität"
        }
    }

    /// The category the ideas screen starts with for a person.
    static func preferred(for relationship: Relationship) -> IdeaCategory {
        relationship == .partner ? .date : .activity
    }
}
