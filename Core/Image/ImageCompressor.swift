import UIKit

/// 이미지 압축 서비스 — 서버 업로드 전 클라이언트 처리
/// 원본은 저장하지 않으며, 썸네일(피드) + 압축본(상세) 두 버전만 생성
enum ImageCompressor {

    // MARK: - 썸네일 생성 (피드 카드용 / 200x200 / 최대 50KB)
    static func makeThumbnail(from image: UIImage) -> Data? {
        let resized = resizeCover(image: normalized(image), targetSize: CGSize(width: 200, height: 200))
        return compressToTarget(image: resized, maxBytes: 50 * 1024)
    }

    // MARK: - 압축본 생성 (상세 화면용 / 800x800 / 최대 400KB)
    static func makeCompressed(from image: UIImage) -> Data? {
        let resized = resizeFit(image: normalized(image), maxSize: CGSize(width: 800, height: 800))
        return compressToTarget(image: resized, maxBytes: 400 * 1024)
    }

    // MARK: - EXIF 방향 정규화
    private static func normalized(_ image: UIImage) -> UIImage {
        guard image.imageOrientation != .up else { return image }
        let renderer = UIGraphicsImageRenderer(size: image.size)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: image.size))
        }
    }

    // MARK: - Cover 리사이즈 (썸네일용) — 짧은 변 기준 크롭
    private static func resizeCover(image: UIImage, targetSize: CGSize) -> UIImage {
        let scale = max(
            targetSize.width / image.size.width,
            targetSize.height / image.size.height
        )
        let scaledSize = CGSize(
            width: image.size.width * scale,
            height: image.size.height * scale
        )
        let origin = CGPoint(
            x: (targetSize.width - scaledSize.width) / 2,
            y: (targetSize.height - scaledSize.height) / 2
        )
        let renderer = UIGraphicsImageRenderer(size: targetSize)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: origin, size: scaledSize))
        }
    }

    // MARK: - Fit 리사이즈 (압축본용) — 긴 변 기준, 업스케일 없음
    private static func resizeFit(image: UIImage, maxSize: CGSize) -> UIImage {
        let scale = min(
            maxSize.width / image.size.width,
            maxSize.height / image.size.height
        )
        guard scale < 1.0 else { return image }
        let newSize = CGSize(
            width: image.size.width * scale,
            height: image.size.height * scale
        )
        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }

    // MARK: - 목표 용량까지 품질 단계적 조절
    private static func compressToTarget(image: UIImage, maxBytes: Int) -> Data? {
        var quality: CGFloat = 0.9
        var data = image.jpegData(compressionQuality: quality)
        while let d = data, d.count > maxBytes, quality > 0.1 {
            quality -= 0.1
            data = image.jpegData(compressionQuality: quality)
        }
        return data
    }

    // MARK: - 파일 크기 포맷 (디버그용)
    static func formatBytes(_ bytes: Int) -> String {
        if bytes < 1024 { return "\(bytes) B" }
        if bytes < 1024 * 1024 { return "\(bytes / 1024) KB" }
        return String(format: "%.1f MB", Double(bytes) / 1024 / 1024)
    }
}
