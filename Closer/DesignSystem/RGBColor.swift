import UIKit

/// An opaque sRGB colour written as `0xRRGGBB`, with the WCAG helpers used to check text contrast.
nonisolated struct RGBColor: Hashable, Sendable {
    let hex: UInt32

    init(hex: UInt32) {
        precondition(hex <= 0xFFFFFF, "RGBColor expects 0xRRGGBB")
        self.hex = hex
    }

    var red: Double { Double((hex >> 16) & 0xFF) / 255 }
    var green: Double { Double((hex >> 8) & 0xFF) / 255 }
    var blue: Double { Double(hex & 0xFF) / 255 }

    var uiColor: UIColor {
        UIColor(red: red, green: green, blue: blue, alpha: 1)
    }

    // MARK: - Contrast

    /// Relative luminance as defined by WCAG 2.x, from 0 (black) to 1 (white).
    var relativeLuminance: Double {
        func linear(_ channel: Double) -> Double {
            channel <= 0.04045 ? channel / 12.92 : pow((channel + 0.055) / 1.055, 2.4)
        }
        return 0.2126 * linear(red) + 0.7152 * linear(green) + 0.0722 * linear(blue)
    }

    /// WCAG contrast ratio, from 1 (same luminance) to 21 (black on white). Body text needs 4.5.
    func contrastRatio(to other: RGBColor) -> Double {
        let lighter = max(relativeLuminance, other.relativeLuminance)
        let darker = min(relativeLuminance, other.relativeLuminance)
        return (lighter + 0.05) / (darker + 0.05)
    }
}
