import Foundation

final class CrewService {
    static let shared = CrewService()
    private let supabase = SupabaseManager.shared.client
    private init() {}

    private let crewSelect = "id, crew_name, emotion_word, crew_type, founder_user_id, member_count, is_open, description, color_code, founded_at, cell_row, cell_col"

    // MARK: - 조회

    func fetchPopularCrews(limit: Int = 5) async throws -> [Crew] {
        try await supabase
            .from("crews")
            .select(crewSelect)
            .order("member_count", ascending: false)
            .limit(limit)
            .execute()
            .value
    }

    func fetchRecentCrews(limit: Int = 10) async throws -> [Crew] {
        try await supabase
            .from("crews")
            .select(crewSelect)
            .order("founded_at", ascending: false)
            .limit(limit)
            .execute()
            .value
    }

    func fetchCrew(crewId: UUID) async throws -> Crew {
        let rows: [Crew] = try await supabase
            .from("crews")
            .select(crewSelect)
            .eq("id", value: crewId.uuidString)
            .limit(1)
            .execute()
            .value
        guard let crew = rows.first else { throw ParamError.notFound }
        return crew
    }

    func searchCrews(query: String) async throws -> [Crew] {
        try await supabase
            .from("crews")
            .select(crewSelect)
            .or("crew_name.ilike.%\(query)%,emotion_word.ilike.%\(query)%")
            .order("member_count", ascending: false)
            .limit(20)
            .execute()
            .value
    }

    func isNameTaken(_ name: String) async throws -> Bool {
        struct IDOnly: Decodable { let id: UUID }
        let rows: [IDOnly] = try await supabase
            .from("crews")
            .select("id")
            .or("crew_name.ilike.\(name),emotion_word.ilike.\(name)")
            .execute()
            .value
        return !rows.isEmpty
    }

    // MARK: - 생성 (userId 외부에서 주입 — 로그인 베이스)

    func createCrew(userId: UUID, name: String, type: String, description: String?) async throws -> Crew {
        struct CrewInsert: Encodable {
            let crewName: String?
            let emotionWord: String?
            let crewType: String
            let founderUserId: UUID
            let description: String?
            let isOpen: Bool
            let memberCount: Int
        }

        let insert = CrewInsert(
            crewName: type == "keyword" ? name : nil,
            emotionWord: type == "emotion" ? name : nil,
            crewType: type,
            founderUserId: userId,
            description: (description?.isEmpty == false) ? description : nil,
            isOpen: true,
            memberCount: 1
        )

        let crew: Crew = try await supabase
            .from("crews")
            .insert(insert)
            .select(crewSelect)
            .single()
            .execute()
            .value

        // keyword 타입은 crew_keywords에도 등록
        if type == "keyword" {
            struct KeywordInsert: Encodable {
                let crewId: UUID
                let keyword: String
            }
            try? await supabase
                .from("crew_keywords")
                .insert(KeywordInsert(crewId: crew.id, keyword: name.lowercased()))
                .execute()
        }

        // crew_members에 창설자 등록
        struct MemberInsert: Encodable {
            let crewId: UUID
            let userId: UUID
            let isFounder: Bool
            let isActive: Bool
        }
        try await supabase
            .from("crew_members")
            .insert(MemberInsert(crewId: crew.id, userId: userId, isFounder: true, isActive: true))
            .execute()

        // 유저 current_crew_id 업데이트
        struct UserCrewUpdate: Encodable {
            let currentCrewId: UUID
        }
        try? await supabase
            .from("users")
            .update(UserCrewUpdate(currentCrewId: crew.id))
            .eq("id", value: userId.uuidString)
            .execute()

        return crew
    }
}
