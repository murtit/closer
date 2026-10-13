import SwiftUI

extension Color {
    static let rosePrimary = Color(red: 0.878, green: 0.322, blue: 0.502)
    static let roseDeep    = Color(red: 0.690, green: 0.188, blue: 0.376)
    static let roseBlush   = Color(red: 0.980, green: 0.878, blue: 0.918)
}

// Erlaubt .rosePrimary als Kürzel überall wo ShapeStyle erwartet wird (z.B. foregroundStyle)
extension ShapeStyle where Self == Color {
    static var rosePrimary: Color { .init(red: 0.878, green: 0.322, blue: 0.502) }
    static var roseDeep:    Color { .init(red: 0.690, green: 0.188, blue: 0.376) }
    static var roseBlush:   Color { .init(red: 0.980, green: 0.878, blue: 0.918) }
}
