import SwiftUI

struct UserProfileView: View {
    let user: User

    @State private var waves: [Wave] = []
    @State private var isFollowing: Bool = false

    var body: some View {
        ZStack {
            Color.void.ignoresSafeArea()

            ScrollView {
                VStack(spacing: Spacing.lg) {
                    // 프로필 헤더
                    VStack(spacing: Spacing.sm) {
                        AvatarView(size: 72)

                        Text(user.nickname ?? "익명")
                            .heading2Style()
                            .foregroundColor(.mist)

                        if isFollowing {
                            Button("팔로잉") {
                                isFollowing.toggle()
                                // TODO: 팔로우 API
                            }
                            .buttonStyle(.paramOutline)
                        } else {
                            Button("팔로우") {
                                isFollowing.toggle()
                                // TODO: 팔로우 API
                            }
                            .buttonStyle(.paramPrimary)
                        }
                    }
                    .padding(.top, Spacing.md)

                    Divider().background(Color.surface)

                    // 파람 목록
                    LazyVStack(spacing: Spacing.sm) {
                        ForEach(waves) { wave in
                            WaveCardView(wave: wave)
                        }
                    }
                    .padding(.horizontal, Spacing.md)
                }
            }
        }
        .navigationTitle(user.nickname ?? "프로필")
        .navigationBarTitleDisplayMode(.inline)
    }
}
