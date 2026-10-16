import MapKit
import SwiftUI

/// An Apple Maps map with places nearby that fit an idea, e.g. flower shops, restaurants or a
/// climbing gym. Tapping a place opens Apple's place card with opening hours, route and more.
struct IdeaPlacesView: View {
    @Environment(IdeaServices.self) private var services
    let idea: Idea
    @State private var viewModel: IdeaPlacesViewModel
    @State private var position: MapCameraPosition = .region(IdeaPlacesViewModel.region(around: IdeaPlacesViewModel.fallbackCenter))
    @State private var selection: MKMapItem?
    @State private var visibleRegion: MKCoordinateRegion?
    /// Set while the camera moves to fit the results, so that move does not count as the user's.
    @State private var isFittingCamera = false
    /// Whether the last search was around the user and not the fallback.
    @State private var searchedAroundUser = false

    init(idea: Idea, viewModel: IdeaPlacesViewModel) {
        self.idea = idea
        _viewModel = State(initialValue: viewModel)
    }

    private var location: LocationProvider { services.location }

    private var offersSearchHere: Bool {
        guard !isFittingCamera, let visibleRegion else { return false }
        return viewModel.shouldOfferSearch(in: visibleRegion)
    }

    var body: some View {
        Map(position: $position, selection: $selection) {
            UserAnnotation()
            ForEach(viewModel.places, id: \.self) { place in
                Marker(item: place)
                    .tint(.closerAccent)
                    .tag(place)
            }
        }
        // Only the results carry a pin, other points of interest would compete with them.
        .mapStyle(.standard(pointsOfInterest: .excludingAll))
        .mapControls {
            MapUserLocationButton()
            MapCompass()
            MapScaleView()
        }
        .onMapCameraChange(frequency: .onEnd) { context in
            if isFittingCamera {
                viewModel.markSearched(context.region)
                isFittingCamera = false
            }
            visibleRegion = context.region
        }
        .mapItemDetailSheet(item: $selection)
        .overlay(alignment: .top) { statusBar }
        .safeAreaInset(edge: .bottom) { placesStrip }
        .navigationTitle(idea.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.visible, for: .navigationBar)
        .task { await location.locate() }
        .task { await initialSearch() }
        .onChange(of: location.status) { _, status in
            // The position arrived after searching around the fallback: search again around the user.
            guard status == .located, !searchedAroundUser, !offersSearchHere else { return }
            Task { await searchAroundBestPosition() }
        }
    }

    // MARK: - Overlays

    @ViewBuilder
    private var statusBar: some View {
        Group {
            switch viewModel.phase {
            case .searching:
                HStack(spacing: 8) {
                    ProgressView()
                    Text("Suche „\(viewModel.query)“ …")
                }
                .statusCapsule()
            case .empty:
                Label("Keine passenden Orte in diesem Gebiet", systemImage: "mappin.slash")
                    .statusCapsule()
            case .failed:
                Button {
                    Task { await searchAroundBestPosition() }
                } label: {
                    Label("Orte konnten nicht geladen werden. Erneut versuchen", systemImage: "arrow.clockwise")
                }
                .buttonStyle(.plain)
                .statusCapsule()
            case .idle, .loaded:
                if offersSearchHere, let visibleRegion {
                    Button {
                        selection = nil
                        Task { await search(in: visibleRegion) }
                    } label: {
                        Label("In diesem Gebiet suchen", systemImage: "magnifyingglass")
                            .font(.subheadline.weight(.semibold))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 4)
                    }
                    .buttonStyle(.glass)
                    .accessibilityIdentifier("searchHereButton")
                } else if location.status == .denied {
                    Label("Ohne Standort sucht Closer im Kartenausschnitt", systemImage: "location.slash")
                        .statusCapsule()
                }
            }
        }
        .padding(.top, 10)
        .padding(.horizontal, 16)
        .animation(.smooth, value: viewModel.phase)
        .animation(.smooth, value: offersSearchHere)
    }

    @ViewBuilder
    private var placesStrip: some View {
        if !viewModel.places.isEmpty {
            ScrollView(.horizontal) {
                HStack(spacing: 12) {
                    ForEach(viewModel.places, id: \.self) { place in
                        Button {
                            selection = place
                        } label: {
                            PlaceCardView(
                                place: place,
                                distance: IdeaPlacesViewModel.distanceText(to: place, from: location.coordinate),
                                isSelected: place == selection
                            )
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("placeCard")
                    }
                }
                .scrollTargetLayout()
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .scrollIndicators(.hidden)
            .scrollTargetBehavior(.viewAligned)
            .transition(.move(edge: .bottom).combined(with: .opacity))
        }
    }

    // MARK: - Searching

    private func initialSearch() async {
        guard viewModel.phase == .idle else { return }
        // Give the position a moment, so the first search is already around the user.
        var waited = 0
        while location.coordinate == nil, location.status != .denied, waited < 20 {
            try? await Task.sleep(for: .milliseconds(100))
            waited += 1
        }
        await searchAroundBestPosition()
    }

    private func searchAroundBestPosition() async {
        let coordinate = location.coordinate
        searchedAroundUser = coordinate != nil
        await search(in: IdeaPlacesViewModel.region(around: coordinate ?? IdeaPlacesViewModel.fallbackCenter))
    }

    private func search(in region: MKCoordinateRegion) async {
        await viewModel.search(in: region)
        isFittingCamera = true
        withAnimation(.smooth) {
            position = viewModel.places.isEmpty ? .region(region) : .automatic
        }
        // If the camera was already in place it does not move, and no change arrives to end the fit.
        try? await Task.sleep(for: .seconds(1.5))
        if isFittingCamera {
            isFittingCamera = false
            viewModel.markSearched(visibleRegion ?? region)
        }
    }
}

private extension View {
    /// A small Liquid Glass capsule at the top of the map for status messages.
    func statusCapsule() -> some View {
        font(.subheadline.weight(.medium))
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .glassEffect(.regular, in: .capsule)
    }
}
