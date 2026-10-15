import Foundation
import Testing
@testable import Closer

@MainActor
struct NotificationSoundTests {
    @Test func offersTheSystemDefaultFirstAndThenClosersOwnSounds() {
        #expect(NotificationSound.allCases.first == .standard)
        #expect(NotificationSound.bundled == Array(NotificationSound.allCases.dropFirst()))
        #expect(NotificationSound.bundled.count >= 3)
    }

    @Test func titlesAreUnique() {
        let titles = NotificationSound.allCases.map(\.title)
        #expect(Set(titles).count == titles.count)
    }

    @Test func onlyBundledSoundsHaveAFile() {
        #expect(NotificationSound.standard.fileName == nil)
        for sound in NotificationSound.bundled {
            #expect(sound.fileName == "closer-\(sound.rawValue).wav")
        }
    }

    @Test func storedValuesRoundTrip() throws {
        for sound in NotificationSound.allCases {
            let data = try JSONEncoder().encode(sound)
            #expect(try JSONDecoder().decode(NotificationSound.self, from: data) == sound)
        }
    }

    @Test func unknownStoredValueFallsBackToTheDefault() throws {
        let decoded = try JSONDecoder().decode(NotificationSound.self, from: Data(#""klingeling""#.utf8))
        #expect(decoded == .standard)
    }
}
