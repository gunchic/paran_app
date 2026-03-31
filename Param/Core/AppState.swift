import Foundation
import Combine
import Supabase

class AppState: ObservableObject {
    @Published var currentUserID: String? {
        didSet { SecureStorage.set(or: currentUserID, forKey: SecureStorage.Key.userID) }
    }
    @Published var currentNickname: String? {
        didSet { SecureStorage.set(or: currentNickname, forKey: SecureStorage.Key.nickname) }
    }
    @Published var currentProfileImageURL: String? {
        didSet { SecureStorage.set(or: currentProfileImageURL, forKey: SecureStorage.Key.profileImageURL) }
    }

    /// 소셜 로그인 후 프로필 미설정 신규 유저의 ID (세션 내에서만 유지)
    @Published var pendingUserID: String?

    private var authListenerTask: Task<Void, Never>?

    init() {
        self.currentUserID          = SecureStorage.string(forKey: SecureStorage.Key.userID)
        self.currentNickname        = SecureStorage.string(forKey: SecureStorage.Key.nickname)
        self.currentProfileImageURL = SecureStorage.string(forKey: SecureStorage.Key.profileImageURL)

        startAuthListener()
    }

    deinit {
        authListenerTask?.cancel()
    }

    // MARK: - Supabase Auth 상태 리스너

    private func startAuthListener() {
        authListenerTask = Task { [weak self] in
            for await (event, session) in SupabaseManager.shared.client.auth.authStateChanges {
                await MainActor.run {
                    switch event {
                    case .signedIn:
                        // 이미 프로필 정보가 있으면 유지 (로그아웃 없이 앱 재시작)
                        if let session = session {
                            let uid = session.user.id.uuidString
                            if self?.currentUserID == nil {
                                self?.currentUserID = uid
                            }
                        }
                    case .signedOut, .userDeleted:
                        self?.currentUserID          = nil
                        self?.currentNickname        = nil
                        self?.currentProfileImageURL = nil
                        self?.pendingUserID          = nil
                    default:
                        break
                    }
                }
            }
        }
    }

    // MARK: - 프로필 업데이트

    func updateProfile(userID: String, nickname: String, profileImageURL: String?) {
        currentUserID          = userID
        currentNickname        = nickname
        currentProfileImageURL = profileImageURL
        pendingUserID          = nil
    }

    // MARK: - 로그아웃

    func logout() {
        currentUserID          = nil
        currentNickname        = nil
        currentProfileImageURL = nil
        pendingUserID          = nil
        SecureStorage.remove(forKey: SecureStorage.Key.userID)
        SecureStorage.remove(forKey: SecureStorage.Key.nickname)
        SecureStorage.remove(forKey: SecureStorage.Key.profileImageURL)
        Task { try? await AuthService.shared.logout() }
    }
}

// MARK: - SecureStorage optional helper

private extension SecureStorage {
    static func set(or value: String?, forKey key: String) {
        if let value { set(value, forKey: key) }
        else { remove(forKey: key) }
    }
}
