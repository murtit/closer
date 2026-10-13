import Foundation

/// All colours of Closer.
///
/// The brand colours are the ones of the app icon (see `scripts/generate-app-icon.py`). Views use
/// the semantic tokens below via `Color+Theme.swift`, never the brand colours directly, so light
/// and dark mode stay consistent. `PaletteTests` checks every text/background pair for contrast.
nonisolated enum Palette {
    // MARK: - Brand

    /// Deep pine green, background of the app icon.
    static let pine = RGBColor(hex: 0x10231F)
    /// Warm coral with a hint of rose, left circle of the app icon.
    static let coral = RGBColor(hex: 0xF5A58C)
    /// Warm cream with a rosé undertone, right circle of the app icon.
    static let cream = RGBColor(hex: 0xF8F3E9)
    /// Where coral and cream overlap in the app icon: an even mix of both.
    static let blend = RGBColor(hex: 0xF6CCBA)

    // MARK: - Surfaces

    /// Screen background: cream by day, pine by night.
    static let background = ThemeColor(Palette.cream, dark: Palette.pine)
    /// Cards and list rows on top of `background`.
    static let surface = ThemeColor(light: 0xFFFDF9, dark: 0x1A332D)
    /// The highlighted card on the home screen; pine in both modes, a shade lighter at night so
    /// it stands out from the background.
    static let hero = ThemeColor(Palette.pine, dark: RGBColor(hex: 0x21423A))

    // MARK: - Content

    /// Tint for buttons, toggles, links and icons. Coral is too light on cream, so the light
    /// variant is a deeper terracotta of the same hue.
    static let accent = ThemeColor(RGBColor(hex: 0xA94A30), dark: Palette.coral)
    /// Text and icons on a filled `accent` background, such as prominent buttons.
    static let onAccent = ThemeColor(light: 0xFFFFFF, dark: 0x10231F)
    /// Soft fill behind emojis, chips and quick actions.
    static let accentSoft = ThemeColor(light: 0xFBE4DA, dark: 0x4A3630)
    /// Text and icons on `accentSoft`.
    static let onAccentSoft = ThemeColor(light: 0x8A3A25, dark: 0xF8C4B2)
    /// Text on `hero`.
    static let onHero = ThemeColor(Palette.cream)
    /// Labels and icons on `hero` that should stand out.
    static let heroAccent = ThemeColor(Palette.coral)
    /// Secondary accent derived from pine, for figures next to `accent`.
    static let sage = ThemeColor(light: 0x3B6A5D, dark: 0x8FBFAE)
    /// Avatar without a photo: coral circle with pine initials, as in the app icon.
    static let avatar = ThemeColor(Palette.coral)
    static let onAvatar = ThemeColor(Palette.pine)
}
