import SwiftUI

enum FollowTab: String, CaseIterable {
    case followers = "팔로워"
    case following = "팔로잉"
}

struct FollowListView: View {
    let userId: UUID
    @State private var selectedTab: FollowTab = .followers
    @State private var users: [User] = []

    var body: some View {
        ZStack {
            Color.void.ignoresSafeArea()

            VStack(spacing: 0) {
                Picker("", selection: $selectedTab) {
                    ForEach(FollowTab.allCases, id: \.self) { tab in
                        Text(tab.rawValue).tag(tab)
                    }
                }
                .pickerStyle(.segmented)
                .padding(Spacing.md)

                ScrollView {
                    LazyVStack(spacing: Spacing.sm) {
                        ForEach(users) { user in
                            NavigationLink(destination: UserProfileView(user: user)) {
                                userRow(user)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, Spacing.md)
                }
            }
        }
        .navigationTitle(selectedTab.rawValue)
        .navigationBarTitleDisplayMode(.inline)
    }

    private func userRow(_ user: User) -> some View {
        HStack(spacing: Spacing.md) {
            AvatarView(size: 40)

            Text(user.nickname ?? "익명")
                .bodyStyle()
                .foregroundColor(.mist)

            Spacer()
        }
        .padding(.vertical, Spacing.xs)
    }
}
