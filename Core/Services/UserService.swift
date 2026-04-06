import Foundation

/// 유저 프로필 조회 / 업데이트 서비스
final class UserService {
    static let shared = UserService()
    private let supabase = SupabaseManager.shared.client

    private let userSelect = "id, email, nickname, avatar_id, current_crew_id, is_profile_set, created_at"

    private init() {}

    func fetchCurrentUser(userId: UUID) async throws -> User {
        let rows: [User] = try await supabase
            .from("users")
            .select(userSelect)
            .eq("id", value: userId.uuidString)
            .limit(1)
            .execute()
            .value
        guard let user = rows.first else { throw ParamError.notFound }
        return user
    }

    func fetchUserProfile(userId: UUID) async throws -> User {
        let rows: [User] = try await supabase
            .from("users")
            .select(userSelect)
            .eq("id", value: userId.uuidString)
            .limit(1)
            .execute()
            .value
        guard let user = rows.first else { throw ParamError.notFound }
        return user
    }

    func updateProfile(userId: UUID, nickname: String, avatarId: UUID?) async throws -> User {
        let update = UserProfileUpdate(nickname: nickname, avatarId: avatarId)
        let rows: [User] = try await supabase
            .from("users")
            .update(update)
            .eq("id", value: userId.uuidString)
            .select(userSelect)
            .execute()
            .value
        guard let user = rows.first else { throw ParamError.unknown("업데이트 실패") }
        return user
    }
}
