import SwiftUI

// ─────────────────────────────────────────
// ZONE 2 — 파동 수치 표시 + 액션 진입점
// 수치 표시 전담 / 버튼 액션은 MomentDetailView에서 주입
// ─────────────────────────────────────────
struct WaveStatsZone: View {
    let waveCount: Int
    let hasWaved: Bool
    let onTapWave: () -> Void
    var onTapCount: (() -> Void)? = nil

    var body: some View {
        HStack(spacing: 0) {

            // 파동 수치 — 탭하면 나도그래 유저 목록으로 이동
            Button(action: { onTapCount?() }) {
                VStack(alignment: .leading, spacing: 3) {
                    HStack(alignment: .bottom, spacing: 4) {
                        Text("\(waveCount)")
                            .font(.system(size: 30, weight: .bold))
                            .foregroundColor(.primary)
                            .contentTransition(.numericText())
                            .animation(.spring(response: 0.4), value: waveCount)
                        Text("명이 같은 파동 위에 있어요")
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                            .padding(.bottom, 4)
                    }
                    if waveCount > 0 {
                        HStack(spacing: 4) {
                            Text("나만 이런 게 아니었어 💙")
                                .font(.system(size: 12))
                                .foregroundColor(.signalRed.opacity(0.7))
                            Image(systemName: "chevron.right")
                                .font(.system(size: 10))
                                .foregroundColor(.signalRed.opacity(0.5))
                        }
                        .transition(.opacity)
                    }
                }
            }
            .buttonStyle(.plain)
            .disabled(waveCount == 0)

            Spacer()

            // 나도 그래 버튼
            Button(action: onTapWave) {
                HStack(spacing: 6) {
                    Image(systemName: "water.waves")
                        .font(.system(size: 14))
                    Text(hasWaved ? "공감 중" : "나도 그래")
                        .font(.system(size: 15, weight: .semibold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, Spacing.lg + 2)
                .padding(.vertical, Spacing.sm + 2)
                .background(hasWaved ? Color.signalRed.opacity(0.6) : Color.signalRed)
                .cornerRadius(Radius.full)
                .animation(.spring(response: 0.3), value: hasWaved)
            }
            .buttonShadow()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(Color.warmPaper)
    }
}
