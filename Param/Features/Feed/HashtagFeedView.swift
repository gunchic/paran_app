import SwiftUI

/// 해시태그 피드 — 특정 태그의 파동 모아보기
struct HashtagFeedView: View {
    let tag: String

    @StateObject private var viewModel: HashtagFeedViewModel

    init(tag: String) {
        self.tag = tag
        _viewModel = StateObject(wrappedValue: HashtagFeedViewModel(tag: tag))
    }

    var body: some View {
        ZStack {
            Color.paper.ignoresSafeArea()

            if viewModel.isLoading {
                ParamLoadingView(isFullScreen: true)
            } else if viewModel.items.isEmpty {
                ParamEmptyView(
                    icon: "number",
                    title: "아직 파동이 없어요",
                    subtitle: "#\(tag) 태그의 첫 번째 파동을 올려보세요"
                )
            } else {
                ScrollView {
                    LazyVStack(spacing: 1) {
                        ForEach(viewModel.items) { item in
                            NavigationLink(destination: WaveDetailView(item: item)) {
                                WaveCardView(item: item)
                            }
                            .buttonStyle(.plain)
                            .onAppear {
                                if item.id == viewModel.items.last?.id {
                                    Task { await viewModel.loadMore() }
                                }
                            }
                        }
                        if viewModel.isLoadingMore {
                            ProgressView().tint(.ash).padding(Spacing.md)
                        }
                    }
                }
                .refreshable { await viewModel.load() }
            }
        }
        .navigationTitle("#\(tag)")
        .navigationBarTitleDisplayMode(.large)
        .task { await viewModel.load() }
    }
}

// MARK: - ViewModel

@MainActor
final class HashtagFeedViewModel: ObservableObject {
    @Published var items: [WaveFeedItem] = []
    @Published var isLoading = false
    @Published var isLoadingMore = false
    @Published var hasMore = true

    private let tag: String
    private let pageSize = 20
    private var currentPage = 0
    private let supabase = SupabaseManager.shared.client

    private let feedSelect = """
        moment_id,
        moments(id, user_id, body, image_url, thumbnail_url, youtube_video_id, created_at)
        """

    init(tag: String) {
        self.tag = tag
    }

    func load() async {
        isLoading = true
        defer { isLoading = false }
        do {
            items = try await fetchPage(0)
            currentPage = 0
            hasMore = items.count == pageSize
        } catch { /* 조용히 처리 */ }
    }

    func loadMore() async {
        guard !isLoadingMore, hasMore else { return }
        isLoadingMore = true
        defer { isLoadingMore = false }
        do {
            let next = try await fetchPage(currentPage + 1)
            items.append(contentsOf: next)
            currentPage += 1
            hasMore = next.count == pageSize
        } catch { }
    }

    private func fetchPage(_ page: Int) async throws -> [WaveFeedItem] {
        // wave_hashtags → moment_id 조회 → moment_feed JOIN
        struct HashtagRow: Decodable { let momentId: UUID }

        let offset = page * pageSize
        let tagRows: [HashtagRow] = try await supabase
            .from("wave_hashtags")
            .select("moment_id")
            .eq("tag", value: tag)
            .order("created_at", ascending: false)
            .range(from: offset, to: offset + pageSize - 1)
            .execute()
            .value

        guard !tagRows.isEmpty else { return [] }

        let ids = tagRows.map { $0.momentId.uuidString }
        let feedItems: [WaveFeedItem] = try await supabase
            .from("moment_feed")
            .select("id, user_id, author_nickname, author_profile_image_url, body, image_url, thumbnail_url, youtube_video_id, youtube_thumbnail, wave_count, comment_count, crew_id, crew_name, created_at")
            .in("id", values: ids)
            .order("created_at", ascending: false)
            .execute()
            .value

        return feedItems
    }
}
