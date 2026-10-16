import Foundation
import MapKit

/// Abstraction over `MKLocalSearch`, so the places screen can be tested without network.
protocol PlaceSearching {
    func places(matching query: String, in region: MKCoordinateRegion) async throws -> [MKMapItem]
}

/// Searches Apple Maps for points of interest (shops, restaurants, places to go) in a region.
final class MapKitPlaceSearch: PlaceSearching {
    func places(matching query: String, in region: MKCoordinateRegion) async throws -> [MKMapItem] {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query
        request.region = region
        request.resultTypes = .pointOfInterest
        return try await MKLocalSearch(request: request).start().mapItems
    }
}
