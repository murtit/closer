import Foundation

/// Why no ideas could be generated, independent of the Foundation Models types.
enum IdeaGenerationError: Error, Equatable {
    /// The model's safety guardrails declined the request, usually because of the note.
    case declined
    /// The model does not support the device's language.
    case unsupportedLanguage
    /// Apple Intelligence is off or its model is not available right now.
    case unavailable
    /// Anything else, e.g. the model returned nothing usable.
    case failed

    /// Shown to the user in place of the ideas.
    var message: String {
        switch self {
        case .declined:
            "Dazu kann Apple Intelligence keine Ideen vorschlagen. Formuliere deinen Hinweis anders oder lass ihn weg."
        case .unsupportedLanguage:
            "Apple Intelligence unterstützt die Sprache deines iPhones noch nicht."
        case .unavailable:
            "Apple Intelligence ist gerade nicht verfügbar. Versuch es später noch einmal."
        case .failed:
            "Das hat nicht geklappt. Versuch es noch einmal."
        }
    }
}
