import Foundation
import Supabase

/// 파동 피드 Supabase 쿼리 전담 서비스
final class WaveService {
    static let shared = WaveService()
    private let supabase = SupabaseManager.shared.client
    private let pageSize = 20

    private init() {}

    /// 홈 피드 파동 목록 조회 (페이지네이션)
    func fetchFeed(page: Int) async throws -> [WaveFeedItem] {
        let offset = page * pageSize
        return try await supabase
            .from("moment_feed")
            .select("id, user_id, body, image_url, thumbnail_url, youtube_video_id, youtube_thumbnail, crew_id, crew_name, author_nickname, author_profile_image_url, wave_count, comment_count, created_at")
            .order("created_at", ascending: false)
            .range(from: offset, to: offset + pageSize - 1)
            .execute()
            .value
    }
}
