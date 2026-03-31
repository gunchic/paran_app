import SwiftUI
import UIKit

// ─────────────────────────────────────────
// RoundedCorner — 특정 모서리만 radius 적용
// 사용법: .cornerRadius(16, corners: [.topLeft, .topRight])
// ─────────────────────────────────────────
struct RoundedCorner: Shape {
    var radius: CGFloat
    var corners: UIRectCorner

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}
