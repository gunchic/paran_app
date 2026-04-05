import Foundation

// Supabase users 테이블 매핑
// id = auth.uid() (Supabase 표준 패턴)
struct User: Identifiable, Codable, Equatable {
    let id: UUID
    let email: String?
    let nickname: String?
    let avatarId: UUID?
    let currentCrewId: UUID?
    let isProfileSet: Bool
    let createdAt: Date?

    static func == (lhs: User, rhs: User) -> Bool {
        lhs.id == rhs.id
    }
}

// INSERT 시 사용 (created_at은 DB default)
struct UserInsert: Encodable {
    let id: UUID
    let email: String?
    let isProfileSet: Bool = false
}

// UPDATE 시 사용
struct UserProfileUpdate: Encodable {
    let nickname: String
    let avatarId: UUID?
    let isProfileSet: Bool = true
}
