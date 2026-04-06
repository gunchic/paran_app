import UIKit

/// 이미지 캐시 (메모리 100MB + 디스크 7일)
/// actor로 동시성 안전 보장
actor ImageCache {

    static let shared = ImageCache()

    // MARK: - 메모리 캐시 (NSCache / 100MB / 200장)
    private let memoryCache: NSCache<NSString, UIImage> = {
        let cache = NSCache<NSString, UIImage>()
        cache.totalCostLimit = 100 * 1024 * 1024
        cache.countLimit = 200
        return cache
    }()

    // MARK: - 디스크 캐시 경로
    private let diskCacheURL: URL = {
        let cacheDir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        let dir = cacheDir.appendingPathComponent("ParamImageCache")
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }()

    private init() {}

    // MARK: - 이미지 조회 (메모리 → 디스크 → 네트워크)
    func image(for url: URL) async throws -> UIImage {
        let key = url.absoluteString as NSString

        // 1. 메모리 캐시
        if let cached = memoryCache.object(forKey: key) {
            return cached
        }

        // 2. 디스크 캐시
        if let diskImage = loadFromDisk(key: url.absoluteString) {
            memoryCache.setObject(diskImage, forKey: key)
            return diskImage
        }

        // 3. 네트워크 다운로드
        let (data, _) = try await URLSession.shared.data(from: url)
        guard let image = UIImage(data: data) else {
            throw ParamError.networkError("이미지 로드 실패")
        }

        memoryCache.setObject(image, forKey: key)
        saveToDisk(data: data, key: url.absoluteString)

        return image
    }

    // MARK: - 캐시 전체 삭제
    func clearAll() {
        memoryCache.removeAllObjects()
        let files = try? FileManager.default.contentsOfDirectory(
            at: diskCacheURL,
            includingPropertiesForKeys: nil
        )
        files?.forEach { try? FileManager.default.removeItem(at: $0) }
    }

    // MARK: - 만료된 디스크 캐시만 정리 (7일 초과)
    func clearExpired() {
        let files = try? FileManager.default.contentsOfDirectory(
            at: diskCacheURL,
            includingPropertiesForKeys: [.contentModificationDateKey]
        )
        files?.forEach { url in
            if let attrs = try? url.resourceValues(forKeys: [.contentModificationDateKey]),
               let modDate = attrs.contentModificationDate,
               Date().timeIntervalSince(modDate) > 7 * 24 * 3600 {
                try? FileManager.default.removeItem(at: url)
            }
        }
    }

    // MARK: - 디스크 캐시 사용량
    func diskCacheSize() -> Int {
        let files = try? FileManager.default.contentsOfDirectory(
            at: diskCacheURL,
            includingPropertiesForKeys: [.fileSizeKey]
        )
        return files?.reduce(0) { total, url in
            let size = (try? url.resourceValues(forKeys: [.fileSizeKey]))?.fileSize ?? 0
            return total + size
        } ?? 0
    }

    // MARK: - Private Helpers

    private func saveToDisk(data: Data, key: String) {
        let fileURL = diskCacheURL.appendingPathComponent(cacheFileName(for: key))
        try? data.write(to: fileURL)
    }

    private func loadFromDisk(key: String) -> UIImage? {
        let fileURL = diskCacheURL.appendingPathComponent(cacheFileName(for: key))
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return nil }

        // 7일 만료 체크
        if let attrs = try? FileManager.default.attributesOfItem(atPath: fileURL.path),
           let modDate = attrs[.modificationDate] as? Date,
           Date().timeIntervalSince(modDate) > 7 * 24 * 3600 {
            try? FileManager.default.removeItem(at: fileURL)
            return nil
        }

        guard let data = try? Data(contentsOf: fileURL) else { return nil }
        return UIImage(data: data)
    }

    private func cacheFileName(for key: String) -> String {
        (key.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? key)
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: ":", with: "_")
    }
}
