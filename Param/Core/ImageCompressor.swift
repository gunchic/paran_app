import UIKit

// ─────────────────────────────────────────
// ImageCompressor
// 업로드 전 클라이언트에서 이미지 2단계 압축
//
//  thumbnail  200×200px  JPEG 70%  → 피드 카드
//  image      800×800px  JPEG 80%  → 파동 상세
//
// 비율 유지 (fit, crop 없음) / JPEG 통일
// ─────────────────────────────────────────
struct ImageCompressor {

    struct Result {
        let thumbnail: Data   // 200×200, 70%
        let image: Data       // 800×800, 80%
    }

    /// 비동기 압축 — background 스레드에서 실행
    static func compress(_ image: UIImage) async -> Result? {
        await Task.detached(priority: .userInitiated) {
            guard let thumb = resized(image, maxSide: 200, quality: 0.70),
                  let img   = resized(image, maxSide: 800, quality: 0.80)
            else { return nil }
            return Result(thumbnail: thumb, image: img)
        }.value
    }

    // ── Private ──────────────────────────────────────
    /// fit 방식 리사이즈 (maxSide 기준, 업스케일 없음)
    private static func resized(_ image: UIImage, maxSide: CGFloat, quality: CGFloat) -> Data? {
        let w = image.size.width
        let h = image.size.height
        let ratio = min(maxSide / w, maxSide / h)

        // 원본이 이미 목표보다 작으면 리사이즈 없이 압축만
        let targetSize: CGSize
        if ratio >= 1 {
            targetSize = CGSize(width: w, height: h)
        } else {
            targetSize = CGSize(width: (w * ratio).rounded(), height: (h * ratio).rounded())
        }

        let renderer = UIGraphicsImageRenderer(size: targetSize)
        let out = renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: targetSize))
        }
        return out.jpegData(compressionQuality: quality)
    }
}
