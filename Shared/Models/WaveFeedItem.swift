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
    let waveCount: Int
    let commentCount: Int
    let createdAt: Date

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
