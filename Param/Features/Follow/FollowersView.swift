import SwiftUI
import Combine

// ─────────────────────────────────────────
// FollowersView — 팔로워 목록
// ─────────────────────────────────────────
struct FollowersView: View {
    let userID: String
    let title: String  // "팔로워" or 닉네임 기반

    @EnvironmentObject var appState: AppState
    @StateObject private var vm = FollowListViewModel()

    var body: some View {
        Group {
            if vm.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if vm.users.isEmpty {
                emptyState
            } else {
                List(vm.users) { user in
                    FollowUserRow(user: user, viewerID: appState.currentUserID)
                        .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
                        .listRowSeparator(.hidden)
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle("팔로워 \(vm.users.count)명")
        .navigationBarTitleDisplayMode(.inline)
        .task { await vm.loadFollowers(userID: userID, viewerID: appState.currentUserID) }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "person.2")
                .font(.system(size: 44))
                .foregroundColor(.driftwood)
            Text("아직 팔로워가 없어요")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.void)
            Text("파동을 보내면 파람들이 찾아올 거예요")
                .font(.system(size: 14))
                .foregroundColor(.driftwood)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// ─────────────────────────────────────────
// FollowingView — 팔로잉 목록
// ─────────────────────────────────────────
struct FollowingView: View {
    let userID: String

    @EnvironmentObject var appState: AppState
    @StateObject private var vm = FollowListViewModel()

    var body: some View {
        Group {
            if vm.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if vm.users.isEmpty {
                emptyState
            } else {
                List(vm.users) { user in
                    FollowUserRow(user: user, viewerID: appState.currentUserID)
                        .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
                        .listRowSeparator(.hidden)
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle("팔로잉 \(vm.users.count)명")
        .navigationBarTitleDisplayMode(.inline)
        .task { await vm.loadFollowing(userID: userID, viewerID: appState.currentUserID) }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "waveform.path")
                .font(.system(size: 44))
                .foregroundColor(.driftwood)
            Text("아직 팔로잉하는 파람이 없어요")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.void)
            Text("파동에 공명하면 자연스럽게 연결돼요")
                .font(.system(size: 14))
                .foregroundColor(.driftwood)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// ─────────────────────────────────────────
// FollowUserRow — 팔로워/팔로잉 공통 행
// ─────────────────────────────────────────
struct FollowUserRow: View {
    let user: FollowUser
    let viewerID: String?

    @State private var isFollowing: Bool
    @EnvironmentObject var appState: AppState

    init(user: FollowUser, viewerID: String?) {
        self.user = user
        self.viewerID = viewerID
        _isFollowing = State(initialValue: user.isFollowing)
    }

    private var isMutual: Bool { user.isFollowing && isFollowing }
    private var isSelf: Bool { user.id == viewerID }

    var body: some View {
        NavigationLink(destination:
            UserProfileView(
                userID: user.id,
                nickname: user.nickname,
                profileImageURL: user.profileImageUrl
            ).environmentObject(appState)
        ) {
            HStack(spacing: 12) {
                // 프로필 이미지
                avatarView
                    .frame(width: 48, height: 48)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color(.systemGray5), lineWidth: 1))

                // 닉네임 + 맞팔 뱃지
                VStack(alignment: .leading, spacing: 3) {
                    Text(user.nickname)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.void)
                    if user.isFollowing && !isSelf {
                        Text("서로 팔로우 중")
                            .font(.system(size: 12))
                            .foregroundColor(.signalRed)
                    }
                    Text("팔로워 \(user.followerCount)명")
                        .font(.system(size: 12))
                        .foregroundColor(.driftwood)
                }

                Spacer()

                // 팔로우 버튼 (본인 제외)
                if !isSelf {
                    FollowButton(targetUserID: user.id, isFollowing: $isFollowing, compact: true)
                }
            }
            .padding(.vertical, 10)
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var avatarView: some View {
        if let urlStr = user.profileImageUrl, let url = URL(string: urlStr) {
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
            Text(String(user.nickname.prefix(1)))
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.signalRed)
        }
    }
}

// ─────────────────────────────────────────
// ViewModel
// ─────────────────────────────────────────
@MainActor
class FollowListViewModel: ObservableObject {
    @Published var users: [FollowUser] = []
    @Published var isLoading = false

    func loadFollowers(userID: String, viewerID: String?) async {
        isLoading = true
        defer { isLoading = false }
        users = (try? await APIClient.shared.get(
            "/users/\(userID)/followers",
            userID: viewerID
        )) ?? []
    }

    func loadFollowing(userID: String, viewerID: String?) async {
        isLoading = true
        defer { isLoading = false }
        users = (try? await APIClient.shared.get(
            "/users/\(userID)/following",
            userID: viewerID
        )) ?? []
    }
}
