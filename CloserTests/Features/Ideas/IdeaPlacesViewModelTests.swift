import CoreLocation
import Foundation
import MapKit
import Testing
@testable import Closer

@MainActor
struct IdeaPlacesViewModelTests {
    private let search = FakePlaceSearch()
    private let center = CLLocationCoordinate2D(latitude: 47.3686, longitude: 8.5392)

    private func makeViewModel() -> IdeaPlacesViewModel {
        IdeaPlacesViewModel(query: "Blumenladen", placeSearch: search)
    }

    @Test func searchesTheIdeasTermAroundTheCentre() async {
        let viewModel = makeViewModel()

        await viewModel.search(around: center)

        #expect(search.searches.count == 1)
        #expect(search.searches[0].query == "Blumenladen")
        #expect(search.searches[0].region.center.latitude == center.latitude)
        #expect(search.searches[0].region.span.latitudeDelta > 0)
        #expect(viewModel.searchedRegion?.center.longitude == center.longitude)
    }

    @Test func nearestPlacesComeFirst() async {
        search.result = .success([
            FakePlaceSearch.place("Weit", latitude: 47.40, longitude: 8.54),
            FakePlaceSearch.place("Nah", latitude: 47.369, longitude: 8.5393),
            FakePlaceSearch.place("Mittel", latitude: 47.38, longitude: 8.54),
        ])
        let viewModel = makeViewModel()

        await viewModel.search(around: center)

        #expect(viewModel.phase == .loaded)
        #expect(viewModel.places.map(\.name) == ["Nah", "Mittel", "Weit"])
    }

    @Test func resultsAreCapped() async {
        search.result = .success((0..<30).map { FakePlaceSearch.place("Ort \($0)", latitude: 47.37 + Double($0) * 0.001, longitude: 8.54) })
        let viewModel = makeViewModel()

        await viewModel.search(around: center)

        #expect(viewModel.places.count == IdeaPlacesViewModel.maximumResults)
    }

    @Test func noResultsIsEmpty() async {
        let viewModel = makeViewModel()
        await viewModel.search(around: center)
        #expect(viewModel.phase == .empty)
    }

    @Test func mapKitsNotFoundErrorIsEmptyNotFailed() async {
        search.result = .failure(MKError(.placemarkNotFound))
        let viewModel = makeViewModel()
        await viewModel.search(around: center)
        #expect(viewModel.phase == .empty)
    }

    @Test func otherErrorsFailAndClearOldPlaces() async {
        search.result = .success([FakePlaceSearch.place("Nah", latitude: 47.369, longitude: 8.5393)])
        let viewModel = makeViewModel()
        await viewModel.search(around: center)

        search.result = .failure(MKError(.serverFailure))
        await viewModel.search(around: center)

        #expect(viewModel.phase == .failed)
        #expect(viewModel.places.isEmpty)
    }

    // MARK: - Search here

    @Test func searchHereIsOfferedOnceTheMapMovesAway() async {
        let viewModel = makeViewModel()
        let searched = IdeaPlacesViewModel.region(around: center)
        #expect(!viewModel.shouldOfferSearch(in: searched), "Nothing searched yet")

        await viewModel.search(in: searched)
        #expect(!viewModel.shouldOfferSearch(in: searched))

        let nearby = IdeaPlacesViewModel.region(around: CLLocationCoordinate2D(latitude: 47.3696, longitude: 8.5392))
        #expect(!viewModel.shouldOfferSearch(in: nearby), "About 100 m away")

        let otherTown = IdeaPlacesViewModel.region(around: CLLocationCoordinate2D(latitude: 47.50, longitude: 8.72))
        #expect(viewModel.shouldOfferSearch(in: otherTown))

        var zoomedOut = searched
        zoomedOut.span = MKCoordinateSpan(latitudeDelta: searched.span.latitudeDelta * 3, longitudeDelta: searched.span.longitudeDelta * 3)
        #expect(viewModel.shouldOfferSearch(in: zoomedOut))
    }

    @Test func markedRegionBecomesTheSearchedOne() async {
        let viewModel = makeViewModel()
        await viewModel.search(around: center)
        let fitted = IdeaPlacesViewModel.region(around: CLLocationCoordinate2D(latitude: 47.50, longitude: 8.72))

        viewModel.markSearched(fitted)

        #expect(!viewModel.shouldOfferSearch(in: fitted))
    }

    // MARK: - Distance

    @Test func distanceNeedsAPosition() {
        let place = FakePlaceSearch.place("Nah", latitude: 47.369, longitude: 8.5393)
        #expect(IdeaPlacesViewModel.distanceText(to: place, from: nil) == nil)
    }

    @Test func shortDistancesAreInMetresLongOnesInKilometres() throws {
        let near = FakePlaceSearch.place("Nah", latitude: 47.3716, longitude: 8.5392)   // ~330 m
        let far = FakePlaceSearch.place("Weit", latitude: 47.3906, longitude: 8.5392)   // ~2.4 km

        let nearText = try #require(IdeaPlacesViewModel.distanceText(to: near, from: center))
        let farText = try #require(IdeaPlacesViewModel.distanceText(to: far, from: center))

        #expect(nearText.hasSuffix("m") && !nearText.contains("km"))
        #expect(nearText.contains("330"))
        #expect(farText.hasSuffix("km"))
        #expect(farText.contains("2"))
    }
}
