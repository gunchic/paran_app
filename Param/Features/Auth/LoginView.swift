import SwiftUI

struct LoginView: View {
    let onNewUser:      () -> Void
    let onExistingUser: () -> Void

    @EnvironmentObject var appState: AppState

    @State private var isLoading    = false
    @State private var errorMessage: String?

    var body: some View {
        ZStack {
            Color.warmPaper.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // 워드마크
                Text("PARAM")
                    .font(.system(size: 36, weight: .black))
                    .foregroundColor(.void)

                Spacer().frame(height: 14)

                Text("어!너도? 나도!")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.void)

                Spacer()

                // 에러 메시지
                if let error = errorMessage {
                    Text(error)
                        .font(.system(size: 13))
                        .foregroundColor(.signalRed)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                        .padding(.bottom, 12)
                }

                // 소셜 로그인 버튼
                VStack(spacing: 12) {
                    SocialButton(
                        label: "카카오로 계속하기",
                        badge: "💬",
                        badgeIsEmoji: true,
                        bg: Color(red: 1.0, green: 0.898, blue: 0),
                        fg: .black,
                        isLoading: isLoading
                    ) { handleLogin(provider: "kakao") }

                    SocialButton(
                        label: "네이버로 계속하기",
                        badge: "N",
                        badgeIsEmoji: false,
                        bg: Color(red: 0.012, green: 0.780, blue: 0.353),
                        fg: .white,
                        isLoading: isLoading
                    ) { handleLogin(provider: "naver") }

                    SocialButton(
                        label: "구글로 계속하기",
                        badge: "G",
                        badgeIsEmoji: false,
                        bg: .white,
                        fg: .black,
                        hasBorder: true,
                        isLoading: isLoading
                    ) { handleLogin(provider: "google") }
                }
                .padding(.horizontal, 24)
                .disabled(isLoading)

                Spacer().frame(height: 28)

                Text("가입 시 이용약관 및 개인정보처리방침에 동의합니다")
                    .font(.system(size: 11))
                    .foregroundColor(.driftwood)
                    .multilineTextAlignment(.center)

                Spacer().frame(height: 52)
            }
        }
    }

    // MARK: - 소셜 로그인

    private func handleLogin(provider: String) {
        isLoading    = true
        errorMessage = nil

        Task {
            do {
                let session: SupabaseSession
                switch provider {
                case "kakao":  session = try await AuthService.shared.loginWithKakao()
                case "naver":  session = try await AuthService.shared.loginWithNaver()
                case "google": session = try await AuthService.shared.loginWithGoogle()
                default: return
                }
                await routeAfterLogin(session: session)
            } catch {
                let msg = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
                errorMessage = "로그인 실패: \(msg)"
            }
            isLoading = false
        }
    }

    // MARK: - 로그인 후 화면 전환

    @MainActor
    private func routeAfterLogin(session: SupabaseSession) async {
        do {
            let (userID, nickname, profileImageURL) =
                try await AuthService.shared.fetchOrCreateProfile(session: session)

            if let nick = nickname, !nick.isEmpty {
                // 기존 유저 → 메인 앱
                appState.updateProfile(userID: userID, nickname: nick, profileImageURL: profileImageURL)
                onExistingUser()
            } else {
                // 신규 유저 → 프로필 설정
                appState.pendingUserID = userID
                appState.currentUserID = userID
                onNewUser()
            }
        } catch {
            errorMessage = "프로필 조회 실패: \(error.localizedDescription)"
        }
    }
}

// MARK: - 소셜 버튼

private struct SocialButton: View {
    let label:        String
    let badge:        String
    let badgeIsEmoji: Bool
    let bg:           Color
    let fg:           Color
    var hasBorder:    Bool = false
    var isLoading:    Bool = false
    let action:       () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(bg)
                    .overlay(
                        Group {
                            if hasBorder {
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.sand, lineWidth: 1)
                            }
                        }
                    )

                HStack(spacing: 0) {
                    Text(badge)
                        .font(badgeIsEmoji
                              ? .system(size: 18)
                              : .system(size: 16, weight: .bold))
                        .foregroundColor(fg)
                        .frame(width: 28)

                    Spacer()

                    if isLoading {
                        ProgressView().tint(fg)
                    } else {
                        Text(label)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(fg)
                    }

                    Spacer()
                }
                .padding(.horizontal, 20)
            }
            .frame(height: 52)
        }
    }
}
