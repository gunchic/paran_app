import Foundation

// Supabase avatars 테이블 매핑
struct Avatar: Identifiable, Codable {
    let id: UUID
    let name: String
    let imageUrl: String
    let sortOrder: Int
    let isActive: Bool
}
