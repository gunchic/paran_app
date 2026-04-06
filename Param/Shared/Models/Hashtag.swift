import Foundation

/// wave_hashtags 테이블 매핑
struct Hashtag: Identifiable, Codable {
    let id: UUID
    let momentId: UUID
    let tag: String
    let createdAt: Date
}
