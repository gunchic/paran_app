import SwiftUI
import Combine

// ─────────────────────────────────────────
// MomentDetailView
// ─────────────────────────────────────────
struct MomentDetailView: View {
    let moment: Moment

    @StateObject private var vm         = MomentDetailViewModel()
    @StateObject private var commentsVM = CommentsViewModel()
    @ObservedObject private var waveStore = WaveStore.shared
    @State private var showCancelConfirm = false   // 공감 취소 확인 alert
    @State private var showWaveUsers     = false
    @State private var showCommentInput  = false
    @EnvironmentObject var appState: AppState

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {

                // ZONE 1 — 원본 파동
                DetailHeaderZone(moment: moment)

                Divider()

                // ZONE 2 — 파동 수치 + 나도 그래 토글
                WaveStatsZone(
                    waveCount: waveStore.count(for: moment.id),
                    hasWaved: waveStore.hasWaved(moment.id),
                    onTapWave: {
                        if waveStore.hasWaved(moment.id) {
                            showCancelConfirm = true
                        } else {
                            submitWave()
                        }
                    },
                    onTapCount: {
                        if !vm.waves.isEmpty { showWaveUsers = true }
                    }
                )

                Divider()

                // ZONE 3 — 댓글
                CommentsZone(momentID: moment.id, vm: commentsVM)

                // 댓글 입력 버튼
                Button(action: { showCommentInput = true }) {
                    HStack {
                        Image(systemName: "bubble.left")
                            .font(.system(size: 14))
                        Text("댓글 달기")
                            .font(.system(size: 14, weight: .medium))
                    }
                    .foregroundColor(.driftwood)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.md)
                    .background(Color(.systemBackground))
                    .cornerRadius(Radius.md)
                    .padding(.horizontal, Spacing.lg)
                    .padding(.bottom, Spacing.lg)
                }
                .buttonStyle(.plain)
            }
        }
        .background(Color.warmPaper)
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle("파동")

        // 공감 취소 확인 alert
        .alert("파동 공감을 취소하시겠습니까?", isPresented: $showCancelConfirm) {
            Button("예", role: .destructive) { cancelWave() }
            Button("아니오", role: .cancel) {}
        }

        // 댓글 입력 시트
        .sheet(isPresented: $showCommentInput) {
            CommentInputSheet(momentID: moment.id) {
                Task { await commentsVM.load(momentID: moment.id) }
            }
            .environmentObject(appState)
        }

        .navigationDestination(isPresented: $showWaveUsers) {
            WaveUsersView(momentID: moment.id, waves: vm.waves)
                .environmentObject(appState)
        }
        .task {
            await vm.loadWaves(momentID: moment.id)
            await commentsVM.load(momentID: moment.id, userID: appState.currentUserID)
        }
        .refreshable {
            await vm.loadWaves(momentID: moment.id)
            await commentsVM.load(momentID: moment.id, userID: appState.currentUserID)
        }
    }

    // ── 나도 그래 ────────────────────────────────────
    private func submitWave() {
        guard let userID = appState.currentUserID else { return }
        let momentID = moment.id
        waveStore.recordWave(momentID: momentID)
        Task {
            do {
                let _: Wave = try await APIClient.shared.post(
                    "/moments/\(momentID)/wave",
                    body: EmptyBody(),
                    userID: userID
                )
                await vm.loadWaves(momentID: momentID)
            } catch {
                waveStore.rollback(momentID: momentID)
            }
        }
    }

    // ── 공감 취소 ─────────────────────────────────────
    private func cancelWave() {
        guard let userID = appState.currentUserID else { return }
        let momentID = moment.id
        waveStore.rollback(momentID: momentID)
        Task {
            do {
                try await APIClient.shared.delete("/moments/\(momentID)/wave", userID: userID)
                await vm.loadWaves(momentID: momentID)
            } catch {
                waveStore.recordWave(momentID: momentID)
            }
        }
    }
}

// ─────────────────────────────────────────
// ViewModel
// ─────────────────────────────────────────
@MainActor
class MomentDetailViewModel: ObservableObject {
    @Published var waves: [Wave] = []

    private var currentMomentID: String = ""

    func loadWaves(momentID: String) async {
        currentMomentID = momentID
        guard let result: [Wave] = try? await APIClient.shared.get(
            "/moments/\(momentID)/waves"
        ) else { return }
        self.waves = result
        WaveStore.shared.setCount(result.count, for: momentID)
    }
}
