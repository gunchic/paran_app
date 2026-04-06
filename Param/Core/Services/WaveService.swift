import Foundation
import UIKit

/// 파동(moment) + 나도그래(wave resonance) 서비스
final class WaveService {
    static let shared = WaveService()
    private let supabase = SupabaseManager.shared.client
    private let pageSize = 20

    private let feedSelect = """
        id, user_id, author_nickname, author_profile_image_url,
        body, image_url, thumbnail_url, youtube_video_id, youtube_thumbnail,
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

    // MARK: - 파람 올리기

    struct MomentCreate: Encodable {
        let userId: UUID
        let body: String
        let imageUrl: String?
        let thumbnailUrl: String?
        let contentType: String
    }

    func createMoment(
        userId: UUID,
        body: String,
        imageUrl: String? = nil,
        thumbnailUrl: String? = nil
    ) async throws {
        let contentType = imageUrl != nil ? "image" : "text"
        let payload = MomentCreate(
            userId: userId,
            body: body,
            imageUrl: imageUrl,
            thumbnailUrl: thumbnailUrl,
            contentType: contentType
        )
        try await supabase
            .from("moments")
            .insert(payload)
            .execute()
    }

    // MARK: - 이미지 업로드

    func uploadImage(_ image: UIImage, userId: UUID) async throws -> (imageUrl: String, thumbnailUrl: String) {
        guard let compressed = image.jpegData(compressionQuality: 0.8),
              let thumbnail = image.resized(to: CGSize(width: 200, height: 200))?.jpegData(compressionQuality: 0.7)
        else { throw ParamError.unknown("이미지 변환 실패") }

        let fileName = "\(userId.uuidString)/\(UUID().uuidString)"
        let thumbName = "\(userId.uuidString)/thumb_\(UUID().uuidString)"

        try await supabase.storage
            .from("waves")
            .upload(fileName, data: compressed, options: .init(contentType: "image/jpeg", upsert: false))

        try await supabase.storage
            .from("waves")
            .upload(thumbName, data: thumbnail, options: .init(contentType: "image/jpeg", upsert: false))

        let baseUrl = "https://ptnltusonbczrquzurti.supabase.co/storage/v1/object/public/waves/"
        return (imageUrl: baseUrl + fileName, thumbnailUrl: baseUrl + thumbName)
    }

    // MARK: - 나도그래 토글

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

    private struct ResonanceCheck: Decodable {
        let id: UUID
    }
}

// MARK: - UIImage 리사이즈 헬퍼
private extension UIImage {
    func resized(to size: CGSize) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        defer { UIGraphicsEndImageContext() }
        draw(in: CGRect(origin: .zero, size: size))
        return UIGraphicsGetImageFromCurrentImageContext()
    }
}
