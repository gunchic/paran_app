import SwiftUI

/// YouTube 파동 카드 플레이어
/// - 기본 상태: 썸네일 + 중앙 재생 버튼 (Signal Red)
/// - 재생 시: YouTubePlayerView 인라인 표시
/// - embed 비허용 영상: 오류 감지 → YouTube 앱/Safari 열기 폴백
struct YouTubeCard: View {
    let videoId: String
    var title: String?
    var thumbnail: String?
    var autoPlay: Bool = false

    @State private var isPlaying: Bool
    @State private var embedFailed = false

    init(videoId: String, title: String? = nil, thumbnail: String? = nil, autoPlay: Bool = false) {
        self.videoId   = videoId
        self.title     = title
        self.thumbnail = thumbnail
        self.autoPlay  = autoPlay
        _isPlaying     = State(initialValue: autoPlay)
    }

    private let playerHeight: CGFloat = 200

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {

            // ── 플레이어 / 썸네일 ─────────────────────
            ZStack {
                if isPlaying && !embedFailed {
                    YouTubePlayerView(videoId: videoId) {
                        // embed 로드 실패 → 폴백 UI로 전환
                        embedFailed = true
                        isPlaying   = false
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: playerHeight)
                } else if embedFailed {
                    embedBlockedView
                } else {
                    thumbnailSection
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: playerHeight)
            .background(Color.black)
            .clipped()

            // ── 하단 바 (제목 + YouTube 앱 열기) ──────
            HStack(spacing: 0) {
                // 영상 제목
                if let title, !title.isEmpty {
                    Text(title)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.white)
                        .lineLimit(1)
                } else {
                    HStack(spacing: 5) {
                        Image(systemName: "play.rectangle.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.signalRed)
                        Text("YouTube")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.white.opacity(0.7))
                    }
                }

                Spacer()

                // YouTube 앱에서 보기 버튼
                Button(action: openInYouTube) {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.up.right.square")
                            .font(.system(size: 11))
                        Text("앱에서 보기")
                            .font(.system(size: 11))
                    }
                    .foregroundColor(.white.opacity(0.5))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(Color.black.opacity(0.85))
        }
        .background(Color.black)
        .cornerRadius(Radius.md)
        .clipped()
    }

    // MARK: - embed 차단 폴백 UI

    private var embedBlockedView: some View {
        ZStack {
            // 썸네일 블러 배경
            let thumbURL = thumbnail.flatMap(URL.init) ?? URL(string: YouTubeUtils.thumbnailURL(videoId: videoId))
            AsyncImage(url: thumbURL) { phase in
                if let img = phase.image { img.resizable().scaledToFill() }
                else { Color.black }
            }
            .frame(maxWidth: .infinity)
            .frame(height: playerHeight)
            .clipped()
            .blur(radius: 4)

            Color.black.opacity(0.6)

            // 안내 메시지 + YouTube 버튼
            VStack(spacing: 12) {
                Image(systemName: "play.slash.fill")
                    .font(.system(size: 28))
                    .foregroundColor(.white.opacity(0.7))
                Text("이 영상은 앱 내 재생이 제한되어 있어요")
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                Button(action: openInYouTube) {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.up.right.square.fill")
                            .font(.system(size: 14))
                        Text("YouTube에서 보기")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 9)
                    .background(Color.signalRed)
                    .cornerRadius(Radius.full)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 20)
        }
    }

    // MARK: - 썸네일

    private var thumbnailSection: some View {
        ZStack {
            let thumbURL = thumbnail.flatMap(URL.init) ?? URL(string: YouTubeUtils.thumbnailURL(videoId: videoId))
            AsyncImage(url: thumbURL) { phase in
                switch phase {
                case .success(let image):
                    image.resizable().scaledToFill()
                case .failure:
                    Color.black
                default:
                    ZStack { Color.black; ProgressView().tint(.white) }
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: playerHeight)
            .clipped()

            Color.black.opacity(0.25)

            Button(action: { isPlaying = true }) {
                ZStack {
                    Circle()
                        .fill(Color.signalRed)
                        .frame(width: 48, height: 48)
                        .shadow(color: .black.opacity(0.4), radius: 8, y: 2)
                    Image(systemName: "play.fill")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                        .offset(x: 2)
                }
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - YouTube 앱 열기

    private func openInYouTube() {
        let appURL     = URL(string: "youtube://www.youtube.com/watch?v=\(videoId)")!
        let webURL     = URL(string: "https://www.youtube.com/watch?v=\(videoId)")!
        let openTarget = UIApplication.shared.canOpenURL(appURL) ? appURL : webURL
        UIApplication.shared.open(openTarget)
    }
}
