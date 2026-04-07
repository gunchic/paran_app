import SwiftUI

// MARK: - AppRouter
// 인증 상태에 따른 화면 분기
// 1. isLoading → SplashView (세션 복원 중)
// 2. hasSeenOnboarding == false → OnboardingView
// 3. hasSession == false → LoginView
// 4. isProfileSet == false → ProfileSetupView
// 5. 정상 → MainTabView
struct AppRouter: View {
    @EnvironmentObject private var authManager: AuthManager
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding: Bool = false

    var body: some View {
        Group {
            if authManager.isLoading {
                splashScreen
            } else if !hasSeenOnboarding {
                OnboardingView {
                    hasSeenOnboarding = true
                }
                .transition(.opacity)
            } else if !authManager.hasSession {
                LoginView()
                    .transition(.opacity)
            } else if !authManager.currentUser!.isProfileSet {
                ProfileSetupView()
                    .transition(.opacity)
            } else {
                MainTabView()
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.25), value: authManager.isLoading)
        .animation(.easeInOut(duration: 0.25), value: hasSeenOnboarding)
        .animation(.easeInOut(duration: 0.25), value: authManager.hasSession)
        .animation(.easeInOut(duration: 0.25), value: authManager.currentUser?.isProfileSet)
    }

    // MARK: - 스플래시 (세션 복원 대기)
    private var splashScreen: some View {
        ZStack {
            Color.paper.ignoresSafeArea()
            VStack(spacing: Spacing.md) {
                Text("PARAM")
                    .font(.system(size: 32, weight: .black))
                    .foregroundColor(.void)
                    .tracking(6)
                ProgressView().tint(.wave400)
            }
        }
    }
}
