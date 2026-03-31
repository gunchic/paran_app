import Foundation
import Combine

/// 피드 카드에 노출할 "좋아요 최다 댓글"을 momentID별로 캐싱
final class TopCommentStore: ObservableObject {
    static let shared = TopCommentStore()

    @Published private(set) var topComments: [String: Comment] = [:]
    private var loading: Set<String> = []

    private init() {}

    func topComment(for momentID: String) -> Comment? {
        topComments[momentID]
    }

    /// 아직 로드되지 않은 경우에만 API 호출 (중복 방지)
    func loadIfNeeded(momentID: String, userID: String?) async {
        guard topComments[momentID] == nil, !loading.contains(momentID) else { return }
        loading.insert(momentID)
        defer { loading.remove(momentID) }

        guard let comment: Comment = try? await APIClient.shared.get(
            "/moments/\(momentID)/top-comment",
            userID: userID
        ) else { return }

        await MainActor.run {
            topComments[momentID] = comment
        }
    }

    /// 댓글 작성 후 캐시 무효화 → 다음 표시 시 재조회
    func invalidate(momentID: String) {
        topComments.removeValue(forKey: momentID)
    }
}
