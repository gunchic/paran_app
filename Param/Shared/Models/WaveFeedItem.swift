import Foundation

/// moment_feed VIEW 매핑 모델 — 홈 피드 카드 데이터
struct WaveFeedItem: Identifiable, Codable {
    let id: UUID
    let userId: UUID
    let body: String
    let imageUrl: String?
    let thumbnailUrl: String?
    let youtubeVideoId: String?
    let youtubeThumbnail: String?
    let crewId: UUID?
    let crewName: String?
    let authorNickname: String?
    let authorProfileImageUrl: String?
    var waveCount: Int
    let commentCount: Int
    let createdAt: Date

    /// 이미지 포커싱 위치 (0.0=상단 / 0.5=중앙 / 1.0=하단, 기본 0.5)
    var imageOffsetY: Double = 0.5

    // 별도 조회 후 주입 (moment_feed에 없는 데이터 — Codable 제외)
    var hashtags: [String] = []
    var topComment: Comment? = nil
    var isResonated: Bool = false

    enum CodingKeys: String, CodingKey {
        case id, userId, body, imageUrl, thumbnailUrl
        case youtubeVideoId, youtubeThumbnail
        case crewId, crewName, authorNickname, authorProfileImageUrl
        case waveCount, commentCount, createdAt
        case imageOffsetY
    }

    // imageOffsetY: DB에 없으면 0.5로 폴백 (컬럼 마이그레이션 전 호환)
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        userId = try c.decode(UUID.self, forKey: .userId)
        body = try c.decode(String.self, forKey: .body)
        imageUrl = try c.decodeIfPresent(String.self, forKey: .imageUrl)
        thumbnailUrl = try c.decodeIfPresent(String.self, forKey: .thumbnailUrl)
        youtubeVideoId = try c.decodeIfPresent(String.self, forKey: .youtubeVideoId)
        youtubeThumbnail = try c.decodeIfPresent(String.self, forKey: .youtubeThumbnail)
        crewId = try c.decodeIfPresent(UUID.self, forKey: .crewId)
        crewName = try c.decodeIfPresent(String.self, forKey: .crewName)
        authorNickname = try c.decodeIfPresent(String.self, forKey: .authorNickname)
        authorProfileImageUrl = try c.decodeIfPresent(String.self, forKey: .authorProfileImageUrl)
        waveCount = try c.decode(Int.self, forKey: .waveCount)
        commentCount = try c.decode(Int.self, forKey: .commentCount)
        createdAt = try c.decode(Date.self, forKey: .createdAt)
        imageOffsetY = try c.decodeIfPresent(Double.self, forKey: .imageOffsetY) ?? 0.5
    }

    /// 표시할 이미지 URL (thumbnail 우선, 없으면 유튜브 썸네일)
    var displayImageUrl: String? {
        if let thumb = thumbnailUrl, !thumb.isEmpty { return thumb }
        if let ytThumb = youtubeThumbnail, !ytThumb.isEmpty { return ytThumb }
        if let ytId = youtubeVideoId, !ytId.isEmpty {
            return "https://img.youtube.com/vi/\(ytId)/hqdefault.jpg"
        }
        return nil
    }

    var hasYouTube: Bool {
        youtubeVideoId != nil && !(youtubeVideoId?.isEmpty ?? true)
    }
}
