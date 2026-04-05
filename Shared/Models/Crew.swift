import Foundation

struct Crew: Identifiable, Codable {
    let id: UUID
    let crewName: String      // 선점 단어/문장
    let crewType: String      // "keyword" or "emotion"
    let founderUserId: UUID
    let memberCount: Int
    let isOpen: Bool
    let description: String?
    let colorCode: String?
    let createdAt: Date
}
