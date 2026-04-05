import SwiftUI

struct MyPageView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        NavigationStack {
            ZStack {
                Color.paper.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: Spacing.lg) {
                        // 프로필 섹션
                        VStack(spacing: Spacing.sm) {
                            AvatarView(size: 80)

                            Text(appState.currentUser?.nickname ?? "닉네임 없음")
                                .heading2Style()
                                .foregroundColor(.void)

                            Text(appState.currentUser?.email ?? "")
                                .captionStyle()
                                .foregroundColor(.ash)
                        }
                        .padding(.top, Spacing.md)

                        Divider().background(Color.stone)

                        // 메뉴
                        VStack(spacing: Spacing.xs) {
                            NavigationLink(destination: MyCrewListView()) {
                                menuRow(icon: "person.3", title: "내 크루")
                            }

                            NavigationLink(destination: FollowListView(userId: appState.currentUser?.id ?? UUID())) {
                                menuRow(icon: "person.2", title: "팔로우")
                            }

                            NavigationLink(destination: NotificationView()) {
                                menuRow(icon: "bell", title: "알림")
                            }
                        }
                        .padding(.horizontal, Spacing.md)
                    }
                }
            }
            .navigationTitle("나")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func menuRow(icon: String, title: String) -> some View {
        HStack(spacing: Spacing.md) {
            Image(systemName: icon)
                .foregroundColor(.wave400)
                .frame(width: 24)

            Text(title)
                .bodyStyle()
                .foregroundColor(.void)

            Spacer()

            Image(systemName: "chevron.right")
                .foregroundColor(.slate)
                .captionStyle()
        }
        .padding(Spacing.md)
        .background(Color.surfaceLowest)
        .clipShape(RoundedRectangle(cornerRadius: Radius.md, style: .continuous))
    }
}
