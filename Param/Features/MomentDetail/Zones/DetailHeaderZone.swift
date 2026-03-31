import SwiftUI

// ─────────────────────────────────────────
// ZONE 1 — 원본 파동 (이미지 + 글 + 태그)
// ─────────────────────────────────────────
struct DetailHeaderZone: View {
    let moment: Moment

    @EnvironmentObject var appState: AppState
    @State private var selectedHashtag = ""
    @State private var goToHashtagFeed = false

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {

            // YouTube 콘텐츠 — contentType 또는 youtubeVideoId 존재 시 표시
            if let videoId = moment.youtubeVideoId, !videoId.isEmpty {
                YouTubeCard(
                    videoId: videoId,
                    title: moment.youtubeTitle,
                    thumbnail: moment.youtubeThumbnail,
                    autoPlay: false
                )
                .padding(.horizontal, 16)
                .padding(.top, 8)
            }
            // 일반 이미지 (YouTube가 아닐 때만)
            else if let imageUrl = moment.imageUrl, let url = URL(string: imageUrl) {
                TappableImage(url: url)
                    .frame(maxWidth: .infinity)
                    .frame(height: 280)
                    .clipped()
            }

            VStack(alignment: .leading, spacing: 10) {

                // 본문 — #태그 signalRed 강조
                if let body = moment.body, !body.isEmpty {
                    hashtagBody(body)
                        .font(.system(size: 17, weight: .regular))
                        .lineSpacing(4)
                }

                // 태그 Pills — 탭 시 해시태그 피드
                if !(moment.tags ?? []).isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            ForEach(moment.tags ?? [], id: \.self) { tag in
                                Button(action: {
                                    selectedHashtag = tag
                                    goToHashtagFeed = true
                                }) {
                                    TagPill(text: tag)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }

                // 시간
                Text(moment.createdAt.relativeString)
                    .font(.system(size: 12))
                    .foregroundColor(Color(.systemGray3))
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 8)
        }
        .background(Color.warmPaper)
        .navigationDestination(isPresented: $goToHashtagFeed) {
            HashtagFeedView(tag: selectedHashtag)
                .environmentObject(appState)
        }
    }

    // ── 본문 해시태그 강조 ─────────────────────────────
    private func hashtagBody(_ text: String) -> Text {
        var result  = Text("")
        let nsText  = text as NSString
        let length  = nsText.length
        let pattern = try? NSRegularExpression(pattern: "#[^\\s#]+")
        let matches = pattern?.matches(in: text, range: NSRange(location: 0, length: length)) ?? []
        var lastEnd = 0

        for match in matches {
            let r = match.range
            if r.location > lastEnd {
                let plain = nsText.substring(with: NSRange(location: lastEnd, length: r.location - lastEnd))
                result = result + Text(plain).foregroundColor(.primary)
            }
            let hashtag = nsText.substring(with: r)
            result = result + Text(hashtag).foregroundColor(.signalRed)
            lastEnd = r.location + r.length
        }
        if lastEnd < length {
            result = result + Text(nsText.substring(from: lastEnd)).foregroundColor(.primary)
        }
        return result
    }
}
