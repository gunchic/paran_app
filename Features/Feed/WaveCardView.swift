import SwiftUI

/// 홈 피드 파동 카드 — 풀 너비, No-Line Rule
struct WaveCardView: View {
    let item: WaveFeedItem
    let onCrewTap: ((UUID, String) -> Void)?
    var onResonateTap: (() -> Void)? = nil

    @State private var isResonated: Bool = false

    init(item: WaveFeedItem, onCrewTap: ((UUID, String) -> Void)? = nil, onResonateTap: (() -> Void)? = nil) {
        self.item = item
        self.onCrewTap = onCrewTap
        self.onResonateTap = onResonateTap
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 이미지 영역 (풀 너비)
            if let imageUrl = item.displayImageUrl {
                mediaSection(url: imageUrl)
            }

            // 콘텐츠 영역
            VStack(alignment: .leading, spacing: Spacing.sm) {
                authorRow
                bodyText
                if let crewId = item.crewId, let crewName = item.crewName {
                    crewBadge(id: crewId, name: crewName)
                }
                actionBar
            }
            .padding(.horizontal, Spacing.md)
            .padding(.top, Spacing.sm)
            .padding(.bottom, Spacing.md)
        }
        .background(Color.surfaceLowest)
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
                    Color.surfaceContainer
                        .overlay(ProgressView().tint(.ash))
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

    // MARK: - 작성자
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

    // MARK: - 크루 배지
    private func crewBadge(id: UUID, name: String) -> some View {
        Button {
            onCrewTap?(id, name)
        } label: {
            Text(name)
                .captionStyle()
                .foregroundColor(.wave600)
                .padding(.horizontal, Spacing.sm)
                .padding(.vertical, Spacing.xs)
                .background(Color.wave400.opacity(0.12))
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    // MARK: - 액션 바
    private var actionBar: some View {
        HStack(spacing: Spacing.md) {
            // 나도그래
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    isResonated.toggle()
                }
                onResonateTap?()
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: isResonated ? "heart.fill" : "heart")
                        .font(.system(size: 15))
                        .foregroundColor(isResonated ? .wave400 : .ash)
                    Text("\(item.waveCount + (isResonated ? 1 : 0))")
                        .captionStyle()
                        .foregroundColor(isResonated ? .wave400 : .ash)
                }
            }
            .buttonStyle(.plain)

            // 댓글
            HStack(spacing: 4) {
                Image(systemName: "bubble.left")
                    .font(.system(size: 15))
                    .foregroundColor(.ash)
                Text("\(item.commentCount)")
                    .captionStyle()
                    .foregroundColor(.ash)
            }

            Spacer()
        }
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
