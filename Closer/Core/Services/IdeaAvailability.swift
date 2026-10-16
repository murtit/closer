import Foundation

/// Whether ideas can be generated on this iPhone.
enum IdeaAvailability: Equatable {
    case available
    /// The device supports Apple Intelligence, but it is turned off in Settings.
    case notEnabled
    /// Apple Intelligence is on, but the model is still downloading.
    case notReady
    /// The device does not support Apple Intelligence. Ideas are hidden entirely.
    case unsupported

    /// Whether the ideas feature appears in the app at all.
    var isShown: Bool { self != .unsupported }
}
