#if DEBUG
import CoreLocation
import Foundation
import MapKit

/// Used with demo data: fixed places in Zürich instead of a real Apple Maps search.
struct DemoPlaceSearch: PlaceSearching {
    /// Where the demo user is: Zürich, near the lake.
    static let userCoordinate = CLLocationCoordinate2D(latitude: 47.3686, longitude: 8.5392)

    func places(matching query: String, in region: MKCoordinateRegion) async throws -> [MKMapItem] {
        let places: [(name: String, latitude: Double, longitude: Double)] = [
            ("Trattoria Lucia", 47.3712, 8.5434),
            ("Osteria al Ponte", 47.3668, 8.5446),
            ("Pasta & Vino", 47.3741, 8.5371),
            ("Ristorante Bellavista", 47.3633, 8.5481),
            ("Pizzeria am Limmatquai", 47.3755, 8.5442),
        ]
        return places.map { place in
            let item = MKMapItem(location: CLLocation(latitude: place.latitude, longitude: place.longitude), address: nil)
            item.name = place.name
            return item
        }
    }
}
#endif
