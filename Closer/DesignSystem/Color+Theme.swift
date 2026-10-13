import SwiftUI

/// Semantic colours of `Palette` as SwiftUI colours, adapting to light and dark mode.
extension Color {
    static let closerBackground = Palette.background.color
    static let closerSurface = Palette.surface.color
    static let closerHero = Palette.hero.color
    static let closerAccent = Palette.accent.color
    static let closerOnAccent = Palette.onAccent.color
    static let closerAccentSoft = Palette.accentSoft.color
    static let closerOnAccentSoft = Palette.onAccentSoft.color
    static let closerOnHero = Palette.onHero.color
    static let closerHeroAccent = Palette.heroAccent.color
    static let closerSage = Palette.sage.color
    static let closerAvatar = Palette.avatar.color
    static let closerOnAvatar = Palette.onAvatar.color
}

// Allows `.closerAccent` wherever a ShapeStyle is expected (e.g. foregroundStyle).
extension ShapeStyle where Self == Color {
    static var closerBackground: Color { Color.closerBackground }
    static var closerSurface: Color { Color.closerSurface }
    static var closerHero: Color { Color.closerHero }
    static var closerAccent: Color { Color.closerAccent }
    static var closerOnAccent: Color { Color.closerOnAccent }
    static var closerAccentSoft: Color { Color.closerAccentSoft }
    static var closerOnAccentSoft: Color { Color.closerOnAccentSoft }
    static var closerOnHero: Color { Color.closerOnHero }
    static var closerHeroAccent: Color { Color.closerHeroAccent }
    static var closerSage: Color { Color.closerSage }
    static var closerAvatar: Color { Color.closerAvatar }
    static var closerOnAvatar: Color { Color.closerOnAvatar }
}
