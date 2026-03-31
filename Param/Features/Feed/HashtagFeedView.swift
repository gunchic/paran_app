import SwiftUI
import Combine

// ─────────────────────────────────────────
// HashtagFeedView — 해시태그별 파동 피드
// ─────────────────────────────────────────
struct HashtagFeedView: View {
    let tag: String

    @EnvironmentObject var appState: AppState
    @StateObject private var vm   = HashtagFeedViewModel()
    @State private var sortOrder  = HashtagSortOrder.latest

    var body: some View {
        VStack(spacing: 0) {

            // ── 정렬 선택 ──────────────────────────────
            Picker("정렬", selection: $sortOrder) {
                Text("최신순").tag(HashtagSortOrder.latest)
                Text("공감순").tag(HashtagSortOrder.waves)
            }
            .pickerStyle(.segmented)
            .padding(Spacing.lg)
            .background(Color(.systemBackground))

            Divider()

            // ── 콘텐츠 ───────────────────────────────
            if vm.isLoading {
                Spacer()
                ProgressView()
                Spacer()
            } else if vm.moments.isEmpty {
                Spacer()
                VStack(spacing: Spacing.md) {
                    Image(systemName: "tag.slash")
                        .font(.system(size: 40))
                    Text("아직 파동이 없어요")
                        .font(.system(size: 16, weight: .medium))
                }
                .foregroundColor(.driftwood)
                Spacer()
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(vm.moments) { moment in
                            MomentCard(moment: moment)
                        }
                    }
                    .padding(.vertical, Spacing.sm)
                }
            }
        }
        .background(Color.warmPaper.ignoresSafeArea())
        .navigationTitle("#\(tag)")
        .navigationBarTitleDisplayMode(.inline)
        .task { await vm.load(tag: tag, sort: sortOrder) }
        .onChange(of: sortOrder) { _, newSort in
            Task { await vm.load(tag: tag, sort: newSort) }
        }
    }
}

// ─────────────────────────────────────────
// Sort
// ─────────────────────────────────────────
enum HashtagSortOrder { case latest, waves }

// ─────────────────────────────────────────
// ViewModel
// ─────────────────────────────────────────
@MainActor
class HashtagFeedViewModel: ObservableObject {
    @Published var moments: [Moment]   = []
    @Published var isLoading           = false

    func load(tag: String, sort: HashtagSortOrder) async {
        isLoading = true
        defer { isLoading = false }

        let sortParam = sort == .waves ? "waves" : "latest"
        let encoded   = tag.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? tag
        guard let result: [Moment] = try? await APIClient.shared.get(
            "/moments/tag/\(encoded)?sort=\(sortParam)"
        ) else { return }
        moments = result
    }
}
