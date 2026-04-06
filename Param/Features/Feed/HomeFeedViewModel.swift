import SwiftUI

/// 홈 피드 상태 관리 + 페이지네이션 로직
@MainActor
final class HomeFeedViewModel: ObservableObject {
    @Published var items: [WaveFeedItem] = []
    @Published var isLoading: Bool = false
    @Published var isLoadingMore: Bool = false
    @Published var hasMore: Bool = true
    @Published var errorMessage: String? = nil

    private let pageSize = 20
    private var currentPage = 0
    private let service = WaveService.shared

    /// 초기 로드 (pull-to-refresh 포함)
    func loadInitial() async {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil
        do {
            let result = try await service.fetchFeed(page: 0)
            items = result
            currentPage = 0
            hasMore = result.count == pageSize
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    /// 무한스크롤 추가 로드
    func loadMore() async {
        guard !isLoadingMore, hasMore, !isLoading else { return }
        isLoadingMore = true
        do {
            let nextPage = currentPage + 1
            let result = try await service.fetchFeed(page: nextPage)
            items.append(contentsOf: result)
            currentPage = nextPage
            hasMore = result.count == pageSize
        } catch {
            // 추가 로드 실패는 조용히 처리
        }
        isLoadingMore = false
    }
}
