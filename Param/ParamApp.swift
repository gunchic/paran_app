import SwiftUI

// MARK: - 앱 라우트
enum AppRoute {
    case splash
    case onboarding
    case login
    case profileSetup
    case main
}

// MARK: - App Entry
@main
struct ParamApp: App {
    @StateObject private var appState = AppState()
    @State private var route: AppRoute = .splash

    var body: some Scene {
        WindowGroup {
            routeView
                .environmentObject(appState)
                .onChange(of: appState.currentUserID) { newValue in
                    if newValue == nil {
                        route = .login
                    }
                }
        }
    }

    @ViewBuilder
    private var routeView: some View {
        switch route {
        case .splash:
            SplashView(onComplete: { route = $0 })

        case .onboarding:
            OnboardingSlideView(
                onSkip:     { route = .login },
                onComplete: { route = .login }
            )

        case .login:
            LoginView(
                onNewUser:      { route = .profileSetup },
                onExistingUser: { route = .main }
            )

        case .profileSetup:
            ProfileSetupView(onComplete: { route = .main })

        case .main:
            MainTabView()
        }
    }
}
