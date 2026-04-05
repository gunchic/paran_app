import Foundation

struct CrewKeyword: Identifiable, Codable {
    let id: UUID
    let keyword: String
    let crewId: UUID
    let createdAt: Date
}
