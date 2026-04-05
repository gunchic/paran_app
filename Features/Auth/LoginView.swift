import SwiftUI

// A-02 로그인 — 라이트 모드
struct LoginView: View {
    @EnvironmentObject private var authManager: AuthManager
    @State private var errorMessage: String? = nil
    @State private var showError: Bool = false

    var body: some View {
        ZStack {
            Color.paper.ignoresSafeArea()

            VStack(spacing: 0) {
                // 워드마크 + 슬로건
                VStack(spacing: Spacing.xs) {
                    Text("PARAM")
                        .font(.heading2)
                        .tracking(6)
                        .foregroundColor(.void)

                    Text("파동이 닿는 곳")
                        .font(.caption)
                        .tracking(1)
                        .foregroundColor(.ash)
                }
                .padding(.top, Spacing.xl)

                Spacer()

                // 환영 텍스트
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    Text("파람에\n오신 걸 환영해요")
                        .font(.heading1)
                        .tracking(-1)
                        .foregroundColor(.void)
                        .lineSpacing(4)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, Spacing.lg)

                Spacer()

                // 로그인 버튼 영역
                VStack(spacing: Spacing.md) {
                    // 구글 로그인 버튼
                    Button(action: handleGoogleLogin) {
                        HStack(spacing: Spacing.sm) {
                            if authManager.isLoading {
                                ProgressView()
                                    .tint(.wave400)
                                    .scaleEffect(0.85)
                            } else {
                                Image(systemName: "globe")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.void)
                            }
                            Text("Google로 계속하기")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(.void)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.surfaceContainer)
                        .clipShape(RoundedRectangle(cornerRadius: Radius.md, style: .continuous))
                    }
                    .disabled(authManager.isLoading)

                    // 약관 안내
                    Text("로그인 시 서비스 이용약관에 동의하게 됩니다")
                        .font(.caption)
                        .tracking(0.5)
                        .foregroundColor(.ash)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, Spacing.lg)
                .padding(.bottom, Spacing.xl)
            }
        }
        .alert("로그인 실패", isPresented: $showError) {
            Button("확인", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "알 수 없는 오류가 발생했어요")
        }
    }

    private func handleGoogleLogin() {
        Task {
            do {
                try await authManager.loginWithGoogle()
            } catch {
                errorMessage = error.localizedDescription
                showError = true
            }
        }
    }
}

#Preview {
    LoginView()
        .environmentObject(AuthManager())
}
