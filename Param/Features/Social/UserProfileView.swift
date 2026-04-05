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

                        Button(isFollowing ? "팔로잉" : "팔로우") {
                            isFollowing.toggle()
                            // TODO: 팔로우 API
                        }
                        .buttonStyle(isFollowing ? .outline : .primary)
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
