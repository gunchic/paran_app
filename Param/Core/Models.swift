import Foundation

struct Moment: Identifiable, Codable {
    let id: String
    let userId: String
    let authorNickname: String?
    let authorProfileImageUrl: String?
    let body: String?
    let imageUrl: String?       // 압축본 800×800 (상세화면용)
    let thumbnailUrl: String?   // 썸네일 200×200 (피드 카드용)
    let location: String?
    let latitude: Double?
    let longitude: Double?
    let tags: [String]?   // 서버에서 null 올 수 있음
    let waveCount: Int
    let commentCount: Int
    var matchScore: Double? // 매칭 피드 전용 (0.0–1.0) — 클라이언트 보너스 적용 가능
    let expiresAt: Date
    let createdAt: Date

    // MARK: - YouTube 콘텐츠
    /// "photo" | "youtube" | "text" — nil이면 기존 photo로 간주
    let contentType: String?
    let youtubeVideoId: String?
    let youtubeThumbnail: String?
    let youtubeTitle: String?
}

struct Wave: Identifiable, Codable, Hashable {
    let id: String
    let momentId: String
    let userId: String
    let nickname: String?
    let profileImageUrl: String?
    let body: String?
    let imageUrl: String?
    let latitude: Double?
    let longitude: Double?
    let createdAt: Date
}

struct GraphNode: Codable {
    let userId: String
    let nickname: String
    let connections: [Connection]
    let topTags: [TagWeight]
}

struct Connection: Codable {
    let userId: String
    let nickname: String
    let strength: Int
}

struct TagWeight: Codable {
    let tag: String
    let count: Int
}

struct SimilarUser: Codable {
    let userId: String
    let nickname: String
    let sharedMoments: Int
    let commonTags: [String]
}

struct User: Identifiable, Codable {
    let id: String
    let nickname: String
    let profileImageUrl: String?
    let email: String?
    let socialProvider: String?
    let createdAt: Date
}

struct CreateMomentRequest: Encodable {
    let body: String?
    let imageUrl: String?
    let thumbnailUrl: String?
    let location: String?
    let latitude: Double?
    let longitude: Double?
    let tags: [String]
    // YouTube 콘텐츠
    let contentType: String?
    let youtubeVideoId: String?
    let youtubeThumbnail: String?
    let youtubeTitle: String?
}

// MARK: - 댓글

struct Comment: Identifiable, Codable {
    let id: String
    let momentId: String
    let userId: String
    let authorNickname: String?
    let authorProfileImageUrl: String?
    let body: String?
    let imageUrl: String?
    let likeCount: Int
    let isLiked: Bool
    let createdAt: Date
}

struct CreateCommentRequest: Encodable {
    let body: String?
    let imageUrl: String?
}

// MARK: - 팔로우

struct FollowUser: Identifiable, Codable {
    let id: String
    let nickname: String
    let profileImageUrl: String?
    let isFollowing: Bool
    let followerCount: Int
    let followingCount: Int
}

struct FollowStats: Codable {
    let followerCount: Int
    let followingCount: Int
}

struct FollowRelation: Codable {
    let id: String
    let followerId: String
    let followingId: String
    let createdAt: Date
}

// MARK: - 소셜 로그인

struct SocialLoginRequest: Encodable {
    let code: String
}

/// 백엔드 POST /auth/{provider} 응답
/// - nickname이 nil이면 신규 유저 → ProfileSetupView로 이동
/// - nickname이 있으면 기존 유저 → 바로 메인으로 이동
struct SocialAuthResponse: Decodable {
    let id: String
    let nickname: String?
    let profileImageUrl: String?
}
