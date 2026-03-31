import SwiftUI

// ─────────────────────────────────────────
// WaveCard — 피드 파동 카드 (디자인 시스템 적용 버전)
// MomentCard의 공통 컴포넌트 분리본
// 기능 로직은 MomentCard와 동일, 토큰만 적용
// ─────────────────────────────────────────
struct WaveCard: View {
    let moment: Moment
    @EnvironmentObject var appState: AppState
    @ObservedObject private var waveStore = WaveStore.shared

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {

            // ── 작성자 행 ─────────────────────────────
            NavigationLink(destination:
                UserProfileView(
                    userID: moment.userId,
                    nickname: moment.authorNickname ?? "",
                    profileImageURL: moment.authorProfileImageUrl
                ).environmentObject(appState)
            ) {
                HStack(spacing: Spacing.sm) {
                    ParamAvatar(
                        url: moment.authorProfileImageUrl,
                        fallbackLetter: moment.authorNickname ?? "P",
                        size: .sm
                    )
                    Text(moment.authorNickname ?? "파람")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.void)
                    Spacer()
                    Text(moment.createdAt.relativeString)
                        .font(.paramCaption)
                        .foregroundColor(.driftwood)
                }
            }
            .buttonStyle(.plain)

            // ── 콘텐츠 행 ────────────────────────────
            HStack(alignment: .top, spacing: Spacing.md) {

                // 왼쪽 썸네일
                thumbnailView
                    .frame(width: 80, height: 80)
                    .cornerRadius(Radius.md)
                    .clipped()

                // 오른쪽 콘텐츠
                VStack(alignment: .leading, spacing: Spacing.sm - 2) {
                    if let body = moment.body, !body.isEmpty {
                        Text(body)
                            .font(.paramBody)
                            .foregroundColor(.void)
                            .lineLimit(2)
                    }

                    if !(moment.tags ?? []).isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: Spacing.sm - 2) {
                                ForEach(moment.tags ?? [], id: \.self) { tag in
                                    TagPill(text: tag)
                                }
                            }
                        }
                    }

                    Spacer(minLength: 0)

                    // 파동 버튼
                    HStack {
                        Spacer()
                        Button(action: sendWave) {
                            HStack(spacing: Spacing.xs) {
                                Image(systemName: "water.waves")
                                    .font(.system(size: 12))
                                    .foregroundColor(waveStore.hasWaved(moment.id) ? .signalRed : .driftwood)
                                Text(waveStore.hasWaved(moment.id) ? "파동 중" : "나도 그래")
                                    .font(.paramLabel)
                                    .foregroundColor(waveStore.hasWaved(moment.id) ? .signalRed : .driftwood)
                                let count = waveStore.count(for: moment.id)
                                if count > 0 {
                                    Text("\(count)")
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundColor(waveStore.hasWaved(moment.id) ? .signalRed : .driftwood)
                                }
                            }
                            .padding(.horizontal, Spacing.sm + 2)
                            .padding(.vertical, Spacing.xs + 1)
                            .background(waveStore.hasWaved(moment.id) ? Color.redTint : Color(.systemGray6))
                            .cornerRadius(Radius.full)
                            .animation(.spring(response: 0.3), value: waveStore.hasWaved(moment.id))
                        }
                        .disabled(waveStore.hasWaved(moment.id))
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(Spacing.sm + Spacing.xs)
        .background(Color(.systemBackground))
        .cornerRadius(Radius.lg)
        .cardShadow()
        .padding(.horizontal, Spacing.lg)
        .padding(.vertical, Spacing.xs + 1)
    }

    @ViewBuilder
    private var thumbnailView: some View {
        if let imageUrl = moment.imageUrl, let url = resolvedURL(imageUrl) {
            CachedImage(url: url) { image in
                image.resizable().scaledToFill()
            } placeholder: {
                ZStack {
                    Color(.systemGray6)
                    ProgressView().scaleEffect(0.7)
                }
            }
        } else {
            placeholderView
        }
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

    private var placeholderView: some View {
        ZStack {
            Color(.systemGray6)
            Image(systemName: "photo")
                .font(.system(size: 22))
                .foregroundColor(.driftwood)
        }
    }

    func sendWave() {
        guard let userID = appState.currentUserID else { return }
        withAnimation(.spring(response: 0.3)) {
            waveStore.recordWave(momentID: moment.id)
        }
        Task {
            let _: Wave? = try? await APIClient.shared.post(
                "/moments/\(moment.id)/wave",
                body: EmptyBody(),
                userID: userID
            )
        }
    }
}
