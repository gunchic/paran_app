import SwiftUI
import UIKit

// ─────────────────────────────────────────────────────────────
// ImageCache — 메모리 + 디스크 2단계 캐시
// ─────────────────────────────────────────────────────────────

final class ImageCache {
    static let shared = ImageCache()

    // 1. 메모리 캐시 (앱 실행 중 유지, 최대 100MB)
    private let memory = NSCache<NSString, UIImage>()

    // 2. 디스크 캐시 경로
    private let diskURL: URL = {
        let caches = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        let dir = caches.appendingPathComponent("param_images")
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }()

    private init() {
        memory.totalCostLimit = 100 * 1024 * 1024  // 100MB
        memory.countLimit = 200
    }

    // MARK: - 조회

    func get(_ url: URL) -> UIImage? {
        let key = cacheKey(url)

        // 1. 메모리 캐시 확인
        if let img = memory.object(forKey: key as NSString) {
            return img
        }

        // 2. 디스크 캐시 확인
        let filePath = diskURL.appendingPathComponent(key)
        if let data = try? Data(contentsOf: filePath),
           let img = UIImage(data: data) {
            memory.setObject(img, forKey: key as NSString, cost: data.count)
            return img
        }

        return nil
    }

    // MARK: - 저장

    func set(_ image: UIImage, for url: URL) {
        let key = cacheKey(url)
        memory.setObject(image, forKey: key as NSString)

        // 디스크에도 저장 (백그라운드)
        Task.detached(priority: .background) { [weak self] in
            guard let self else { return }
            if let data = image.jpegData(compressionQuality: 0.85) {
                let filePath = self.diskURL.appendingPathComponent(key)
                try? data.write(to: filePath)
            }
        }
    }

    // MARK: - 캐시 초기화

    func clearMemory() {
        memory.removeAllObjects()
    }

    func clearAll() {
        memory.removeAllObjects()
        try? FileManager.default.removeItem(at: diskURL)
        try? FileManager.default.createDirectory(at: diskURL, withIntermediateDirectories: true)
    }

    // MARK: - Private

    private func cacheKey(_ url: URL) -> String {
        // URL을 파일명으로 쓸 수 있게 변환
        url.absoluteString
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: ":", with: "_")
    }
}

// ─────────────────────────────────────────────────────────────
// CachedImage — AsyncImage 대체 컴포넌트
// 사용법: CachedImage(url: url) { image in ... }
// ─────────────────────────────────────────────────────────────

struct CachedImage<Content: View, Placeholder: View>: View {
    let url: URL?
    let content: (Image) -> Content
    let placeholder: () -> Placeholder

    @State private var image: UIImage?
    @State private var isLoading = false

    init(
        url: URL?,
        @ViewBuilder content: @escaping (Image) -> Content,
        @ViewBuilder placeholder: @escaping () -> Placeholder
    ) {
        self.url = url
        self.content = content
        self.placeholder = placeholder
    }

    var body: some View {
        Group {
            if let image {
                content(Image(uiImage: image))
            } else {
                placeholder()
                    .task { await load() }
            }
        }
    }

    @MainActor
    private func load() async {
        guard let url, !isLoading else { return }

        // 캐시 확인 (즉시 반환)
        if let cached = ImageCache.shared.get(url) {
            image = cached
            return
        }

        // 서버에서 다운로드
        isLoading = true
        defer { isLoading = false }

        guard let (data, _) = try? await URLSession.shared.data(from: url),
              let downloaded = UIImage(data: data) else { return }

        ImageCache.shared.set(downloaded, for: url)
        image = downloaded
    }
}
