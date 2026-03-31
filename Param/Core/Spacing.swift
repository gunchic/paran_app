import CoreGraphics

// ─────────────────────────────────────────
// Spacing — 파람 여백 시스템
// 사용법: .padding(Spacing.lg)
//         .padding(.horizontal, Spacing.xl)
//         VStack(spacing: Spacing.md)
// ─────────────────────────────────────────
enum Spacing {
    static let xs:   CGFloat = 4
    static let sm:   CGFloat = 8
    static let md:   CGFloat = 12
    static let lg:   CGFloat = 16
    static let xl:   CGFloat = 20
    static let xxl:  CGFloat = 24
    static let xxxl: CGFloat = 32
}
