import SwiftUI

/// Round quick action (call, message, mail). Disabled when the person has no matching data.
struct ContactActionButton: View {
    @Environment(\.openURL) private var openURL
    let title: String
    let systemImage: String
    let url: URL?

    var body: some View {
        Button {
            if let url { openURL(url) }
        } label: {
            VStack(spacing: 6) {
                Image(systemName: systemImage)
                    .font(.title3)
                    .frame(width: 52, height: 52)
                    .background(Circle().fill(Color.roseBlush))
                Text(title)
                    .font(.caption)
            }
            .foregroundStyle(Color.roseDeep)
        }
        .buttonStyle(.plain)
        .disabled(url == nil)
        .opacity(url == nil ? 0.4 : 1)
    }
}
