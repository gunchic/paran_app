import SwiftUI

// ─────────────────────────────────────────────────────────────
// MomentCard 탭 영역 정의
//
//  ┌──────────────────────────────────────────┐
//  │  [이미지 / YouTube]                        │ → 상세화면
//  │  [프로필 아바타] [닉네임]                     │ 아바타·닉네임 → 유저 프로필
//  │  [본문 / 위치 / 시간]                        │ → 상세화면
//  ├──────────────────────────────────────────┤
//  │  [#태그 pills]                            │ → 해시태그 피드
//  ├──────────────────────────────────────────┤
//  │  ❤️ n 나도그래  │  💬 n 베스트댓글 텍스트      │ → 상세화면
//  └──────────────────────────────────────────┘
// ─────────────────────────────────────────────────────────────
struct MomentCard: View {
    let moment: Moment
    @EnvironmentObject var appState: AppState
    @ObservedObject private var waveStore       = WaveStore.shared
    @ObservedObject private var commentStore    = CommentStore.shared
    @ObservedObject private var topCommentStore = TopCommentStore.shared

    @State private var goToDetail       = false
    @State private var goToProfile      = false
    @State private var goToHashtagFeed  = false
    @State private var selectedHashtag  = ""

    private let imageHeight: CGFloat = 240
    private let avatarSize: CGFloat  = 52

    var body: some View {
        VStack(spacing: 0) {

            // ── 카드 메인 영역 ─────────────────────────────
            ZStack(alignment: .topLeading) {

                // [전체] 이미지 + 텍스트 → 상세화면
                Button(action: { goToDetail = true }) {
                    VStack(alignment: .leading, spacing: 0) {
                        imageSection
                        textSection
                    }
                    .contentShape(Rectangle())  // 패딩·여백 포함 전체 영역 탭 인식
                }
                .buttonStyle(.plain)

                // [프로필 아바타] → 유저 프로필 (ZStack 최상단 → 탭 우선순위 높음)
                Button(action: { goToProfile = true }) {
                    authorAvatarView
                        .frame(width: avatarSize, height: avatarSize)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.white, lineWidth: 2.5))
                        .shadow(color: .black.opacity(0.15), radius: 4, y: 2)
                }
                .buttonStyle(.plain)
                .offset(x: Spacing.lg, y: imageHeight - avatarSize / 2)
            }

            // ── 해시태그 Pills → 해시태그 피드 ────────────
            if !(moment.tags ?? []).isEmpty {
                tagPillsRow
            }

            // ── 액션 바 → 전부 상세화면 진입 ──────────────
            actionBar
        }
        .background(Color(.systemBackground))
        .cornerRadius(Radius.lg)
        .cardShadow()
        .padding(.horizontal, Spacing.lg)
        .padding(.vertical, Spacing.sm - 2)
        .navigationDestination(isPresented: $goToDetail) {
            MomentDetailView(moment: moment)
                .environmentObject(appState)
        }
        .navigationDestination(isPresented: $goToProfile) {
            UserProfileView(
                userID: moment.userId,
                nickname: moment.authorNickname ?? "",
                profileImageURL: moment.authorProfileImageUrl
            )
            .environmentObject(appState)
        }
        .navigationDestination(isPresented: $goToHashtagFeed) {
            HashtagFeedView(tag: selectedHashtag)
                .environmentObject(appState)
        }
        .task {
            await TopCommentStore.shared.loadIfNeeded(
                momentID: moment.id,
                userID: appState.currentUserID
            )
        }
    }

    // ── 해시태그 Pills ──────────────────────────────────
    private var tagPillsRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Spacing.sm - 2) {
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
            .padding(.horizontal, Spacing.lg)
            .padding(.vertical, Spacing.sm)
        }
        .background(Color(.systemBackground))
        .overlay(alignment: .top) {
            Rectangle()
                .fill(Color(.separator))
                .frame(height: 0.5)
        }
    }

    // ── 액션 바 ──────────────────────────────────────────
    private var actionBar: some View {
        HStack(spacing: 0) {

            // 나도 그래 → 상세화면
            Button(action: { goToDetail = true }) {
                HStack(spacing: Spacing.xs) {
                    Image(systemName: waveStore.hasWaved(moment.id) ? "heart.fill" : "heart")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(waveStore.hasWaved(moment.id) ? .signalRed : .driftwood)
                    if let label = waveVoice(waveStore.count(for: moment.id)) {
                        Text(label)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(waveStore.hasWaved(moment.id) ? .signalRed : .driftwood)
                            .lineLimit(1)
                    }
                }
                .padding(.vertical, 12)
                .padding(.horizontal, Spacing.lg)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Rectangle()
                .fill(Color(.separator))
                .frame(width: 1, height: 18)

            // 댓글 → 상세화면 (count + 베스트 댓글 텍스트)
            Button(action: { goToDetail = true }) {
                HStack(spacing: Spacing.xs) {
                    Image(systemName: "bubble.left")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.driftwood)

                    let count = commentStore.count(for: moment.id)
                    let top   = topCommentStore.topComment(for: moment.id)

                    if count > 0 {
                        Text("\(count)")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.driftwood)
                    }

                    if let body = top?.body, !body.isEmpty {
                        Text(body)
                            .font(.system(size: 12))
                            .foregroundColor(.driftwood)
                            .lineLimit(1)
                    }
                }
                .padding(.vertical, 12)
                .padding(.horizontal, Spacing.lg)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Spacer()
        }
        .background(Color(.systemBackground))
        .overlay(alignment: .top) {
            Rectangle()
                .fill(Color(.separator))
                .frame(height: 0.5)
        }
    }

    // ── 이미지 섹션 ──────────────────────────────────────
    @ViewBuilder
    private var imageSection: some View {
        if let videoId = moment.youtubeVideoId, !videoId.isEmpty {
            YouTubeCard(
                videoId: videoId,
                title: moment.youtubeTitle,
                thumbnail: moment.youtubeThumbnail,
                autoPlay: false
            )
            .frame(maxWidth: .infinity)
            .frame(height: imageHeight)
            .cornerRadius(Radius.lg, corners: [.topLeft, .topRight])
        } else {
            photoImageSection
        }
    }

    // ── 사진 섹션 ────────────────────────────────────────
    private var photoImageSection: some View {
        ZStack(alignment: .bottomLeading) {
            thumbnailView
                .frame(maxWidth: .infinity)
                .frame(height: imageHeight)
                .clipped()

            LinearGradient(
                colors: [.clear, Color.black.opacity(0.62)],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(maxWidth: .infinity)
            .frame(height: imageHeight * 0.45)

            // [닉네임] → 유저 프로필 (이미지 내 텍스트)
            Button(action: { goToProfile = true }) {
                Text(moment.authorNickname ?? "파람")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.5), radius: 3, y: 1)
                    .padding(.leading, Spacing.lg + avatarSize + Spacing.sm)
                    .padding(.bottom, Spacing.xs)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .overlay(alignment: .topLeading) {
            LiveBadge()
                .padding(Spacing.md)
        }
        .cornerRadius(Radius.lg, corners: [.topLeft, .topRight])
    }

    // ── 텍스트 섹션 (본문 + 위치 + 시간) ─────────────────
    private var textSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            if let body = moment.body, !body.isEmpty {
                hashtagBody(body)
                    .font(.system(size: 20, weight: .bold))
                    .lineLimit(3)
                    .lineSpacing(3)
            }

            HStack {
                if moment.latitude != nil {
                    HStack(spacing: Spacing.xs) {
                        Image(systemName: "mappin")
                            .font(.system(size: 11))
                        Text("위치 있음")
                            .font(.paramCaption)
                    }
                    .foregroundColor(.driftwood)
                }
                Spacer()
                Text(moment.createdAt.relativeString)
                    .font(.paramCaption)
                    .foregroundColor(.driftwood)
            }
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.top, avatarSize / 2 + Spacing.md)
        .padding(.bottom, Spacing.lg)
    }

    // ── 본문 해시태그 강조 ────────────────────────────────
    /// #tag 부분만 signalRed 로 색상 적용한 Text 반환
    private func hashtagBody(_ text: String) -> Text {
        var result   = Text("")
        let nsText   = text as NSString
        let length   = nsText.length
        let pattern  = try? NSRegularExpression(pattern: "#[^\\s#]+")
        let matches  = pattern?.matches(in: text, range: NSRange(location: 0, length: length)) ?? []
        var lastEnd  = 0

        for match in matches {
            let r = match.range
            if r.location > lastEnd {
                let plain = nsText.substring(with: NSRange(location: lastEnd, length: r.location - lastEnd))
                result = result + Text(plain).foregroundColor(.void)
            }
            let hashtag = nsText.substring(with: r)
            result = result + Text(hashtag).foregroundColor(.signalRed)
            lastEnd = r.location + r.length
        }
        if lastEnd < length {
            result = result + Text(nsText.substring(from: lastEnd)).foregroundColor(.void)
        }
        return result
    }

    // ── 작성자 아바타 ─────────────────────────────────────
    @ViewBuilder
    private var authorAvatarView: some View {
        if let urlStr = moment.authorProfileImageUrl, let url = URL(string: urlStr) {
            CachedImage(url: url) { img in
                img.resizable().scaledToFill()
            } placeholder: {
                avatarFallback
            }
        } else {
            avatarFallback
        }
    }

    private var avatarFallback: some View {
        ZStack {
            Color.redTint
            Text(String((moment.authorNickname ?? "P").prefix(1)))
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.signalRed)
        }
    }

    // ── 썸네일 ───────────────────────────────────────────
    @ViewBuilder
    private var thumbnailView: some View {
        // 피드 카드에는 썸네일(200×200) 우선, 없으면 압축본 사용
        let feedImageUrl = moment.thumbnailUrl ?? moment.imageUrl
        if let imageUrl = feedImageUrl, let url = resolvedURL(imageUrl) {
            CachedImage(url: url) { image in
                image.resizable().scaledToFill()
            } placeholder: {
                ZStack {
                    Color.whiteWarm
                    ProgressView().tint(.driftwood)
                }
            }
        } else {
            ZStack {
                Color.whiteWarm
                Image(systemName: "photo")
                    .font(.system(size: 36))
                    .foregroundColor(.sand)
            }
        }
    }

    // ── 유틸 ─────────────────────────────────────────────
    private func waveVoice(_ count: Int) -> String? {
        guard count > 0 else { return nil }
        return "\(count) 나도그래"
    }

    private func resolvedURL(_ rawUrl: String) -> URL? {
        guard let url = URL(string: rawUrl),
              let scheme = url.scheme, ["http", "https"].contains(scheme)
        else { return nil }
        if rawUrl.hasPrefix(AppConfig.imageBaseURL) { return url }
        if url.path.hasPrefix("/uploads/") {
            return URL(string: AppConfig.imageBaseURL + url.path)
        }
        return url
    }
}

struct EmptyBody: Encodable {}

extension Date {
    var relativeString: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        return formatter.localizedString(for: self, relativeTo: Date())
    }
}
