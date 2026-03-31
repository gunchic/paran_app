import SwiftUI
import Combine

// ─────────────────────────────────────────────────────────────
// UserProfileView — 다른 유저 프로필 조회 (읽기 전용 + 팔로우)
// ─────────────────────────────────────────────────────────────
struct UserProfileView: View {
    let userID: String
    let nickname: String           // 로딩 전 표시용 초기값
    let profileImageURL: String?

    @EnvironmentObject var appState: AppState
    @StateObject private var vm = UserProfileViewModel()

    private var isSelf: Bool { userID == appState.currentUserID }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // ── 프로필 헤더 ──────────────────────────
                profileHeader

                Divider().padding(.vertical, 8)

                // ── 파동 목록 ────────────────────────────
                MyMomentsSection(moments: vm.moments, isLoading: vm.isLoading)
            }
        }
        .navigationTitle(vm.user?.nickname ?? nickname)
        .navigationBarTitleDisplayMode(.inline)
        .task { await vm.load(userID: userID, viewerID: appState.currentUserID) }
    }

    // ── 프로필 헤더 ──────────────────────────────────────
    private var profileHeader: some View {
        VStack(spacing: 16) {
            // 프로필 이미지
            avatarView
                .frame(width: 80, height: 80)
                .clipShape(Circle())
                .overlay(Circle().stroke(Color(.systemGray4), lineWidth: 1))

            // 닉네임
            Text(vm.user?.nickname ?? nickname)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.void)

            // 팔로워 / 팔로잉 수 (탭 가능)
            if let stats = vm.stats {
                HStack(spacing: 32) {
                    NavigationLink(destination:
                        FollowersView(userID: userID, title: nickname)
                            .environmentObject(appState)
                    ) {
                        statItem(count: stats.followerCount, label: "팔로워")
                    }
                    .buttonStyle(.plain)

                    NavigationLink(destination:
                        FollowingView(userID: userID)
                            .environmentObject(appState)
                    ) {
                        statItem(count: stats.followingCount, label: "팔로잉")
                    }
                    .buttonStyle(.plain)
                }
            }

            // 팔로우 버튼 (본인 제외)
            if !isSelf {
                FollowButton(
                    targetUserID: userID,
                    isFollowing: $vm.isFollowing
                )
            }
        }
        .padding(.top, 24)
        .padding(.bottom, 16)
        .frame(maxWidth: .infinity)
    }

    private func statItem(count: Int, label: String) -> some View {
        VStack(spacing: 4) {
            Text("\(count)")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.void)
            Text(label)
                .font(.system(size: 12))
                .foregroundColor(.driftwood)
        }
    }

    @ViewBuilder
    private var avatarView: some View {
        let urlStr = vm.user?.profileImageUrl ?? profileImageURL
        if let urlStr, let url = URL(string: urlStr) {
            CachedImage(url: url) { img in
                img.resizable().scaledToFill()
            } placeholder: { avatarPlaceholder }
        } else {
            avatarPlaceholder
        }
    }

    private var avatarPlaceholder: some View {
        ZStack {
            Color.signalRed.opacity(0.12)
            Text(String((vm.user?.nickname ?? nickname).prefix(1)))
                .font(.system(size: 30, weight: .semibold))
                .foregroundColor(.signalRed)
        }
    }
}

// ─────────────────────────────────────────────────────────────
// ViewModel
// ─────────────────────────────────────────────────────────────
@MainActor
private class UserProfileViewModel: ObservableObject {
    @Published var user: User?
    @Published var moments: [Moment] = []
    @Published var stats: FollowStats?
    @Published var isFollowing = false
    @Published var isLoading = false

    func load(userID: String, viewerID: String?) async {
        isLoading = true
        defer { isLoading = false }

        async let fetchedUser: User    = APIClient.shared.get("/users/\(userID)")
        async let fetchedMoments: [Moment] = APIClient.shared.get("/users/\(userID)/moments")
        async let fetchedStats: FollowStats = APIClient.shared.get("/users/\(userID)/follow-stats")

        user    = try? await fetchedUser
        moments = (try? await fetchedMoments) ?? []
        stats   = try? await fetchedStats

        // 팔로우 여부 확인
        if let vid = viewerID, vid != userID {
            let followers: [FollowUser] = (try? await APIClient.shared.get(
                "/users/\(userID)/followers", userID: vid
            )) ?? []
            isFollowing = followers.contains { $0.id == vid }
        }
    }
}
