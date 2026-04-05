import SwiftUI

// MARK: - Color Token Extensions
extension Color {
    // MARK: Primary Darks
    /// Primary background (dark mode main)
    static let void    = Color(hex: "#0E0E0E")
    /// Card background (dark)
    static let depth   = Color(hex: "#1C1C1C")
    /// Elevated surface
    static let surface = Color(hex: "#2A2A2A")
    /// Primary text on dark
    static let mist    = Color(hex: "#F0EFEB")

    // MARK: Wave Blue (Brand Accent)
    static let wave100 = Color(hex: "#B8DDE8")  // Tint
    static let wave400 = Color(hex: "#7EB8C9")  // 메인 액센트 / CTA
    static let wave600 = Color(hex: "#3D8EA3")  // Press / Active
    static let wave800 = Color(hex: "#1E5F73")  // Deep accent

    // MARK: Neutrals
    static let paper = Color(hex: "#F5F4F2")  // Light mode bg
    static let stone = Color(hex: "#E8E7E4")  // Border on light
    static let ash   = Color(hex: "#9A9994")  // Secondary text
    static let slate = Color(hex: "#5C5B58")  // Tertiary text

    // MARK: Surface Hierarchy
    static let surfaceBase      = Color(hex: "#FAF9F7")
    static let surfaceLow       = Color(hex: "#F4F3F1")
    static let surfaceContainer = Color(hex: "#EFEEEC")
    static let surfaceLowest    = Color(hex: "#FFFFFF")
    static let surfaceHighest   = Color(hex: "#E3E2E0")

    // MARK: Semantic
    /// 파람 브랜드 포인트
    static let waveAccent = Color.wave400
}

// MARK: - Hex Color Initializer
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red:     Double(r) / 255,
            green:   Double(g) / 255,
            blue:    Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
