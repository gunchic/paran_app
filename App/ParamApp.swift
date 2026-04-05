import SwiftUI

@main
struct ParamApp: App {
    @StateObject private var authManager = AuthManager()

    var body: some Scene {
        WindowGroup {
            AppRouter()
                .environmentObject(authManager)
                .preferredColorScheme(.light)
        }
    }
}
