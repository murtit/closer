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
}
