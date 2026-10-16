import MapKit
import SwiftUI

/// A place in the strip below the map: name, address and distance on Liquid Glass.
struct PlaceCardView: View {
    let place: MKMapItem
    let distance: String?
    var isSelected = false

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                Image(systemName: "mappin.circle.fill")
                    .font(.title3)
                    .foregroundStyle(.closerAccent)
                Text(place.name ?? "Ort")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
            }
            if let address = place.address?.shortAddress, !address.isEmpty {
                Text(address)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            if let distance {
                Label(distance, systemImage: "figure.walk")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(14)
        .frame(width: 220, alignment: .leading)
        .frame(minHeight: 88, alignment: .topLeading)
        .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 20))
        .overlay {
            RoundedRectangle(cornerRadius: 20)
                .strokeBorder(Color.closerAccent, lineWidth: isSelected ? 2 : 0)
        }
        .contentShape(RoundedRectangle(cornerRadius: 20))
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }
}
