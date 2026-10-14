import Testing
import UIKit
@testable import Closer

@MainActor
struct PaletteTests {
    private let styles: [UIUserInterfaceStyle] = [.light, .dark]

    // MARK: - Brand

    @Test func brandColoursMatchTheAppIcon() {
        #expect(Palette.pine.hex == 0x10231F)
        #expect(Palette.coral.hex == 0xF5A58C)
        #expect(Palette.cream.hex == 0xF8F3E9)
    }

    @Test func blendIsAnEvenMixOfCoralAndCream() {
        let coral = Palette.coral, cream = Palette.cream, blend = Palette.blend
        #expect(abs(blend.red - (coral.red + cream.red) / 2) <= 1.0 / 255)
        #expect(abs(blend.green - (coral.green + cream.green) / 2) <= 1.0 / 255)
        #expect(abs(blend.blue - (coral.blue + cream.blue) / 2) <= 1.0 / 255)
    }

    // MARK: - Light and dark mode

    @Test func backgroundIsCreamByDay() {
        #expect(Palette.background.resolved(for: .light) == Palette.cream)
    }

    /// Pine is an accent at night (hero card, sage), not the colour of whole screens.
    @Test func darkSurfacesAreNeutralNotGreen() {
        for token in [Palette.background, Palette.surface] {
            let color = token.resolved(for: .dark)
            #expect(color != Palette.pine)
            #expect(color.green <= color.red, "\(String(color.hex, radix: 16))")
            #expect(max(color.red, color.green, color.blue) - min(color.red, color.green, color.blue) <= 0.02)
        }
    }

    @Test func heroStaysPineInBothModes() {
        #expect(Palette.hero.resolved(for: .light) == Palette.pine)
        let dark = Palette.hero.resolved(for: .dark)
        #expect(dark.green > dark.red && dark.green > dark.blue)
        #expect(dark.contrastRatio(to: Palette.background.resolved(for: .dark)) > 1.2)
    }

    /// The partner card is built from the icon's warm colours, not a new hue.
    @Test func partnerCardIsWarm() {
        #expect(Palette.partner.resolved(for: .light) == Palette.coral)
        #expect(Palette.partnerEnd.resolved(for: .light) == Palette.blend)
        for token in [Palette.partner, Palette.partnerEnd] {
            let dark = token.resolved(for: .dark)
            #expect(dark.red > dark.green && dark.red > dark.blue)
        }
    }

    @Test func surfacesFollowTheAppearance() {
        for token in [Palette.background, Palette.surface] {
            #expect(token.resolved(for: .light).relativeLuminance > 0.8)
            #expect(token.resolved(for: .dark).relativeLuminance < 0.05)
        }
    }

    @Test func uiColorResolvesPerTraitCollection() {
        for style in styles {
            let resolved = Palette.accent.uiColor.resolvedColor(with: UITraitCollection(userInterfaceStyle: style))
            var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
            let isRGB = resolved.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
            #expect(isRGB)
            let expected = Palette.accent.resolved(for: style)
            #expect(abs(red - expected.red) < 0.001)
            #expect(abs(green - expected.green) < 0.001)
            #expect(abs(blue - expected.blue) < 0.001)
            #expect(alpha == 1)
        }
    }

    // MARK: - Contrast (WCAG AA, 4.5:1 for text)

    @Test(arguments: [
        ("accent on background", Palette.accent, Palette.background),
        ("accent on surface", Palette.accent, Palette.surface),
        ("onAccent on accent", Palette.onAccent, Palette.accent),
        ("onAccentSoft on accentSoft", Palette.onAccentSoft, Palette.accentSoft),
        ("onHero on hero", Palette.onHero, Palette.hero),
        ("heroAccent on hero", Palette.heroAccent, Palette.hero),
        ("sage on surface", Palette.sage, Palette.surface),
        ("onAvatar on avatar", Palette.onAvatar, Palette.avatar),
        ("onPartner on partner", Palette.onPartner, Palette.partner),
        ("onPartner on partnerEnd", Palette.onPartner, Palette.partnerEnd),
        ("partnerAccent on partner", Palette.partnerAccent, Palette.partner),
        ("partnerAccent on partnerEnd", Palette.partnerAccent, Palette.partnerEnd),
        ("partner on onPartner", Palette.partner, Palette.onPartner),
    ])
    func textIsReadableInBothModes(name: String, foreground: ThemeColor, background: ThemeColor) {
        for style in styles {
            let ratio = foreground.resolved(for: style).contrastRatio(to: background.resolved(for: style))
            #expect(ratio >= 4.5, "\(name) in \(style == .dark ? "dark" : "light") mode: \(ratio)")
        }
    }

    // MARK: - RGBColor

    @Test func componentsAreReadFromHex() {
        let color = RGBColor(hex: 0xFF8000)
        #expect(color.red == 1)
        #expect(abs(color.green - 128.0 / 255) < 0.0001)
        #expect(color.blue == 0)
    }

    @Test func contrastRatioSpansOneToTwentyOne() {
        let black = RGBColor(hex: 0x000000), white = RGBColor(hex: 0xFFFFFF)
        #expect(abs(black.contrastRatio(to: white) - 21) < 0.001)
        #expect(white.contrastRatio(to: black) == black.contrastRatio(to: white))
        #expect(Palette.coral.contrastRatio(to: Palette.coral) == 1)
    }
}
