import SwiftUI

extension View {
    /// Replaces the system grey behind a `List` or `Form` with Closer's background colour.
    /// Combine with `.listRowBackground(Color.closerSurface)` on the sections.
    func closerListBackground() -> some View {
        scrollContentBackground(.hidden)
            .background(Color.closerBackground.ignoresSafeArea())
    }
}
