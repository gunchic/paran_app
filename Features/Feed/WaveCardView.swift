import SwiftUI

/// 홈 피드 파동 카드 — 풀 너비, No-Line Rule
struct WaveCardView: View {
    let item: WaveFeedItem
    let onCrewTap: ((UUID, String) -> Void)?
    let onHashtagTap: ((String) -> Void)?
    var onResonateTap: (() -> Void)? = nil
    var hideTopComment: Bool = false

    @State private var isResonated: Bool = false
    @State private var resonateCount: Int = 0

    init(
        item: WaveFeedItem,
        onCrewTap: ((UUID, String) -> Void)? = nil,
        onHashtagTap: ((String) -> Void)? = nil,
        onResonateTap: (() -> Void)? = nil,
        hideTopComment: Bool = false
    ) {
        self.item = item
        self.onCrewTap = onCrewTap
        self.onHashtagTap = onHashtagTap
        self.onResonateTap = onResonateTap
        self.hideTopComment = hideTopComment
        _isResonated = State(initialValue: item.isResonated)
        _resonateCount = State(initialValue: item.waveCount)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 이미지 영역
            if let imageUrl = item.displayImageUrl {
                mediaSection(url: imageUrl)
            }

            // 콘텐츠 영역
            VStack(alignment: .leading, spacing: Spacing.sm) {
                authorRow
                bodyText

                // 크루 배지 + 해시태그 가로 스크롤
                if item.crewId != nil || !item.hashtags.isEmpty {
                    badgeRow
                }

                // 나도그래 카운트 텍스트
                if resonateCount > 0 {
                    resonateCountText
                }

                actionBar
            }
            .padding(.horizontal, Spacing.md)
            .padding(.top, Spacing.sm)
            .padding(.bottom, hideTopComment ? Spacing.md : Spacing.xs)

            // 상위 댓글 1개
            if !hideTopComment, let comment = item.topComment {
                topCommentRow(comment)
                    .padding(.horizontal, Spacing.md)
                    .padding(.bottom, Spacing.md)
            }
        }
        .background(Color.surfaceLowest)
        .onAppear {
            isResonated = item.isResonated
            resonateCount = item.waveCount
        }
        .onChange(of: item.isResonated) { newVal in isResonated = newVal }
        .onChange(of: item.waveCount) { newVal in resonateCount = newVal }
    }

    // MARK: - 미디어
    private func mediaSection(url: String) -> some View {
        ZStack(alignment: .center) {
            AsyncImage(url: URL(string: url)) { phase in
                switch phase {
                case .success(let image):
                    image.resizable().scaledToFill()
                case .failure:
                    Color.surfaceContainer
                case .empty:
                    Color.surfaceContainer.overlay(ProgressView().tint(.ash))
                @unknown default:
                    Color.surfaceContainer
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 220)
            .clipped()

            if item.hasYouTube {
                Image(systemName: "play.circle.fill")
                    .font(.system(size: 44))
                    .foregroundColor(.white.opacity(0.9))
                    .shadow(radius: 4)
            }
        }
    }

    // MARK: - 작성자 행
    private var authorRow: some View {
        HStack(spacing: Spacing.sm) {
            AsyncImage(url: URL(string: item.authorProfileImageUrl ?? "")) { phase in
                if case .success(let image) = phase {
                    image.resizable().scaledToFill()
                } else {
                    Circle().fill(Color.surfaceContainer)
                }
            }
            .frame(width: 32, height: 32)
            .clipShape(Circle())

            Text(item.authorNickname ?? "알 수 없음")
                .captionStyle()
                .foregroundColor(.ash)

            Spacer()

            Text(item.createdAt.paramRelative)
                .captionStyle()
                .foregroundColor(.ash)
        }
    }

    // MARK: - 본문
    private var bodyText: some View {
        Text(item.body)
            .bodyStyle()
            .foregroundColor(.void)
            .lineLimit(4)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - 크루 배지 + 해시태그 가로 스크롤
    private var badgeRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Spacing.xs) {
                // 크루 배지 (맨 앞 고정)
                if let crewId = item.crewId, let crewName = item.crewName {
                    Button { onCrewTap?(crewId, crewName) } label: {
                        Text(crewName)
                            .font(.caption.weight(.semibold))
                            .tracking(1)
                            .foregroundColor(.void)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Color.wave400)
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }

                // 해시태그 배지
                ForEach(item.hashtags, id: \.self) { tag in
                    Button { onHashtagTap?(tag) } label: {
                        Text("#\(tag)")
                            .captionStyle()
                            .foregroundColor(.slate)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Color.surfaceContainer)
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - 나도그래 카운트 텍스트
    private var resonateCountText: some View {
        Text("♥ 나만 그런 줄 알았는데 \(resonateCount)명 더")
            .font(.caption.weight(.medium))
            .tracking(1)
            .foregroundColor(.wave400)
    }

    // MARK: - 액션 바
    private var actionBar: some View {
        HStack(spacing: Spacing.md) {
            // 나도그래 버튼
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    isResonated.toggle()
                    resonateCount += isResonated ? 1 : -1
                }
                onResonateTap?()
            } label: {
                Image(systemName: isResonated ? "heart.fill" : "heart")
                    .font(.system(size: 16))
                    .foregroundColor(isResonated ? .wave400 : .ash)
            }
            .buttonStyle(.plain)

            // 댓글 수
            HStack(spacing: 4) {
                Image(systemName: "bubble.left")
                    .font(.system(size: 16))
                    .foregroundColor(.ash)
                if item.commentCount > 0 {
                    Text("\(item.commentCount)")
                        .captionStyle()
                        .foregroundColor(.ash)
                }
            }

            Spacer()
        }
    }

    // MARK: - 상위 댓글 1개
    private func topCommentRow(_ comment: Comment) -> some View {
        HStack(alignment: .top, spacing: Spacing.sm) {
            // 아바타
            AsyncImage(url: URL(string: comment.userAvatarUrl ?? "")) { phase in
                if case .success(let img) = phase {
                    img.resizable().scaledToFill()
                } else {
                    Circle().fill(Color.surfaceContainer)
                }
            }
            .frame(width: 24, height: 24)
            .clipShape(Circle())

            // 닉네임 + 내용
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: Spacing.xs) {
                    Text(comment.userNickname ?? "알 수 없음")
                        .captionStyle()
                        .foregroundColor(.ash)
                    Text(comment.body)
                        .captionStyle()
                        .foregroundColor(.void)
                        .lineLimit(2)
                }
            }

            Spacer()

            // 댓글 이미지 썸네일
            if let imgUrl = comment.imageUrl {
                AsyncImage(url: URL(string: imgUrl)) { phase in
                    if case .success(let img) = phase {
                        img.resizable().scaledToFill()
                    } else {
                        Color.surfaceContainer
                    }
                }
                .frame(width: 40, height: 40)
                .clipped()
                .clipShape(RoundedRectangle(cornerRadius: Radius.xs, style: .continuous))
            }
        }
        .padding(.top, Spacing.xs)
    }
}

// MARK: - Date 상대시간
extension Date {
    var paramRelative: String {
        let diff = Int(Date().timeIntervalSince(self))
        if diff < 60 { return "방금 전" }
        if diff < 3600 { return "\(diff / 60)분 전" }
        if diff < 86400 { return "\(diff / 3600)시간 전" }
        if diff < 604800 { return "\(diff / 86400)일 전" }
        let f = DateFormatter()
        f.dateFormat = "MM.dd"
        return f.string(from: self)
    }
}
