import Foundation
import Observation

/// What the ideas feature needs: the language model, the place search and the user's position.
/// Injected with `.environment(_:)` like `PeopleViewModel`, so demo data and tests can swap them.
@Observable
final class IdeaServices {
    let generator: any IdeaGenerating
    let placeSearch: any PlaceSearching
    let location: LocationProvider
    /// Last known availability; refresh with `refreshAvailability()` when the app becomes active.
    private(set) var availability: IdeaAvailability

    init(
        generator: any IdeaGenerating = FoundationModelIdeaGenerator(),
        placeSearch: any PlaceSearching = MapKitPlaceSearch(),
        location: LocationProvider = LocationProvider()
    ) {
        self.generator = generator
        self.placeSearch = placeSearch
        self.location = location
        availability = generator.availability
    }

    func refreshAvailability() {
        let current = generator.availability
        if current != availability { availability = current }
    }

    /// While the model is still downloading, checks again every `interval` until it is ready (or
    /// anything else) or the task is cancelled, e.g. when the ideas screen closes. iOS does not
    /// notify apps when the download finishes.
    func waitWhileModelLoads(checkingEvery interval: Duration = .seconds(3)) async {
        refreshAvailability()
        while availability == .notReady, !Task.isCancelled {
            try? await Task.sleep(for: interval)
            refreshAvailability()
        }
    }
}
