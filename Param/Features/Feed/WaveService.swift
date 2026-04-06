import Foundation

/// 파동(moment) + 나도그래(wave resonance) 서비스
final class WaveService {
    static let shared = WaveService()
    private let supabase = SupabaseManager.shared.client
    private let pageSize = 20

    private let feedSelect = """
        id, user_id, author_nickname, author_profile_image_url, \
        body, image_url, thumbnail_url, youtube_video_id, youtube_thumbnail, \
        wave_count, comment_count, crew_id, crew_name, created_at
        """

    private init() {}

    // MARK: - 피드 조회

    func fetchFeed(page: Int) async throws -> [WaveFeedItem] {
        let offset = page * pageSize
        return try await supabase
            .from("moment_feed")
            .select(feedSelect)
            .order("created_at", ascending: false)
            .range(from: offset, to: offset + pageSize - 1)
            .execute()
            .value
    }

    // MARK: - 파람 올리기 (moments INSERT)

    struct MomentCreate: Encodable {
        let userId: UUID
        let body: String
        let imageUrl: String?
        let thumbnailUrl: String?
        let contentType: String
        let imageOffsetY: Double?
    }

    func createMoment(
        userId: UUID,
        body: String,
        imageUrl: String? = nil,
        thumbnailUrl: String? = nil,
        imageOffsetY: Double? = nil
    ) async throws -> UUID {
        let contentType = imageUrl != nil ? "image" : "text"
        let payload = MomentCreate(
            userId: userId,
            body: body,
            imageUrl: imageUrl,
            thumbnailUrl: thumbnailUrl,
            contentType: contentType,
            imageOffsetY: imageOffsetY
        )
        struct CreatedMoment: Decodable { let id: UUID }
        let result: [CreatedMoment] = try await supabase
            .from("moments")
            .insert(payload)
            .select("id")
            .execute()
            .value
        guard let id = result.first?.id else { throw ParamError.unknown("파동 등록 실패") }
        return id
    }

    // MARK: - 해시태그 등록 (wave_hashtags INSERT)

    func insertHashtags(_ tags: [String], momentId: UUID) async throws {
        guard !tags.isEmpty else { return }
        struct HashtagInsert: Encodable { let momentId: UUID; let tag: String }
        let rows = tags.map { HashtagInsert(momentId: momentId, tag: $0.lowercased()) }
        try await supabase
            .from("wave_hashtags")
            .insert(rows)
            .execute()
    }

    // MARK: - 나도그래 토글 (waves INSERT/DELETE)

    private struct ResonanceCheck: Decodable { let id: UUID }

    struct ResonanceInsert: Encodable {
        let momentId: UUID
        let userId: UUID
    }

    func toggleResonate(momentId: UUID, userId: UUID) async throws -> Bool {
        let existing: [ResonanceCheck] = try await supabase
            .from("waves")
            .select("id")
            .eq("moment_id", value: momentId.uuidString)
            .eq("user_id", value: userId.uuidString)
            .execute()
            .value

        if existing.isEmpty {
            try await supabase
                .from("waves")
                .insert(ResonanceInsert(momentId: momentId, userId: userId))
                .execute()
            return true
        } else {
            try await supabase
                .from("waves")
                .delete()
                .eq("moment_id", value: momentId.uuidString)
                .eq("user_id", value: userId.uuidString)
                .execute()
            return false
        }
    }

    func isResonated(momentId: UUID, userId: UUID) async throws -> Bool {
        let rows: [ResonanceCheck] = try await supabase
            .from("waves")
            .select("id")
            .eq("moment_id", value: momentId.uuidString)
            .eq("user_id", value: userId.uuidString)
            .execute()
            .value
        return !rows.isEmpty
    }
}

