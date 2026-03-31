import Foundation

enum YouTubeUtils {

    // MARK: - URL 파싱

    /// YouTube URL에서 videoId 추출
    /// 지원 형식:
    ///   - https://youtu.be/abc123
    ///   - https://www.youtube.com/watch?v=abc123
    ///   - https://www.youtube.com/embed/abc123
    ///   - https://m.youtube.com/watch?v=abc123
    static func extractVideoId(from urlString: String) -> String? {
        guard let url = URL(string: urlString),
              let host = url.host else { return nil }

        // youtu.be/VIDEO_ID
        if host == "youtu.be" {
            let id = url.lastPathComponent
            return id.isEmpty ? nil : id
        }

        guard host.contains("youtube.com") else { return nil }

        // /embed/VIDEO_ID
        let pathComponents = url.pathComponents
        if let embedIdx = pathComponents.firstIndex(of: "embed"),
           embedIdx + 1 < pathComponents.count {
            let id = pathComponents[embedIdx + 1]
            return id.isEmpty ? nil : id
        }

        // ?v=VIDEO_ID
        if let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
           let v = components.queryItems?.first(where: { $0.name == "v" })?.value,
           !v.isEmpty {
            return v
        }

        return nil
    }

    /// YouTube URL 여부 확인
    static func isYouTubeURL(_ urlString: String) -> Bool {
        guard let url = URL(string: urlString),
              let host = url.host else { return false }
        return host.contains("youtube.com") || host == "youtu.be"
    }

    // MARK: - 썸네일

    /// hqdefault 썸네일 URL 반환
    static func thumbnailURL(videoId: String) -> String {
        return "https://img.youtube.com/vi/\(videoId)/hqdefault.jpg"
    }

    // MARK: - 제목

    /// oEmbed API로 영상 제목 가져오기 (API 키 불필요)
    static func fetchTitle(videoId: String) async -> String? {
        let endpoint = "https://www.youtube.com/oembed?url=https://www.youtube.com/watch?v=\(videoId)&format=json"
        guard let url = URL(string: endpoint) else { return nil }
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            return json?["title"] as? String
        } catch {
            return nil
        }
    }
}
