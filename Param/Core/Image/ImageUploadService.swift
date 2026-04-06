import Foundation
import UIKit

/// Supabase Storage 이미지 업로드 서비스
/// 압축은 ImageCompressor에 위임, URL 반환 담당
/// 버킷: "moments" (기존 운영 버킷 — waves/comments 버킷 생성 후 경로 분리 가능)
final class ImageUploadService {

    static let shared = ImageUploadService()
    private let storage = SupabaseManager.shared.client.storage
    private let bucket = "moments"
    private init() {}

    // MARK: - 파동 이미지 업로드 (썸네일 + 압축본 동시)
    func uploadWaveImage(
        originalImage: UIImage,
        waveId: UUID
    ) async throws -> (thumbnailUrl: String, imageUrl: String) {

        guard
            let thumbnailData = ImageCompressor.makeThumbnail(from: originalImage),
            let compressedData = ImageCompressor.makeCompressed(from: originalImage)
        else {
            throw ParamError.uploadFailed
        }

        let thumbnailPath = "thumbnails/\(waveId.uuidString).jpg"
        let compressedPath = "compressed/\(waveId.uuidString).jpg"

        // 동시 업로드
        async let thumbnailUpload = upload(path: thumbnailPath, data: thumbnailData)
        async let compressedUpload = upload(path: compressedPath, data: compressedData)

        let (thumbnailUrl, imageUrl) = try await (thumbnailUpload, compressedUpload)
        return (thumbnailUrl, imageUrl)
    }

    // MARK: - 댓글 이미지 업로드
    func uploadCommentImage(
        originalImage: UIImage,
        commentId: UUID
    ) async throws -> String {
        guard let data = ImageCompressor.makeCompressed(from: originalImage) else {
            throw ParamError.uploadFailed
        }
        return try await upload(path: "comments/\(commentId.uuidString).jpg", data: data)
    }

    // MARK: - 파동 이미지 삭제
    func deleteWaveImages(waveId: UUID) async throws {
        let paths = [
            "thumbnails/\(waveId.uuidString).jpg",
            "compressed/\(waveId.uuidString).jpg"
        ]
        try await storage.from(bucket).remove(paths: paths)
    }

    // MARK: - 공통 업로드 + Public URL 반환
    private func upload(path: String, data: Data) async throws -> String {
        try await storage
            .from(bucket)
            .upload(path, data: data, options: .init(contentType: "image/jpeg", upsert: true))

        let publicUrl = try storage.from(bucket).getPublicURL(path: path)
        return publicUrl.absoluteString
    }
}
