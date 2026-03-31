import SwiftUI

// ─────────────────────────────────────────
// LiveBadge — 실시간 파동 뱃지
// pulse 애니메이션으로 현재 활성 상태 표시
// ─────────────────────────────────────────
struct LiveBadge: View {
    @State private var pulse = false

    var body: some View {
        HStack(spacing: Spacing.xs) {
            // 펄스 점
            ZStack {
                Circle()
                    .fill(Color.signalRed.opacity(0.3))
                    .frame(width: 14, height: 14)
                    .scaleEffect(pulse ? 1.6 : 1.0)
                    .opacity(pulse ? 0 : 1)
                    .animation(
                        .easeOut(duration: 1.2).repeatForever(autoreverses: false),
                        value: pulse
                    )
                Circle()
                    .fill(Color.signalRed)
                    .frame(width: 7, height: 7)
            }

            Text("LIVE")
                .font(.paramMono)
                .foregroundColor(.signalRed)
        }
        .padding(.horizontal, Spacing.sm + Spacing.xs)
        .padding(.vertical, Spacing.xs)
        .background(Color.redTint)
        .cornerRadius(Radius.full)
        .onAppear { pulse = true }
    }
}
