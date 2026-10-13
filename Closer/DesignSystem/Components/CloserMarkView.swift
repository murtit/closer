import SwiftUI

/// The two overlapping circles of the app icon, for use on pine (`closerHero`) surfaces.
/// Proportions match `scripts/generate-app-icon.py`: circle radius 224, centres 320 apart.
struct CloserMarkView: View {
    /// Height of the mark; the width follows from the proportions.
    var height: CGFloat = 24

    static let aspectRatio: CGFloat = (2 * 224 + 320) / (2 * 224)

    var body: some View {
        Canvas { context, size in
            let diameter = size.height
            let distance = diameter * 320 / 448
            let left = Path(ellipseIn: CGRect(x: 0, y: 0, width: diameter, height: diameter))
            let right = Path(ellipseIn: CGRect(x: distance, y: 0, width: diameter, height: diameter))

            context.fill(left, with: .color(Palette.coral.color))
            context.fill(right, with: .color(Palette.cream.color))
            var overlap = context
            overlap.clip(to: left)
            overlap.fill(right, with: .color(Palette.blend.color))
        }
        .frame(width: height * Self.aspectRatio, height: height)
        .accessibilityHidden(true)
    }
}

private extension RGBColor {
    var color: Color { Color(uiColor: uiColor) }
}

#Preview {
    CloserMarkView(height: 64)
        .padding(40)
        .background(Color.closerHero)
}
