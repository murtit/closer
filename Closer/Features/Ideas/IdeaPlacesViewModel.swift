import CoreLocation
import Foundation
import MapKit
import Observation

/// Places in Apple Maps that fit an idea, e.g. flower shops for "Blumen zum Feierabend".
@Observable
final class IdeaPlacesViewModel {
    enum Phase: Equatable {
        case idle
        case searching
        case loaded
        case empty
        case failed
    }

    let query: String
    private(set) var places: [MKMapItem] = []
    private(set) var phase: Phase = .idle
    /// Where the last search looked; the map offers "Hier suchen" once it moves away from it.
    private(set) var searchedRegion: MKCoordinateRegion?

    private let placeSearch: any PlaceSearching

    /// How far around the user to look, in metres.
    static let searchRadius: CLLocationDistance = 4_000
    static let maximumResults = 12

    /// Shown until the user's position is known or when location access is denied.
    static let fallbackCenter = CLLocationCoordinate2D(latitude: 47.3769, longitude: 8.5417) // Zürich

    init(query: String, placeSearch: any PlaceSearching) {
        self.query = query
        self.placeSearch = placeSearch
    }

    static func region(around center: CLLocationCoordinate2D) -> MKCoordinateRegion {
        MKCoordinateRegion(center: center, latitudinalMeters: searchRadius * 2, longitudinalMeters: searchRadius * 2)
    }

    func search(around center: CLLocationCoordinate2D) async {
        await search(in: Self.region(around: center))
    }

    /// Looks for places in `region`, nearest to its centre first.
    func search(in region: MKCoordinateRegion) async {
        phase = .searching
        searchedRegion = region
        do {
            let found = try await placeSearch.places(matching: query, in: region)
            let center = CLLocation(latitude: region.center.latitude, longitude: region.center.longitude)
            places = Array(
                found
                    .sorted { $0.location.distance(from: center) < $1.location.distance(from: center) }
                    .prefix(Self.maximumResults)
            )
            phase = places.isEmpty ? .empty : .loaded
        } catch is CancellationError {
            phase = places.isEmpty ? .idle : .loaded
        } catch {
            places = []
            // MapKit reports "nothing found" as an error rather than an empty result.
            if (error as? MKError)?.code == .placemarkNotFound {
                phase = .empty
            } else {
                phase = .failed
            }
        }
    }

    /// Takes `region` as the searched area, e.g. once the map has zoomed to fit the results, so
    /// "Hier suchen" only appears after the user moves the map.
    func markSearched(_ region: MKCoordinateRegion) {
        searchedRegion = region
    }

    /// Whether `region` is far enough from the last search to offer searching there.
    func shouldOfferSearch(in region: MKCoordinateRegion) -> Bool {
        guard let searchedRegion, phase != .searching else { return false }
        let old = CLLocation(latitude: searchedRegion.center.latitude, longitude: searchedRegion.center.longitude)
        let new = CLLocation(latitude: region.center.latitude, longitude: region.center.longitude)
        let zoomChanged = abs(region.span.latitudeDelta / searchedRegion.span.latitudeDelta - 1) > 0.5
        return old.distance(from: new) > Self.searchRadius / 2 || zoomChanged
    }

    /// "350 m" or "2.4 km" from `coordinate`, or `nil` if the position is unknown.
    static func distanceText(
        to place: MKMapItem,
        from coordinate: CLLocationCoordinate2D?,
        locale: Locale = Locale(identifier: "de_CH")
    ) -> String? {
        guard let coordinate else { return nil }
        let metres = place.location.distance(from: CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude))
        let measurement = Measurement(value: metres, unit: UnitLength.meters)
        if metres < 1_000 {
            let rounded = Measurement(value: (metres / 10).rounded() * 10, unit: UnitLength.meters)
            return rounded.formatted(.measurement(width: .abbreviated, usage: .asProvided).locale(locale))
        }
        return measurement.converted(to: .kilometers)
            .formatted(.measurement(width: .abbreviated, usage: .asProvided, numberFormatStyle: .number.precision(.fractionLength(1))).locale(locale))
    }
}
