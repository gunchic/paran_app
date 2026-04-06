import SwiftUI

/// C-01 홈 피드 화면
struct HomeFeedView: View {
    @StateObject private var viewModel = HomeFeedViewModel()
    @EnvironmentObject private var authManager: AuthManager

    var body: some View {
        ZStack(alignment: .top) {
            Color.paper.ignoresSafeArea()

            VStack(spacing: 0) {
                header
                feedContent
            }
        }
        .task { await viewModel.loadInitial() }
    }

    // MARK: - 헤더 (No-Line Rule)
    private var header: some View {
        HStack {
            Text("PARAM")
                .heading2Style()
                .foregroundColor(.void)
                .tracking(6)

            Spacer()

            NavigationLink(destination: CrewExploreView()) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.void)
            }
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.sm)
        .background(Color.paper)
    }

    // MARK: - 피드 콘텐츠
    @ViewBuilder
    private var feedContent: some View {
        if viewModel.isLoading && viewModel.items.isEmpty {
            Spacer()
            ProgressView().tint(.wave400)
            Spacer()
        } else if viewModel.items.isEmpty {
            emptyState
        } else {
            feedList
        }
    }

    // MARK: - 피드 리스트 + 무한스크롤
    private var feedList: some View {
        ScrollView {
            LazyVStack(spacing: Spacing.md) {
                ForEach(viewModel.items) { item in
                    NavigationLink(destination: WaveDetailView(item: item)) {
                        WaveCardView(item: item) { crewId, crewName in
                            // 크루 탭 → 추후 CrewFeedView 연결
                        }
                    }
                    .buttonStyle(.plain)
                    .onAppear {
                        if item.id == viewModel.items.last?.id {
                            Task { await viewModel.loadMore() }
                        }
                    }
                }

                if viewModel.isLoadingMore {
                    ProgressView().tint(.ash).padding(.vertical, Spacing.md)
                }
            }
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.sm)
        }
        .refreshable { await viewModel.loadInitial() }
    }

    // MARK: - 빈 피드
    private var emptyState: some View {
        VStack(spacing: Spacing.sm) {
            Spacer()
            Text("아직 파동이 없어요")
                .bodyStyle()
                .foregroundColor(.void)
            Text("첫 번째 파동을 올려보세요")
                .captionStyle()
                .foregroundColor(.ash)
            Spacer()
        }
    }
}
