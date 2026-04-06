import SwiftUI

/// 파동 상세 화면 — 추후 댓글/리액션 기능 추가 예정
struct WaveDetailView: View {
    let item: WaveFeedItem

    var body: some View {
        ZStack {
            Color.paper.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.lg) {
                    // 작성자
                    HStack(spacing: Spacing.xs) {
                        AsyncImage(url: URL(string: item.authorProfileImageUrl ?? "")) { phase in
                            if case .success(let image) = phase {
                                image.resizable().scaledToFill()
                            } else {
                                Circle().fill(Color.surfaceContainer)
                            }
                        }
                        .frame(width: 36, height: 36)
                        .clipShape(Circle())

                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.authorNickname ?? "알 수 없음")
                                .font(.paramBody.weight(.semibold))
                                .foregroundColor(.void)
                            Text(item.createdAt, style: .relative)
                                .captionStyle()
                                .foregroundColor(.ash)
                        }
                    }

                    // 이미지
                    if let imageUrl = item.displayImageUrl {
                        AsyncImage(url: URL(string: imageUrl)) { phase in
                            if case .success(let image) = phase {
                                image.resizable().scaledToFill()
                            } else {
                                Color.surfaceContainer
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 260)
                        .clipped()
                        .clipShape(RoundedRectangle(cornerRadius: Radius.md, style: .continuous))
                    }

                    // 본문
                    Text(item.body)
                        .bodyStyle()
                        .foregroundColor(.void)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    // 액션
                    HStack(spacing: Spacing.md) {
                        Label("\(item.waveCount)", systemImage: "heart")
                            .captionStyle()
                            .foregroundColor(.ash)
                        Label("\(item.commentCount)", systemImage: "bubble.left")
                            .captionStyle()
                            .foregroundColor(.ash)
                    }
                }
                .padding(Spacing.md)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}
