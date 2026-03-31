import SwiftUI

// ─────────────────────────────────────────
// Shadow — 파람 그림자 시스템
// 사용법: .cardShadow()
//         .buttonShadow()
// ─────────────────────────────────────────
extension View {
    /// 카드 기본 그림자 (피드 카드, 프로필 섹션)
    func cardShadow() -> some View {
        self.shadow(
            color: Color.void.opacity(0.06),
            radius: 8,
            x: 0,
            y: 2
        )
    }

    /// 주요 버튼 그림자 (CTA, signalRed 버튼)
    func buttonShadow() -> some View {
        self.shadow(
            color: Color.signalRed.opacity(0.25),
            radius: 8,
            x: 0,
            y: 4
        )
    }
}
