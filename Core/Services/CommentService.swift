import Foundation

/// 댓글 조회 / 등록 / 나도그래 서비스
final class CommentService {
    static let shared = CommentService()
    private let supabase = SupabaseManager.shared.client

    private let commentSelect = "id, moment_id, user_id, body, image_url, resonate_count, created_at"

    private init() {}

    // MARK: - 댓글 목록 (created_at ASC)

    func fetchComments(momentId: UUID) async throws -> [Comment] {
        let raw: [CommentRaw] = try await supabase
            .from("comments")
            .select(commentSelect)
            .eq("moment_id", value: momentId.uuidString)
            .order("created_at", ascending: true)
            .execute()
            .value

        let userIds = raw.map { $0.userId }
        let profiles = try await fetchProfiles(userIds: userIds)

        return raw.map { row in
            var c = row.toComment()
            let profile = profiles.first { $0.id == row.userId }
            c.userNickname = profile?.nickname
            c.userAvatarUrl = profile?.avatarUrl
            return c
        }
    }

    // MARK: - 상위 댓글 1개 (홈 피드용)

    func fetchTopComment(momentId: UUID) async throws -> Comment? {
        let raw: [CommentRaw] = try await supabase
            .from("comments")
            .select(commentSelect)
            .eq("moment_id", value: momentId.uuidString)
            .order("resonate_count", ascending: false)
            .order("created_at", ascending: false)
            .limit(1)
            .execute()
            .value

        guard let row = raw.first else { return nil }

        let profiles = try await fetchProfiles(userIds: [row.userId])
        var comment = row.toComment()
        let profile = profiles.first { $0.id == row.userId }
        comment.userNickname = profile?.nickname
        comment.userAvatarUrl = profile?.avatarUrl
        return comment
    }

    // MARK: - 댓글 등록

    func createComment(momentId: UUID, userId: UUID, text: String?, imageUrl: String?) async throws -> Comment {
        struct CommentInsert: Encodable {
            let momentId: UUID
            let userId: UUID
            let body: String
            let imageUrl: String?
        }

        let body = text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let insert = CommentInsert(momentId: momentId, userId: userId, body: body, imageUrl: imageUrl)

        let raw: [CommentRaw] = try await supabase
            .from("comments")
            .insert(insert)
            .select(commentSelect)
            .execute()
            .value

        guard let row = raw.first else { throw ParamError.unknown("댓글 등록 실패") }
        return row.toComment()
    }

    // MARK: - 댓글 나도그래 토글

    private struct LikeCheck: Decodable { let id: UUID }

    func toggleCommentResonate(commentId: UUID, userId: UUID) async throws -> Bool {
        let existing: [LikeCheck] = try await supabase
            .from("comment_likes")
            .select("id")
            .eq("comment_id", value: commentId.uuidString)
            .eq("user_id", value: userId.uuidString)
            .execute()
            .value

        if existing.isEmpty {
            struct LikeInsert: Encodable { let commentId: UUID; let userId: UUID }
            try await supabase
                .from("comment_likes")
                .insert(LikeInsert(commentId: commentId, userId: userId))
                .execute()
            return true
        } else {
            try await supabase
                .from("comment_likes")
                .delete()
                .eq("comment_id", value: commentId.uuidString)
                .eq("user_id", value: userId.uuidString)
                .execute()
            return false
        }
    }

    func isCommentResonated(commentId: UUID, userId: UUID) async throws -> Bool {
        let rows: [LikeCheck] = try await supabase
            .from("comment_likes")
            .select("id")
            .eq("comment_id", value: commentId.uuidString)
            .eq("user_id", value: userId.uuidString)
            .execute()
            .value
        return !rows.isEmpty
    }

    // MARK: - 유저 프로필 일괄 조회

    private struct UserProfile: Decodable {
        let id: UUID
        let nickname: String?
        let avatarUrl: String?
    }

    private func fetchProfiles(userIds: [UUID]) async throws -> [UserProfile] {
        guard !userIds.isEmpty else { return [] }
        let ids = userIds.map { $0.uuidString }
        return try await supabase
            .from("users")
            .select("id, nickname, avatar_id")
            .in("id", values: ids)
            .execute()
            .value
    }
}

// MARK: - DB Row → Comment 변환

private struct CommentRaw: Decodable {
    let id: UUID
    let momentId: UUID
    let userId: UUID
    let body: String
    let imageUrl: String?
    let resonateCount: Int
    let createdAt: Date

    func toComment() -> Comment {
        Comment(
            id: id,
            momentId: momentId,
            userId: userId,
            body: body,
            imageUrl: imageUrl,
            resonateCount: resonateCount,
            createdAt: createdAt
        )
    }
}
