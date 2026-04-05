import SwiftUI

// MARK: - AppRoute
enum AppRoute: Equatable {
    case onboarding
    case login
    case profileSetup
    case home
}

// MARK: - AppRouter
/// 화면 흐름 관리
/// - isProfileSet == false → ProfileSetupView
/// - isProfileSet == true  → HomeFeedView
/// - hasSeenOnboarding (UserDefaults) → 온보딩 표시 여부
struct AppRouter: View {
    @EnvironmentObject private var appState: AppState
    @State private var route: AppRoute = .onboarding

    private var hasSeenOnboarding: Bool {
        UserDefaults.standard.bool(forKey: "hasSeenOnboarding")
    }

    var body: some View {
        Group {
            switch route {
            case .onboarding:
                OnboardingView(onFinish: {
                    UserDefaults.standard.set(true, forKey: "hasSeenOnboarding")
                    route = .login
                })

            case .login:
                LoginView(onLogin: {
                    if appState.isProfileSet {
                        route = .home
                    } else {
                        route = .profileSetup
                    }
                })

            case .profileSetup:
                ProfileSetupView(onComplete: {
                    route = .home
                })

            case .home:
                HomeFeedView()
            }
        }
        .onAppear {
            if hasSeenOnboarding {
                if appState.isLoggedIn {
                    route = appState.isProfileSet ? .home : .profileSetup
                } else {
                    route = .login
                }
            }
        }
        .onChange(of: appState.isLoggedIn) { loggedIn in
            if !loggedIn { route = .login }
        }
    }
}
