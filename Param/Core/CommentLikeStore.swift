import Foundation
import Combine

/// 댓글 좋아요 상태를 피드↔상세화면 간 공유하는 저장소
final class CommentLikeStore: ObservableObject {
    static let shared = CommentLikeStore()

    // commentID → like count (서버값 + 낙관적 조정)
    @Published private(set) var counts: [String: Int] = [:]
    // 현재 유저가 좋아요한 commentID 집합
    @Published private(set) var likedIDs: Set<String> = []

    private init() {}

    func count(for commentID: String) -> Int {
        counts[commentID] ?? 0
    }

    func hasLiked(_ commentID: String) -> Bool {
        likedIDs.contains(commentID)
    }

    /// 서버 응답으로 초기화
    func seed(comments: [Comment]) {
        for c in comments {
            counts[c.id] = c.likeCount
            if c.isLiked { likedIDs.insert(c.id) }
        }
    }

    /// 좋아요 — 낙관적 업데이트
    func recordLike(commentID: String) {
        likedIDs.insert(commentID)
        counts[commentID] = (counts[commentID] ?? 0) + 1
    }

    /// 좋아요 취소 — 낙관적 롤백
    func rollback(commentID: String) {
        likedIDs.remove(commentID)
        counts[commentID] = max(0, (counts[commentID] ?? 0) - 1)
    }
}
