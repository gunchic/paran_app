import Foundation
import Combine

/// 피드 카드와 상세화면 간 댓글 카운트를 동기화하는 공유 저장소
final class CommentStore: ObservableObject {
    static let shared = CommentStore()

    // momentID → comment count
    @Published private(set) var counts: [String: Int] = [:]

    private init() {}

    func count(for momentID: String) -> Int {
        counts[momentID] ?? 0
    }

    func setCount(_ count: Int, for momentID: String) {
        counts[momentID] = count
    }

    /// 피드 목록 일괄 초기화 (서버 응답 기준)
    func seed(moments: [Moment]) {
        for m in moments {
            counts[m.id] = max(counts[m.id] ?? 0, m.commentCount)
        }
    }

    /// 댓글 작성 성공 후 낙관적 증가
    func increment(for momentID: String) {
        counts[momentID] = (counts[momentID] ?? 0) + 1
    }
}
