import SwiftUI
import Combine
import CoreLocation

// ─────────────────────────────────────────
// WaveActionSheet — 나도 그래 분기 처리 시트
// 파람 핵심 영역: UI/기능 변경 잦음 → 독립 컴포넌트
//
// 현재 플로우:
//   Option A. 즉시 공감   → 카운트만 증가 (입력 없음)
//   Option B. 순간 공유   → 글 or 이미지 (하나만 있어도 OK)
// ─────────────────────────────────────────
struct WaveActionSheet: View {
    let momentID: String
    let onOpenProof: () -> Void   // Option B → AddProofSheet 오픈
    let onDismiss: () -> Void

    @EnvironmentObject var appState: AppState
    @ObservedObject private var waveStore = WaveStore.shared
    @State private var isQuickWaving = false

    private var hasWaved: Bool { waveStore.hasWaved(momentID) }

    var body: some View {
        VStack(spacing: 0) {

            // 핸들
            Capsule()
                .fill(Color(.systemGray4))
                .frame(width: 36, height: 4)
                .padding(.top, 12)
                .padding(.bottom, 20)

            VStack(spacing: 12) {

                // ── Option A: 즉시 공감 ──────────────────
                Button(action: quickWave) {
                    HStack(spacing: 14) {
                        ZStack {
                            Circle()
                                .fill(Color.redTint)
                                .frame(width: 48, height: 48)
                            Image(systemName: isQuickWaving ? "checkmark" : "water.waves")
                                .font(.system(size: 20))
                                .foregroundColor(.signalRed)
                                .symbolEffect(.bounce, value: isQuickWaving)
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text("나도 그래")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.primary)
                            Text("공감만 표시할게요")
                                .font(.system(size: 13))
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        if isQuickWaving {
                            ProgressView()
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "chevron.right")
                                .font(.system(size: 13))
                                .foregroundColor(Color(.systemGray3))
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 14)
                    .background(Color(.systemBackground))
                    .cornerRadius(14)
                }
                .disabled(isQuickWaving || hasWaved)
                .overlay(
                    hasWaved ?
                    RoundedRectangle(cornerRadius: Radius.lg)
                        .stroke(Color.redBorder.opacity(0.5), lineWidth: 1.5) : nil
                )

                // ── Option B: 순간 공유 ──────────────────
                Button(action: {
                    onDismiss()
                    Task {
                        try? await Task.sleep(for: .milliseconds(300))
                        onOpenProof()
                    }
                }) {
                    HStack(spacing: 14) {
                        ZStack {
                            Circle()
                                .fill(Color.whiteWarm)
                                .frame(width: 48, height: 48)
                            Image(systemName: "camera.fill")
                                .font(.system(size: 20))
                                .foregroundColor(.driftwood)
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text("지금 이 순간 공유하기")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.primary)
                            Text("글 또는 사진으로 내 상황 남기기")
                                .font(.system(size: 13))
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.system(size: 13))
                            .foregroundColor(Color(.systemGray3))
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 14)
                    .background(Color(.systemBackground))
                    .cornerRadius(14)
                }

            }
            .padding(.horizontal, 16)

            // 취소
            Button(action: onDismiss) {
                Text("취소")
                    .font(.system(size: 16))
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
            }
            .padding(.top, 8)
            .padding(.bottom, 8)
        }
        .background(Color.warmPaper)
    }

    // ── 즉시 공감 처리 ──────────────────────────
    private func quickWave() {
        guard let userID = appState.currentUserID, !hasWaved else { return }
        isQuickWaving = true

        // Optimistic UI — WaveStore에 기록
        withAnimation(.spring(response: 0.3)) {
            waveStore.recordWave(momentID: momentID)
        }

        Task {
            // 위치 비동기 대기 (최대 4초, 선택 사항)
            let loc = await LocationManager.shared.locationAsync()

            struct QuickWaveBody: Encodable {
                let latitude: Double?
                let longitude: Double?
            }
            let body = QuickWaveBody(
                latitude: loc?.coordinate.latitude,
                longitude: loc?.coordinate.longitude
            )
            let _: Wave? = try? await APIClient.shared.post(
                "/moments/\(momentID)/wave",
                body: body,
                userID: userID
            )
            await MainActor.run { isQuickWaving = false }
            try? await Task.sleep(for: .milliseconds(500))
            await MainActor.run { onDismiss() }
        }
    }
}
