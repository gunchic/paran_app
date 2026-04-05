import SwiftUI

// MARK: - AppRouter
// AuthManager 기반 화면 분기
// 1. hasSeenOnboarding == false → OnboardingView
// 2. isLoggedIn == false → LoginView
// 3. isLoggedIn && !isProfileSet → ProfileSetupView
// 4. isLoggedIn && isProfileSet → MainTabView
struct AppRouter: View {
    @EnvironmentObject private var authManager: AuthManager
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding: Bool = false

    var body: some View {
        Group {
            if !hasSeenOnboarding {
                OnboardingView {
                    hasSeenOnboarding = true
                }
                .transition(.opacity)
            } else if !authManager.isLoggedIn {
                LoginView()
                    .transition(.opacity)
            } else if authManager.currentUser?.isProfileSet == false {
                ProfileSetupView()
                    .transition(.opacity)
            } else {
                MainTabView()
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.25), value: hasSeenOnboarding)
        .animation(.easeInOut(duration: 0.25), value: authManager.isLoggedIn)
        .animation(.easeInOut(duration: 0.25), value: authManager.currentUser?.isProfileSet)
    }
}
