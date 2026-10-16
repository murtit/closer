import CoreLocation
import Foundation
import MapKit
@testable import Closer

/// Returns prepared places or an error and records every search.
@MainActor
final class FakePlaceSearch: PlaceSearching {
    var result: Result<[MKMapItem], Error> = .success([])
    private(set) var searches: [(query: String, region: MKCoordinateRegion)] = []

    func places(matching query: String, in region: MKCoordinateRegion) async throws -> [MKMapItem] {
        searches.append((query, region))
        return try result.get()
    }

    static func place(_ name: String, latitude: Double, longitude: Double) -> MKMapItem {
        let item = MKMapItem(location: CLLocation(latitude: latitude, longitude: longitude), address: nil)
        item.name = name
        return item
    }
}
