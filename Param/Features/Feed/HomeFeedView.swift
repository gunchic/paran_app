import SwiftUI

/// C-01 홈 피드 화면
struct HomeFeedView: View {
    @StateObject private var viewModel = HomeFeedViewModel()
    @EnvironmentObject private var authManager: AuthManager
    @State private var showCreateWave = false

    var body: some View {
        ZStack(alignment: .top) {
            Color.paper.ignoresSafeArea()

            VStack(spacing: 0) {
                header
                feedContent
            }
        }
        .sheet(isPresented: $showCreateWave) {
            CreateWaveView {
                Task { await viewModel.loadInitial() }
            }
        }
        .task { await viewModel.loadInitial() }
    }

    // MARK: - 헤더 (글래스모피즘, No-Line Rule)
    private var header: some View {
        HStack {
            Text("PARAM")
                .font(.system(size: 20, weight: .black))
                .foregroundColor(.void)
                .tracking(3)

            Spacer()

            NavigationLink(destination: CrewExploreView()) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.void)
            }
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.sm)
        .glassHeader()
    }

    // MARK: - 피드 콘텐츠
    @ViewBuilder
    private var feedContent: some View {
        if viewModel.isLoading && viewModel.items.isEmpty {
            Spacer()
            ParamLoadingView()
            Spacer()
        } else if let error = viewModel.errorMessage, viewModel.items.isEmpty {
            Spacer()
            ParamErrorView(message: error) {
                Task { await viewModel.loadInitial() }
            }
            Spacer()
        } else if viewModel.items.isEmpty {
            Spacer()
            ParamEmptyView(
                icon: "waveform",
                title: "아직 파동이 없어요",
                subtitle: "첫 번째 파동을 올려보세요"
            )
            Spacer()
        } else {
            feedList
        }
    }

    // MARK: - 피드 리스트 + 무한스크롤
    private var feedList: some View {
        ScrollView {
            LazyVStack(spacing: 1) {
                ForEach(viewModel.items) { item in
                    NavigationLink(destination: WaveDetailView(item: item)) {
                        WaveCardView(item: item) { crewId, crewName in
                            // TODO: CrewFeedView 연결
                        } onResonateTap: {
                            let userId = authManager.currentUser!.id
                            Task { await viewModel.toggleResonate(item: item, userId: userId) }
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
            .padding(.vertical, Spacing.sm)
        }
        .refreshable { await viewModel.loadInitial() }
    }
}
