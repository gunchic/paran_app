import SwiftUI

// MARK: - Type Scale
extension Font {
    /// size 48 / weight .black / tracking -2
    static let display: Font = .system(size: 48, weight: .black, design: .default)

    /// size 28 / weight .bold / tracking -1
    static let heading1: Font = .system(size: 28, weight: .bold, design: .default)

    /// size 20 / weight .semibold
    static let heading2: Font = .system(size: 20, weight: .semibold, design: .default)

    /// size 15 / weight .regular (use with lineSpacing via Text modifier)
    static let paramBody: Font = .system(size: 15, weight: .regular, design: .default)

    /// size 11 / weight .regular / tracking 1
    static let caption: Font = .system(size: 11, weight: .regular, design: .default)
}

// MARK: - Typography Modifiers
extension View {
    func displayStyle() -> some View {
        self.font(.display)
            .tracking(-2)
    }

    func heading1Style() -> some View {
        self.font(.heading1)
            .tracking(-1)
    }

    func heading2Style() -> some View {
        self.font(.heading2)
    }

    func bodyStyle() -> some View {
        self.font(.paramBody)
            .lineSpacing(4)
    }

    func captionStyle() -> some View {
        self.font(.caption)
            .tracking(1)
    }
}
