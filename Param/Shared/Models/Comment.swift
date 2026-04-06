import Foundation

/// comments 테이블 매핑 (moment_id 기반)
struct Comment: Identifiable, Codable, Equatable {
    let id: UUID
    let momentId: UUID
    let userId: UUID
    let body: String
    let imageUrl: String?
    let resonateCount: Int
    let createdAt: Date

    // 조인 데이터 (뷰에서 별도 조회)
    var userNickname: String?
    var userAvatarUrl: String?
    var isResonated: Bool?

    static func == (lhs: Comment, rhs: Comment) -> Bool { lhs.id == rhs.id }
}
