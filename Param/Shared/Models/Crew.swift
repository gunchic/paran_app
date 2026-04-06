import Foundation

struct Crew: Identifiable, Codable, Equatable {
    let id: UUID
    let crewName: String?       // keyword 타입 크루명 (emotion 타입은 nil)
    let emotionWord: String?    // emotion 타입 단어 (keyword 타입은 nil)
    let crewType: String        // "keyword" | "emotion"
    let founderUserId: UUID
    let memberCount: Int
    let isOpen: Bool
    let description: String?
    let colorCode: String?
    let foundedAt: Date
    let cellRow: Int?
    let cellCol: Int?

    /// 화면에 표시할 크루 이름
    var displayName: String {
        crewName ?? emotionWord ?? "이름 없음"
    }
}
