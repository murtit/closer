import Foundation
import Testing
@testable import Closer

@MainActor
struct NotificationSoundTests {
    @Test func offersFiveOfClosersOwnSounds() {
        #expect(NotificationSound.bundled == [.naehe, .funke, .tropfen, .morgen, .gruss])
        #expect(!NotificationSound.bundled.contains(.standard))
    }

    @Test func titlesAreUnique() {
        let titles = ([.standard] + NotificationSound.bundled).map(\.title)
        #expect(Set(titles).count == titles.count)
    }

    @Test func fileNamesPointToTheBundleOrToLibrarySounds() {
        let id = UUID()
        #expect(NotificationSound.standard.fileName == nil)
        #expect(NotificationSound.custom(id).fileName == "\(id.uuidString).caf")
        for sound in NotificationSound.bundled {
            #expect(sound.fileName == "closer-\(sound.id).wav")
        }
    }

    @Test func storedValuesRoundTrip() throws {
        for sound in [.standard, .custom(UUID())] + NotificationSound.bundled {
            let data = try JSONEncoder().encode(sound)
            #expect(try JSONDecoder().decode(NotificationSound.self, from: data) == sound)
        }
    }

    @Test func valuesStoredBeforeCustomSoundsStillDecode() throws {
        let decoded = try JSONDecoder().decode(NotificationSound.self, from: Data(#""naehe""#.utf8))
        #expect(decoded == .naehe)
    }

    @Test func unknownStoredValueFallsBackToTheDefault() throws {
        for stored in [#""klingeling""#, #""custom-kaputt""#] {
            #expect(try JSONDecoder().decode(NotificationSound.self, from: Data(stored.utf8)) == .standard)
        }
    }

    @Test func customSoundIsNamedAfterItsFile() {
        #expect(CustomSound.name(forFile: URL(filePath: "/tmp/Lachen von Lea.m4a")) == "Lachen von Lea")
        #expect(CustomSound.name(forFile: URL(filePath: "/tmp/ .mp3")) == "Eigener Ton")
        #expect(CustomSound.name(forFile: URL(filePath: "/tmp/\(String(repeating: "a", count: 60)).wav")).count == 40)
    }
}
