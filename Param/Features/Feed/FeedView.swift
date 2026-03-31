import SwiftUI
import Combine
import CoreLocation

// ─────────────────────────────────────────
// FeedMode — 피드 표시 방식
// ─────────────────────────────────────────
enum FeedMode: String, CaseIterable {
    case matched = "파람 추천"
    case latest  = "최신순"
}

struct FeedView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var vm = FeedViewModel()
    @State private var feedMode: FeedMode = .latest

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {

                // ── 피드 모드 세그먼트 ─────────────────────
                Picker("피드 모드", selection: $feedMode) {
                    ForEach(FeedMode.allCases, id: \.self) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.warmPaper)

                Divider()

                // ── 콘텐츠 ───────────────────────────────
                ScrollView {
                    LazyVStack(spacing: 0) {
                        if vm.moments.isEmpty && !vm.isLoading {
                            emptyState
                        } else {
                            ForEach(vm.moments) { moment in
                                MomentCard(moment: moment)
                                    .overlay(alignment: .topTrailing) {
                                        if feedMode == .matched, let score = moment.matchScore {
                                            MatchBadge(score: score)
                                                .padding(Spacing.sm + 2)
                                        }
                                    }
                            }
                        }
                    }
                    .padding(.vertical, 8)
                }
                .background(Color.warmPaper)
                .refreshable { await reload() }
            }
            .overlay(alignment: .bottom) {
                if let error = vm.errorMessage {
                    Text("⚠️ \(error)")
                        .font(.caption)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.red.opacity(0.85))
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    HStack(spacing: 6) {
                        Image(systemName: "mappin.circle.fill")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.signalRed)
                        Text("PARAM")
                            .font(.system(size: 20, weight: .black))
                            .foregroundColor(.signalRed)
                            .kerning(1.5)
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(destination: CreateMomentView()) {
                        ZStack {
                            Circle()
                                .fill(Color.void)
                                .frame(width: 32, height: 32)
                            Image(systemName: "plus")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.white)
                        }
                    }
                }
            }
            .onChange(of: feedMode) { _, _ in
                Task { await reload() }
            }
            .onAppear {
                Task { await reload() }
            }
        }
    }

    private func reload() async {
        await vm.load(userID: appState.currentUserID, mode: feedMode)
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: feedMode == .matched ? "waveform.path" : "text.bubble")
                .font(.system(size: 44))
                .foregroundColor(.secondary)
            Text(feedMode == .matched
                 ? "지금 같은 반경에 파람이 없어요\n태그를 추가하거나 위치를 허용해보세요"
                 : "아직 올라온 파동이 없어요")
                .font(.system(size: 15))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 80)
    }
}

// ─────────────────────────────────────────
// MatchBadge — 매칭 점수 뱃지
// ─────────────────────────────────────────
struct MatchBadge: View {
    let score: Double

    private var percent: Int { Int(score * 100) }

    private var badgeColor: Color {
        switch score {
        case 0.8...: return .signalRed  // 강한 파람
        case 0.6...: return .driftwood  // 중간
        default:     return .secondary
        }
    }

    var body: some View {
        Text("\(percent)%")
            .font(.system(size: 10, weight: .bold))
            .foregroundColor(.white)
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(badgeColor)
            .clipShape(Capsule())
    }
}

// ─────────────────────────────────────────
// FeedViewModel
// ─────────────────────────────────────────
@MainActor
class FeedViewModel: ObservableObject {
    @Published var moments: [Moment] = []
    @Published var errorMessage: String?
    @Published var isLoading = false

    func load(userID: String?, mode: FeedMode) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let moments: [Moment]
            if mode == .matched, let uid = userID {
                moments = try await loadMatched(userID: uid)
            } else {
                moments = try await APIClient.shared.get("/moments", userID: userID)
            }
            self.moments = moments
            WaveStore.shared.seed(moments: moments)
            CommentStore.shared.seed(moments: moments)
        } catch is CancellationError {
        } catch let urlError as URLError where urlError.code == .cancelled {
        } catch {
            self.errorMessage = error.localizedDescription
        }
    }

    private func loadMatched(userID: String) async throws -> [Moment] {
        let loc = await LocationManager.shared.locationAsync(timeout: 3.0)
        var path = "/moments/matched"
        if let c = loc?.coordinate {
            path += "?lat=\(c.latitude)&lng=\(c.longitude)"
        }
        let moments: [Moment] = try await APIClient.shared.get(path, userID: userID)
        return applyYouTubeMatchBonus(to: moments)
    }

    /// YouTube 파동끼리 매칭 시 보너스 점수 추가
    /// - 같은 videoId: +0.3
    /// - 같은 채널: +0.1 (추후 구현 — channel 정보 서버 응답 추가 필요)
    private func applyYouTubeMatchBonus(to moments: [Moment]) -> [Moment] {
        // YouTube 파동의 videoId 빈도 집계
        let videoCounts: [String: Int] = moments.reduce(into: [:]) { counts, m in
            if let vid = m.youtubeVideoId { counts[vid, default: 0] += 1 }
        }

        return moments.map { moment in
            guard moment.contentType == "youtube",
                  let videoId = moment.youtubeVideoId,
                  let count = videoCounts[videoId], count > 1,
                  var score = moment.matchScore
            else { return moment }

            // 동일 videoId가 2개 이상 → 보너스 +0.3 (최대 1.0)
            score = min(1.0, score + 0.3)
            var updated = moment
            updated.matchScore = score
            return updated
        }
    }
}
