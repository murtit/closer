import Foundation

/// The text sent to the on-device language model. Kept apart from the model so it can be tested.
enum IdeaPrompt {
    /// Instructions of the model session: who it is and the rules every answer follows.
    static let instructions = """
        Du bist die Ideen-Hilfe der App Closer. Closer hilft Menschen, ihren Liebsten nahe zu bleiben. \
        Du schlägst konkrete, persönliche und gut umsetzbare Ideen vor, die Freude machen. \
        Antworte immer auf Deutsch und schreibe „ss“ statt „ß“. \
        Jede Idee unterscheidet sich klar von den anderen. \
        Zu jeder Idee gibst du einen kurzen Suchbegriff für Apple Karten an, mit dem man passende \
        Geschäfte, Restaurants oder Orte in der Nähe findet, zum Beispiel „Blumenladen“, \
        „Italienisches Restaurant“ oder „Kletterhalle“.
        """

    static func prompt(for request: IdeaRequest) -> String {
        var lines = ["Schlage \(request.count) \(task(for: request))."]
        lines.append("\(request.name) ist für mich: \(relationshipText(request.relationship)).")

        if let years = request.yearsTogether, years > 0 {
            lines.append("Wir sind seit \(years) \(years == 1 ? "Jahr" : "Jahren") zusammen.")
        }
        if let days = request.daysUntilAnniversary, days <= 30 {
            lines.append(days == 0 ? "Heute ist unser Jahrestag." : "In \(days) \(days == 1 ? "Tag" : "Tagen") ist unser Jahrestag.")
        }

        lines.append("Budget: \(request.budget.promptText).")

        let note = request.note.trimmingCharacters(in: .whitespacesAndNewlines)
        if !note.isEmpty {
            lines.append("Das weiss ich über \(request.name): \(note)")
        }

        let excluded = request.excludedTitles.filter { !$0.isEmpty }
        if !excluded.isEmpty {
            lines.append("Schlage nichts davon noch einmal vor: \(excluded.joined(separator: "; ")).")
        }
        return lines.joined(separator: "\n")
    }

    // MARK: - Parts

    static func task(for request: IdeaRequest) -> String {
        switch request.category {
        case .date where request.relationship == .partner:
            "Ideen für ein Date mit \(request.name) vor"
        case .date:
            "Ideen für ein Treffen mit \(request.name) vor"
        case .gift:
            "Geschenkideen für \(request.name) vor"
        case .activity:
            "Ideen vor, was ich mit \(request.name) unternehmen kann"
        }
    }

    static func relationshipText(_ relationship: Relationship) -> String {
        switch relationship {
        case .partner: "meine Partnerin oder mein Partner"
        case .family: "ein Familienmitglied"
        case .friend: "eine Freundin oder ein Freund"
        case .other: relationship.title
        }
    }
}
