import SwiftUI

struct LoginView: View {
    let onNewUser: () -> Void
    let onExistingUser: () -> Void

    @EnvironmentObject var appState: AppState

    @State private var isLoading = false
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
                    ) { handleSocialLogin(provider: "kakao") }

                    SocialButton(
                        label: "네이버로 계속하기",
                        badge: "N",
                        badgeIsEmoji: false,
                        bg: Color(red: 0.012, green: 0.780, blue: 0.353),
                        fg: .white,
                        isLoading: isLoading
                    ) { handleSocialLogin(provider: "naver") }

                    SocialButton(
                        label: "구글로 계속하기",
                        badge: "G",
                        badgeIsEmoji: false,
                        bg: .white,
                        fg: .black,
                        hasBorder: true,
                        isLoading: isLoading
                    ) { handleSocialLogin(provider: "google") }
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

    private func handleSocialLogin(provider: String) {
        isLoading = true
        errorMessage = nil

        Task {
            do {
                let code: String
                switch provider {
                case "kakao":  code = try await AuthService.shared.loginWithKakao()
                case "naver":  code = try await AuthService.shared.loginWithNaver()
                case "google": code = try await AuthService.shared.loginWithGoogle()
                default: return
                }

                let result = try await APIClient.shared.socialLogin(provider: provider, code: code)
                route(result: result)
            } catch {
                let msg = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
                errorMessage = "로그인 실패: \(msg)"
            }
            isLoading = false
        }
    }

    // MARK: - 응답에 따라 화면 전환

    private func route(result: SocialAuthResponse) {
        appState.currentUserID          = result.id
        appState.currentNickname        = result.nickname ?? ""
        appState.currentProfileImageURL = result.profileImageUrl
        appState.pendingUserID          = nil
        onExistingUser()
    }
}

// MARK: - 소셜 버튼

private struct SocialButton: View {
    let label: String
    let badge: String
    let badgeIsEmoji: Bool
    let bg: Color
    let fg: Color
    var hasBorder: Bool = false
    var isLoading: Bool = false
    let action: () -> Void

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
