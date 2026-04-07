import Foundation

// MARK: - UserStats
struct UserStats {
    var waveCount: Int = 0
    var resonateReceivedCount: Int = 0
    var crewCount: Int = 0
}

// MARK: - MyWave (내 파동 그리드용)
struct MyWave: Identifiable, Decodable {
    let id: UUID
    let body: String
    let thumbnailUrl: String?
    let imageUrl: String?
    let createdAt: Date
}

// MARK: - MyCrewMembership (내 크루 목록용)
struct MyCrewMembership: Identifiable {
    var id: UUID { crew.id }
    let crew: Crew
    let isFounder: Bool
    let joinedAt: Date
}

// MARK: - UserService
final class UserService {
    static let shared = UserService()
    private let supabase = SupabaseManager.shared.client

    private let userSelect = "id, email, nickname, avatar_id, current_crew_id, is_profile_set, created_at"
    private let crewSelect = "id, crew_name, emotion_word, crew_type, founder_user_id, member_count, is_open, description, color_code, founded_at, cell_row, cell_col"

    private init() {}

    // MARK: - 현재 유저 조회

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

    // MARK: - 다른 유저 프로필 조회

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

    // MARK: - 프로필 업데이트

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

    // MARK: - 아바타 URL 조회

    func fetchAvatarUrl(avatarId: UUID?) async -> String? {
        guard let avatarId else { return nil }
        struct AvatarRow: Decodable { let imageUrl: String }
        let rows: [AvatarRow]? = try? await supabase
            .from("avatars")
            .select("image_url")
            .eq("id", value: avatarId.uuidString)
            .limit(1)
            .execute()
            .value
        return rows?.first?.imageUrl
    }

    // MARK: - 활동 통계

    func fetchMyStats(userId: UUID) async throws -> UserStats {
        // 내 파동 ID 목록 (wave_count + resonate 기준)
        struct IDRow: Decodable { let id: UUID }
        let momentRows: [IDRow] = try await supabase
            .from("moments")
            .select("id")
            .eq("user_id", value: userId.uuidString)
            .limit(500)
            .execute()
            .value

        let waveCount = momentRows.count

        // 나도그래 받은 수 (내 파동에 달린 공감)
        var resonateCount = 0
        if !momentRows.isEmpty {
            let ids = momentRows.map { $0.id.uuidString }
            let resonateResponse = try await supabase
                .from("waves")
                .select("id", count: .exact)
                .in("moment_id", values: ids)
                .execute()
            resonateCount = resonateResponse.count ?? 0
        }

        // 크루 수
        let crewResponse = try await supabase
            .from("crew_members")
            .select("id", count: .exact)
            .eq("user_id", value: userId.uuidString)
            .eq("is_active", value: true)
            .execute()
        let crewCount = crewResponse.count ?? 0

        return UserStats(
            waveCount: waveCount,
            resonateReceivedCount: resonateCount,
            crewCount: crewCount
        )
    }

    // MARK: - 내 파동 목록 (그리드용)

    func fetchMyWaves(userId: UUID, limit: Int = 30) async throws -> [MyWave] {
        try await supabase
            .from("moments")
            .select("id, body, thumbnail_url, image_url, created_at")
            .eq("user_id", value: userId.uuidString)
            .order("created_at", ascending: false)
            .limit(limit)
            .execute()
            .value
    }

    // MARK: - 내 크루 목록

    func fetchMyCrews(userId: UUID) async throws -> [MyCrewMembership] {
        struct CrewMemberRow: Decodable {
            let isFounder: Bool
            let joinedAt: Date
            let crews: Crew
        }

        let rows: [CrewMemberRow] = try await supabase
            .from("crew_members")
            .select("is_founder, joined_at, crews(\(crewSelect))")
            .eq("user_id", value: userId.uuidString)
            .eq("is_active", value: true)
            .order("joined_at", ascending: false)
            .execute()
            .value

        return rows.map { MyCrewMembership(crew: $0.crews, isFounder: $0.isFounder, joinedAt: $0.joinedAt) }
    }

    // MARK: - 회원 탈퇴

    func deleteAccount(userId: UUID) async throws {
        // 1. 내 파동 이미지 Storage 삭제 시도
        struct IDRow: Decodable { let id: UUID }
        let momentRows: [IDRow] = (try? await supabase
            .from("moments")
            .select("id")
            .eq("user_id", value: userId.uuidString)
            .execute()
            .value) ?? []

        if !momentRows.isEmpty {
            let thumbPaths = momentRows.map { "thumbnails/\($0.id.uuidString).jpg" }
            let compPaths = momentRows.map { "compressed/\($0.id.uuidString).jpg" }
            try? await supabase.storage.from("waves").remove(paths: thumbPaths)
            try? await supabase.storage.from("waves").remove(paths: compPaths)
        }

        // 2. 내 파동 삭제 (DB cascade로 관련 데이터 정리)
        try await supabase
            .from("moments")
            .delete()
            .eq("user_id", value: userId.uuidString)
            .execute()

        // 3. 유저 레코드 삭제
        try await supabase
            .from("users")
            .delete()
            .eq("id", value: userId.uuidString)
            .execute()

        // 4. 로그아웃 (AppRouter가 LoginView로 전환)
        try await supabase.auth.signOut()
    }
}
