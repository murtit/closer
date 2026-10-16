import CoreLocation
import Foundation
import Observation

/// Finds the user's position once, to search for places nearby. Asks for "while using the app"
/// permission the first time (`NSLocationWhenInUseUsageDescription`).
@Observable
final class LocationProvider {
    enum Status: Equatable {
        case idle
        case locating
        case located
        /// Permission denied or location services off. Places are searched around the map instead.
        case denied
    }

    private(set) var coordinate: CLLocationCoordinate2D?
    private(set) var status: Status

    /// Fixed position for demo data and tests; never asks for permission.
    private let fixedCoordinate: CLLocationCoordinate2D?
    /// Keeps the authorization alive while locating.
    @ObservationIgnored private var session: CLServiceSession?

    init(fixedCoordinate: CLLocationCoordinate2D? = nil) {
        self.fixedCoordinate = fixedCoordinate
        coordinate = fixedCoordinate
        status = fixedCoordinate == nil ? .idle : .located
    }

    /// Waits for the first position, until permission is denied, or until the task is cancelled
    /// (e.g. when the map closes).
    func locate() async {
        guard fixedCoordinate == nil, status != .locating else { return }
        status = .locating
        session = CLServiceSession(authorization: .whenInUse)
        defer {
            session = nil
            if status == .locating { status = coordinate == nil ? .idle : .located }
        }
        do {
            for try await update in CLLocationUpdate.liveUpdates() {
                if update.authorizationDenied || update.authorizationDeniedGlobally {
                    status = .denied
                    return
                }
                if let location = update.location {
                    coordinate = location.coordinate
                    status = .located
                    return
                }
            }
        } catch {
            // Keeps the last known position, if any; see `defer`.
        }
    }
}
