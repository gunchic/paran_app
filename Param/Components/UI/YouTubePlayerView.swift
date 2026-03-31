import SwiftUI
import WebKit

/// WKWebView 기반 YouTube 인라인 플레이어
///
/// 오류 150/152 해결:
///   - youtube-nocookie.com 도메인 사용 (embed 제한 완화)
///   - iframe referrerpolicy="origin" 으로 Referer 헤더 강제 설정
///   - HTML injection + baseURL = youtube-nocookie.com (origin 검증 통과)
///   - playsinline=1 강제 (인라인 재생)
///   - 광고는 YouTube 정책상 표시될 수 있음
struct YouTubePlayerView: UIViewRepresentable {
    let videoId: String
    var onError: (() -> Void)?

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.scrollView.isScrollEnabled = false
        webView.scrollView.bounces = false
        webView.backgroundColor = .black
        webView.isOpaque = true
        webView.navigationDelegate = context.coordinator

        // Safari UA — YouTube WebView 감지 우회
        webView.customUserAgent = "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1"

        // baseURL = youtube-nocookie.com → origin 검증 통과
        webView.loadHTMLString(
            buildHTML(videoId: videoId),
            baseURL: URL(string: "https://www.youtube-nocookie.com")
        )
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onError: onError)
    }

    // MARK: - HTML

    private func buildHTML(videoId: String) -> String {
        return """
        <!DOCTYPE html>
        <html>
        <head>
          <meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1">
          <style>
            * { margin: 0; padding: 0; box-sizing: border-box; }
            html, body { width: 100%; height: 100%; background: #000; }
            iframe { width: 100%; height: 100%; border: none; display: block; }
          </style>
        </head>
        <body>
          <iframe
            src="https://www.youtube-nocookie.com/embed/\(videoId)?autoplay=1&playsinline=1&rel=0&modestbranding=1&enablejsapi=1"
            allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture"
            referrerpolicy="origin"
            allowfullscreen>
          </iframe>
        </body>
        </html>
        """
    }

    // MARK: - Coordinator

    class Coordinator: NSObject, WKNavigationDelegate {
        let onError: (() -> Void)?
        init(onError: (() -> Void)?) { self.onError = onError }

        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            onError?()
        }
        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            onError?()
        }
    }
}
