import Foundation

struct Wave: Identifiable, Codable {
    let id: UUID
    let userId: UUID
    let text: String
    let thumbnailUrl: String?
    let imageUrl: String?
    let imageOffsetY: Double?
    let youtubeVideoId: String?
    let crewId: UUID?
    let createdAt: Date
}
