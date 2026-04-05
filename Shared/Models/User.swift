import Foundation

struct User: Identifiable, Codable {
    let id: UUID
    let authUid: String
    let email: String
    let nickname: String?
    let avatarId: UUID?
    let currentCrewId: UUID?
    let isProfileSet: Bool
    let createdAt: Date
}
