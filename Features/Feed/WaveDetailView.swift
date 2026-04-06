import SwiftUI

/// 파동 상세 화면 — 나도그래 기능 포함
struct WaveDetailView: View {
    let item: WaveFeedItem

    @State private var isResonated: Bool = false
    @State private var resonateCount: Int = 0

    var body: some View {
        ZStack {
            Color.paper.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.lg) {
                    // 작성자
                    authorSection

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

                    // 액션 바
                    actionBar
                }
                .padding(Spacing.md)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { resonateCount = item.waveCount }
        .task { await loadResonateState() }
    }

    // MARK: - 작성자 영역
    private var authorSection: some View {
        HStack(spacing: Spacing.sm) {
            AsyncImage(url: URL(string: item.authorProfileImageUrl ?? "")) { phase in
                if case .success(let image) = phase {
                    image.resizable().scaledToFill()
                } else {
                    Circle().fill(Color.surfaceContainer)
                }
            }
            .frame(width: 40, height: 40)
            .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(item.authorNickname ?? "알 수 없음")
                    .font(.paramBody.weight(.semibold))
                    .foregroundColor(.void)
                Text(item.createdAt.paramRelative)
                    .captionStyle()
                    .foregroundColor(.ash)
            }
        }
    }

    // MARK: - 액션 바
    private var actionBar: some View {
        HStack(spacing: Spacing.lg) {
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    isResonated.toggle()
                    resonateCount += isResonated ? 1 : -1
                }
                Task { await performToggle() }
            } label: {
                HStack(spacing: Spacing.xs) {
                    Image(systemName: isResonated ? "heart.fill" : "heart")
                        .font(.system(size: 18))
                        .foregroundColor(isResonated ? .wave400 : .ash)
                    Text("\(resonateCount)")
                        .bodyStyle()
                        .foregroundColor(isResonated ? .wave400 : .ash)
                }
            }
            .buttonStyle(.plain)

            HStack(spacing: Spacing.xs) {
                Image(systemName: "bubble.left")
                    .font(.system(size: 18))
                    .foregroundColor(.ash)
                Text("\(item.commentCount)")
                    .bodyStyle()
                    .foregroundColor(.ash)
            }

            Spacer()
        }
    }

    private func loadResonateState() async {
        guard let userId = try? await SupabaseManager.shared.client.auth.session.user.id else { return }
        do {
            isResonated = try await WaveService.shared.isResonated(momentId: item.id, userId: userId)
        } catch { /* 조용히 처리 */ }
    }

    private func performToggle() async {
        guard let userId = try? await SupabaseManager.shared.client.auth.session.user.id else { return }
        do {
            _ = try await WaveService.shared.toggleResonate(momentId: item.id, userId: userId)
        } catch {
            // 실패 시 롤백
            await MainActor.run {
                isResonated.toggle()
                resonateCount += isResonated ? 1 : -1
            }
        }
    }
}
