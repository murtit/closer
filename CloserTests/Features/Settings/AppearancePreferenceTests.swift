import SwiftUI
import Testing
@testable import Closer

@MainActor
struct AppearancePreferenceTests {
    @Test func systemFollowsTheIPhoneSetting() {
        #expect(AppearancePreference.system.colorScheme == nil)
    }

    @Test func lightAndDarkForceTheirScheme() {
        #expect(AppearancePreference.light.colorScheme == .light)
        #expect(AppearancePreference.dark.colorScheme == .dark)
    }

    @Test func offersAllThreeChoicesWithSystemFirst() {
        #expect(AppearancePreference.allCases == [.system, .light, .dark])
        #expect(AppearancePreference.allCases.map(\.title) == ["Wie iPhone", "Hell", "Dunkel"])
    }

    @Test func storedValuesRoundTrip() {
        for preference in AppearancePreference.allCases {
            #expect(AppearancePreference(storedValue: preference.rawValue) == preference)
        }
    }

    @Test func missingOrUnknownValuesFallBackToSystem() {
        #expect(AppearancePreference(storedValue: nil) == .system)
        #expect(AppearancePreference(storedValue: "sepia") == .system)
    }
}
