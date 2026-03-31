import SwiftUI

// ─────────────────────────────────────────
// FollowButton — 재사용 팔로우/언팔로우 버튼
// 낙관적 업데이트: 탭 즉시 UI 반영 후 API 호출
// ─────────────────────────────────────────
struct FollowButton: View {
    let targetUserID: String
    @Binding var isFollowing: Bool

    @EnvironmentObject var appState: AppState
    @State private var isLoading = false

    var compact: Bool = false  // true면 작은 사이즈

    var body: some View {
        Button(action: toggle) {
            if isLoading {
                ProgressView()
                    .scaleEffect(compact ? 0.6 : 0.8)
                    .frame(width: compact ? 64 : 100, height: compact ? 28 : 36)
            } else {
                Text(isFollowing ? "팔로잉" : "팔로우")
                    .font(.system(size: compact ? 12 : 14, weight: .semibold))
                    .foregroundColor(isFollowing ? .signalRed : .white)
                    .frame(width: compact ? 64 : 100, height: compact ? 28 : 36)
                    .background(isFollowing ? Color.white : Color.signalRed)
                    .cornerRadius(compact ? 8 : 10)
                    .overlay(
                        RoundedRectangle(cornerRadius: compact ? 8 : 10)
                            .stroke(Color.signalRed, lineWidth: isFollowing ? 1 : 0)
                    )
            }
        }
        .disabled(isLoading)
        .animation(.spring(response: 0.25), value: isFollowing)
    }

    private func toggle() {
        guard let myID = appState.currentUserID else { return }
        // 낙관적 업데이트
        isFollowing.toggle()
        isLoading = true
        Task {
            do {
                if isFollowing {
                    try await APIClient.shared.routeFollow(followerID: myID, followingID: targetUserID)
                } else {
                    try await APIClient.shared.routeUnfollow(followerID: myID, followingID: targetUserID)
                }
            } catch {
                // 실패 시 롤백
                await MainActor.run { isFollowing.toggle() }
            }
            await MainActor.run { isLoading = false }
        }
    }
}
