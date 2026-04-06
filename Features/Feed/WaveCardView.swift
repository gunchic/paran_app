import SwiftUI

/// 홈 피드 파동 카드 컴포넌트
struct WaveCardView: View {
    let item: WaveFeedItem
    let onCrewTap: ((UUID, String) -> Void)?

    init(item: WaveFeedItem, onCrewTap: ((UUID, String) -> Void)? = nil) {
        self.item = item
        self.onCrewTap = onCrewTap
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 이미지 영역
            if let imageUrl = item.displayImageUrl {
                mediaSection(url: imageUrl)
            }

            VStack(alignment: .leading, spacing: Spacing.sm) {
                // 유저 정보
                authorRow

                // 파동 텍스트
                Text(item.body)
                    .bodyStyle()
                    .foregroundColor(.void)
                    .lineLimit(3)
                    .frame(maxWidth: .infinity, alignment: .leading)

                // 크루 배지
                if let crewId = item.crewId, let crewName = item.crewName {
                    crewBadge(id: crewId, name: crewName)
                }

                // 액션 바
                actionBar
            }
            .padding(Spacing.md)
        }
        .background(Color.surfaceLowest)
        .clipShape(RoundedRectangle(cornerRadius: Radius.md, style: .continuous))
        .shadow(color: Color.void.opacity(0.06), radius: 8, x: 0, y: 2)
    }

    // MARK: - 미디어 섹션
    private func mediaSection(url: String) -> some View {
        ZStack(alignment: .center) {
            AsyncImage(url: URL(string: url)) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
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
            .frame(height: 200)
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
        HStack(spacing: Spacing.xs) {
            // 아바타
            AsyncImage(url: URL(string: item.authorProfileImageUrl ?? "")) { phase in
                if case .success(let image) = phase {
                    image.resizable().scaledToFill()
                } else {
                    Circle().fill(Color.surfaceContainer)
                }
            }
            .frame(width: 32, height: 32)
            .clipShape(Circle())

            // 닉네임
            Text(item.authorNickname ?? "알 수 없음")
                .captionStyle()
                .foregroundColor(.ash)

            Spacer()

            // 작성 시간
            Text(item.createdAt.relativeString)
                .captionStyle()
                .foregroundColor(.ash)
        }
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
                .background(Color.wave400.opacity(0.1))
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    // MARK: - 액션 바
    private var actionBar: some View {
        HStack(spacing: Spacing.md) {
            // 나도그래 (비활성 상태 - 추후 구현)
            HStack(spacing: 4) {
                Image(systemName: "heart")
                    .font(.system(size: 14))
                    .foregroundColor(.ash)
                Text("\(item.waveCount)")
                    .captionStyle()
                    .foregroundColor(.ash)
            }

            // 댓글
            HStack(spacing: 4) {
                Image(systemName: "bubble.left")
                    .font(.system(size: 14))
                    .foregroundColor(.ash)
                Text("\(item.commentCount)")
                    .captionStyle()
                    .foregroundColor(.ash)
            }

            Spacer()
        }
    }
}

// MARK: - Date 상대시간 Extension
private extension Date {
    var relativeString: String {
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
