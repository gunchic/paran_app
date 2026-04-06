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

    func loadMore() async {
        guard !isLoadingMore, hasMore, !isLoading else { return }
        isLoadingMore = true
        do {
            let nextPage = currentPage + 1
            let result = try await service.fetchFeed(page: nextPage)
            items.append(contentsOf: result)
            currentPage = nextPage
            hasMore = result.count == pageSize
        } catch { /* 조용히 처리 */ }
        isLoadingMore = false
    }

    // MARK: - 나도그래 낙관적 업데이트 (해당 인덱스만 교체, 스크롤 위치 유지)
    func toggleResonate(item: WaveFeedItem) async {
        guard let idx = items.firstIndex(where: { $0.id == item.id }) else { return }
        guard let userId = try? await SupabaseManager.shared.client.auth.session.user.id else { return }

        let wasResonated = items[idx].isResonated
        // 낙관적 업데이트
        items[idx].isResonated = !wasResonated
        items[idx].waveCount += wasResonated ? -1 : 1

        do {
            try await service.toggleResonate(momentId: item.id, userId: userId)
        } catch {
            // 롤백
            items[idx].isResonated = wasResonated
            items[idx].waveCount += wasResonated ? 1 : -1
        }
    }
}
