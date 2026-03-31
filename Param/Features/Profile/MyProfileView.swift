import SwiftUI
import Combine

// ─────────────────────────────────────────────────────────────
// MyProfileView — "나" 탭
// 핵심 영역: 프로필 헤더 + 내가 올린 파동 목록
// UI/기능 변경이 잦으므로 섹션별 컴포넌트로 분리
// ─────────────────────────────────────────────────────────────
struct MyProfileView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var vm = MyProfileViewModel()
    @State private var showLogoutAlert = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    ProfileHeaderSection(
                        nickname: vm.user?.nickname ?? appState.currentNickname ?? "",
                        profileImageURL: vm.user?.profileImageUrl ?? appState.currentProfileImageURL,
                        momentCount: vm.moments.count,
                        email: vm.user?.email,
                        socialProvider: vm.user?.socialProvider,
                        stats: vm.stats,
                        userID: appState.currentUserID ?? ""
                    )

                    Divider().padding(.vertical, 8)

                    MyMomentsSection(moments: vm.moments, isLoading: vm.isLoading)
                }
            }
            .navigationTitle("나")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showLogoutAlert = true
                    } label: {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .alert("로그아웃", isPresented: $showLogoutAlert) {
                Button("취소", role: .cancel) { }
                Button("로그아웃", role: .destructive) {
                    appState.logout()
                }
            } message: {
                Text("파람 로그아웃을 하시겠습니까?")
            }
            .task {
                if let id = appState.currentUserID {
                    await vm.load(userID: id)
                }
            }
        }
    }
}

// ─────────────────────────────────────────────────────────────
// MARK: - ViewModel
// ─────────────────────────────────────────────────────────────
@MainActor
class MyProfileViewModel: ObservableObject {
    @Published var user: User?
    @Published var moments: [Moment] = []
    @Published var stats: FollowStats?
    @Published var isLoading = false

    func load(userID: String) async {
        isLoading = true
        defer { isLoading = false }
        async let fetchedUser: User        = APIClient.shared.get("/users/\(userID)")
        async let fetchedMoments: [Moment] = APIClient.shared.get("/users/\(userID)/moments")
        async let fetchedStats: FollowStats = APIClient.shared.get("/users/\(userID)/follow-stats")
        user    = try? await fetchedUser
        moments = (try? await fetchedMoments) ?? []
        stats   = try? await fetchedStats
    }
}

// ─────────────────────────────────────────────────────────────
// MARK: - ProfileHeaderSection
// 프로필 이미지 + 닉네임 + 파동 수 — 독립 컴포넌트로 분리
// ─────────────────────────────────────────────────────────────
struct ProfileHeaderSection: View {
    let nickname: String
    let profileImageURL: String?
    let momentCount: Int
    var email: String? = nil
    var socialProvider: String? = nil
    var stats: FollowStats? = nil
    var userID: String = ""

    var body: some View {
        VStack(spacing: 16) {
            // 프로필 이미지
            Group {
                if let urlStr = profileImageURL, let url = URL(string: urlStr) {
                    CachedImage(url: url) { image in
                        image.resizable().scaledToFill()
                    } placeholder: {
                        avatarPlaceholder
                    }
                } else {
                    avatarPlaceholder
                }
            }
            .frame(width: 88, height: 88)
            .clipShape(Circle())
            .overlay(Circle().stroke(Color(.systemGray4), lineWidth: 1))

            // 닉네임
            Text(nickname)
                .font(.system(size: 20, weight: .bold))

            // 이메일 / 소셜 로그인 제공자
            if let email {
                HStack(spacing: 6) {
                    if let provider = socialProvider {
                        Text(providerLabel(provider))
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(providerColor(provider))
                            .cornerRadius(6)
                    }
                    Text(email)
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }
            }

            // 팔로워 / 팔로잉 / 파동 수
            HStack(spacing: 32) {
                if let stats, !userID.isEmpty {
                    NavigationLink(destination: FollowersView(userID: userID, title: nickname)) {
                        statItem(count: stats.followerCount, label: "팔로워")
                    }
                    .buttonStyle(.plain)

                    NavigationLink(destination: FollowingView(userID: userID)) {
                        statItem(count: stats.followingCount, label: "팔로잉")
                    }
                    .buttonStyle(.plain)
                }

                HStack(spacing: 4) {
                    Image(systemName: "water.waves")
                        .font(.system(size: 13))
                        .foregroundColor(.signalRed)
                    statItem(count: momentCount, label: "파동")
                }
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

    private func providerLabel(_ provider: String) -> String {
        switch provider {
        case "google": return "Google"
        case "kakao":  return "Kakao"
        case "naver":  return "Naver"
        default:       return provider
        }
    }

    private func providerColor(_ provider: String) -> Color {
        switch provider {
        case "google": return Color(red: 0.26, green: 0.52, blue: 0.96)
        case "kakao":  return Color(red: 1.0, green: 0.898, blue: 0)
        case "naver":  return Color(red: 0.012, green: 0.780, blue: 0.353)
        default:       return .gray
        }
    }

    private var avatarPlaceholder: some View {
        ZStack {
            Color.redTint
            Text(String(nickname.prefix(1)))
                .font(.system(size: 34, weight: .semibold))
                .foregroundColor(.signalRed)
        }
    }
}

// ─────────────────────────────────────────────────────────────
// MARK: - MyMomentsSection
// 내가 올린 파동 목록 — 독립 컴포넌트로 분리
// ─────────────────────────────────────────────────────────────
struct MyMomentsSection: View {
    let moments: [Moment]
    let isLoading: Bool

    var body: some View {
        if isLoading {
            ProgressView()
                .padding(.top, 40)
        } else if moments.isEmpty {
            VStack(spacing: 12) {
                Image(systemName: "water.waves")
                    .font(.system(size: 36))
                    .foregroundColor(Color(.systemGray4))
                Text("아직 올린 파동이 없어요")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(.top, 60)
        } else {
            LazyVStack(spacing: 0) {
                ForEach(moments) { moment in
                    NavigationLink(destination: MomentDetailView(moment: moment)) {
                        MomentCard(moment: moment)
                    }
                    .buttonStyle(.plain)
                    Divider().padding(.horizontal, 16)
                }
            }
        }
    }
}
