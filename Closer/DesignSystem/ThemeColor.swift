import SwiftUI

/// A colour token with one value for light and one for dark mode. Resolves itself whenever the
/// appearance changes, so views never have to check the colour scheme themselves.
nonisolated struct ThemeColor: Hashable, Sendable {
    let light: RGBColor
    let dark: RGBColor

    init(light: UInt32, dark: UInt32) {
        self.light = RGBColor(hex: light)
        self.dark = RGBColor(hex: dark)
    }

    init(_ light: RGBColor, dark: RGBColor) {
        self.light = light
        self.dark = dark
    }

    /// Same colour in both modes.
    init(_ both: RGBColor) {
        self.light = both
        self.dark = both
    }

    func resolved(for style: UIUserInterfaceStyle) -> RGBColor {
        style == .dark ? dark : light
    }

    var uiColor: UIColor {
        let light = light.uiColor
        let dark = dark.uiColor
        return UIColor { traits in traits.userInterfaceStyle == .dark ? dark : light }
    }

    var color: Color { Color(uiColor: uiColor) }
}
