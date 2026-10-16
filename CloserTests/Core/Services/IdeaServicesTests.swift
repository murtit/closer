import CoreLocation
import Testing
@testable import Closer

@MainActor
struct IdeaServicesTests {
    @Test func onlyUnsupportedDevicesHideTheFeature() {
        #expect(IdeaAvailability.available.isShown)
        #expect(IdeaAvailability.notEnabled.isShown)
        #expect(IdeaAvailability.notReady.isShown)
        #expect(!IdeaAvailability.unsupported.isShown)
    }

    @Test func availabilityIsReadAtStartAndOnRefresh() {
        let generator = FakeIdeaGenerator()
        generator.availability = .notReady
        let services = IdeaServices(generator: generator, placeSearch: FakePlaceSearch(), location: LocationProvider(fixedCoordinate: nil))
        #expect(services.availability == .notReady)

        generator.availability = .available
        services.refreshAvailability()
        #expect(services.availability == .available)
    }

    @Test func fixedLocationIsKnownWithoutAsking() async {
        let location = LocationProvider(fixedCoordinate: DemoPlaceSearch.userCoordinate)
        #expect(location.status == .located)
        await location.locate()
        #expect(location.coordinate?.latitude == DemoPlaceSearch.userCoordinate.latitude)
    }

    @Test func waitsWhileTheModelLoadsAndPicksUpWhenItIsReady() async {
        let generator = FakeIdeaGenerator()
        generator.availability = .notReady
        let services = IdeaServices(generator: generator, placeSearch: FakePlaceSearch(), location: LocationProvider(fixedCoordinate: nil))

        let waiting = Task { await services.waitWhileModelLoads(checkingEvery: .milliseconds(10)) }
        try? await Task.sleep(for: .milliseconds(50))
        #expect(services.availability == .notReady)

        generator.availability = .available
        await waiting.value
        #expect(services.availability == .available)
    }

    @Test func stopsWaitingWhenCancelled() async {
        let generator = FakeIdeaGenerator()
        generator.availability = .notReady
        let services = IdeaServices(generator: generator, placeSearch: FakePlaceSearch(), location: LocationProvider(fixedCoordinate: nil))

        let waiting = Task { await services.waitWhileModelLoads(checkingEvery: .milliseconds(10)) }
        waiting.cancel()
        await waiting.value

        #expect(services.availability == .notReady)
    }

    @Test func returnsAtOnceWhenNotLoading() async {
        let generator = FakeIdeaGenerator()
        let services = IdeaServices(generator: generator, placeSearch: FakePlaceSearch(), location: LocationProvider(fixedCoordinate: nil))
        await services.waitWhileModelLoads(checkingEvery: .seconds(60))
        #expect(services.availability == .available)
    }
}
