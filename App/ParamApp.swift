import SwiftUI

@main
struct ParamApp: App {
    @StateObject private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            AppRouter()
                .environmentObject(appState)
                .preferredColorScheme(.dark)
        }
    }
}
