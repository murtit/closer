#if DEBUG
import Foundation

extension DemoData {
    /// Fixed ideas and places around a fixed position, without Apple Intelligence, Apple Maps
    /// search or the location prompt.
    static func makeIdeaServices() -> IdeaServices {
        IdeaServices(
            generator: DemoIdeaGenerator(),
            placeSearch: DemoPlaceSearch(),
            location: LocationProvider(fixedCoordinate: DemoPlaceSearch.userCoordinate)
        )
    }
}
#endif
