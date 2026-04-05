import SwiftUI
import Combine

// MARK: - AppState
/// 전역 앱 상태. EnvironmentObject로 주입됨.
final class AppState: ObservableObject {
    @Published var currentUser: User?
    @Published var isLoading: Bool = false

    var isLoggedIn: Bool { currentUser != nil }
    var isProfileSet: Bool { currentUser?.isProfileSet == true }
}
