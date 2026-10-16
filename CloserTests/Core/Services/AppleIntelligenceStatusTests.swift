import Testing
@testable import Closer

struct AppleIntelligenceStatusTests {
    private func states(_ availability: IdeaAvailability) -> [AppleIntelligenceCheck.State] {
        availability.checks.map(\.state)
    }

    @Test func readyPassesEveryCheck() {
        #expect(states(.available) == [.passed, .passed, .passed])
        #expect(IdeaAvailability.available.statusTitle == "Bereit")
        #expect(!IdeaAvailability.available.offersSettings)
    }

    @Test func turnedOffFailsOnlyTheSecondCheck() {
        #expect(states(.notEnabled) == [.passed, .failed, .skipped])
        #expect(IdeaAvailability.notEnabled.statusTitle == "Ausgeschaltet")
        #expect(IdeaAvailability.notEnabled.offersSettings)
    }

    @Test func loadingShowsTheModelInProgress() {
        #expect(states(.notReady) == [.passed, .passed, .inProgress])
        #expect(IdeaAvailability.notReady.statusTitle == "Wird geladen")
        #expect(IdeaAvailability.notReady.offersSettings)
    }

    @Test func unsupportedSaysSoAndSkipsTheRest() {
        #expect(states(.unsupported) == [.failed, .skipped, .skipped])
        #expect(IdeaAvailability.unsupported.statusTitle == "Nicht unterstützt")
        #expect(IdeaAvailability.unsupported.statusMessage.contains("unterstützt Apple Intelligence nicht"))
        // Nothing in Settings can add Apple Intelligence to an iPhone that lacks it.
        #expect(!IdeaAvailability.unsupported.offersSettings)
    }

    @Test func checksAlwaysAskTheSameThreeQuestions() {
        for availability in [IdeaAvailability.available, .notEnabled, .notReady, .unsupported] {
            #expect(availability.checks.map(\.title) == ["Von diesem iPhone unterstützt", "Eingeschaltet", "Sprachmodell geladen"])
        }
    }
}
