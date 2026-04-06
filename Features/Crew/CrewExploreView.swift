import SwiftUI

/// CR-01 크루 탐색 화면
struct CrewExploreView: View {
    @StateObject private var viewModel = CrewExploreViewModel()
    @State private var showCreate = false

    var body: some View {
        ZStack {
            Color.paper.ignoresSafeArea()

            VStack(spacing: 0) {
                searchBar
                contentArea
            }
        }
        .navigationTitle("크루 탐색")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showCreate = true
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 17, weight: .medium))
                        .foregroundColor(.void)
                }
            }
        }
        .sheet(isPresented: $showCreate) {
            CrewCreateView()
        }
        .task { await viewModel.loadInitial() }
    }

    // MARK: - 검색 바
    private var searchBar: some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 15))
                .foregroundColor(.ash)
            TextField("크루 이름 검색", text: $viewModel.searchText)
                .foregroundColor(.void)
                .font(.paramBody)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.sm)
        .background(Color.surfaceContainer)
        .clipShape(RoundedRectangle(cornerRadius: Radius.md, style: .continuous))
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.sm)
    }

    // MARK: - 콘텐츠 분기
    @ViewBuilder
    private var contentArea: some View {
        if viewModel.searchText.trimmingCharacters(in: .whitespaces).isEmpty {
            browseContent
        } else {
            searchContent
        }
    }

    // MARK: - 검색 결과
    private var searchContent: some View {
        ScrollView {
            LazyVStack(spacing: Spacing.sm) {
                if viewModel.isSearching {
                    ProgressView().tint(.ash).padding(.vertical, Spacing.md)
                } else if viewModel.searchResults.isEmpty {
                    Text("검색 결과가 없어요")
                        .captionStyle()
                        .foregroundColor(.ash)
                        .padding(.vertical, Spacing.lg)
                        .frame(maxWidth: .infinity)
                } else {
                    ForEach(viewModel.searchResults) { crew in
                        NavigationLink(destination: CrewProfileView(crew: crew)) {
                            crewRow(crew)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(.horizontal, Spacing.md)
        }
    }

    // MARK: - 탐색 (인기 + 최신)
    private var browseContent: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: Spacing.lg) {
                if viewModel.isLoadingInitial {
                    ProgressView()
                        .tint(.ash)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Spacing.lg)
                } else {
                    if !viewModel.popularCrews.isEmpty {
                        crewSection(title: "인기 크루", crews: viewModel.popularCrews)
                    }
                    if !viewModel.recentCrews.isEmpty {
                        crewSection(title: "최신 크루", crews: viewModel.recentCrews)
                    }
                    if viewModel.popularCrews.isEmpty && viewModel.recentCrews.isEmpty {
                        VStack(spacing: Spacing.sm) {
                            Text("아직 크루가 없어요")
                                .bodyStyle()
                                .foregroundColor(.void)
                            Text("첫 번째 크루를 만들어보세요")
                                .captionStyle()
                                .foregroundColor(.ash)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Spacing.xl)
                    }
                }
            }
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.sm)
        }
    }

    // MARK: - 섹션 헤더 + 목록
    private func crewSection(title: String, crews: [Crew]) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text(title)
                .captionStyle()
                .foregroundColor(.ash)

            ForEach(crews) { crew in
                NavigationLink(destination: CrewProfileView(crew: crew)) {
                    crewRow(crew)
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - 크루 행 카드
    private func crewRow(_ crew: Crew) -> some View {
        HStack(spacing: Spacing.md) {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(crew.displayName)
                    .bodyStyle()
                    .foregroundColor(.void)

                HStack(spacing: Spacing.xs) {
                    Text(crew.crewType == "keyword" ? "키워드" : "감정")
                        .captionStyle()
                        .foregroundColor(.wave600)
                        .padding(.horizontal, Spacing.sm)
                        .padding(.vertical, 2)
                        .background(Color.wave400.opacity(0.1))
                        .clipShape(Capsule())

                    Text("멤버 \(crew.memberCount)명")
                        .captionStyle()
                        .foregroundColor(.ash)
                }
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.slate)
        }
        .paramCard()
    }
}
