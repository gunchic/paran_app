import SwiftUI

// MARK: - Color Token Extensions
extension Color {
    // MARK: Brand Palette
    /// Primary brand color / CTA
    static let wave100 = Color(hex: "#B8DDE8")  // Tint
    static let wave400 = Color(hex: "#7EB8C9")  // 메인 액센트
    static let wave600 = Color(hex: "#3D8EA3")  // Press / Active
    static let wave800 = Color(hex: "#1E5F73")  // Deep / Primary Button

    /// Secondary brand color
    static let colorSecondary = Color(hex: "#657B81")

    /// Tertiary brand color (purple accent)
    static let colorTertiary = Color(hex: "#C0A5D6")

    // MARK: Neutral Scale (Light Mode)
    /// 앱 메인 배경 (Light mode)
    static let paper  = Color(hex: "#F5F4F2")
    /// 카드 배경 (Light mode)
    static let stone  = Color(hex: "#E8E7E4")
    /// 보조 텍스트
    static let ash    = Color(hex: "#9A9994")
    /// 3차 텍스트
    static let slate  = Color(hex: "#5C5B58")

    // MARK: Surface Hierarchy (Light Mode)
    static let surfaceLowest    = Color(hex: "#FFFFFF")
    static let surfaceBase      = Color(hex: "#FAF9F7")
    static let surfaceLow       = Color(hex: "#F4F3F1")
    static let surfaceContainer = Color(hex: "#EFEEEC")
    static let surfaceHighest   = Color(hex: "#E3E2E0")

    // MARK: Dark Tokens (Inverted 버튼 등 부분 사용)
    /// 완전한 어두운 배경 / Inverted 버튼 bg / 기본 텍스트 컬러
    static let void    = Color(hex: "#0E0E0E")
    /// 다크 카드 배경
    static let depth   = Color(hex: "#1C1C1C")
    /// 다크 elevated surface
    static let surface = Color(hex: "#2A2A2A")
    /// 다크 모드 주요 텍스트
    static let mist    = Color(hex: "#F0EFEB")

    // MARK: Semantic
    /// 파람 브랜드 포인트
    static let waveAccent = Color.wave400
    /// 앱 기본 배경
    static let appBackground = Color.paper
    /// 카드 배경
    static let cardBackground = Color.surfaceLowest
    /// 기본 텍스트
    static let primaryText = Color.void
    /// 보조 텍스트
    static let secondaryText = Color.ash
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
