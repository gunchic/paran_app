import Foundation
import Combine

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

    init() {
        self.currentUserID          = SecureStorage.string(forKey: SecureStorage.Key.userID)
        self.currentNickname        = SecureStorage.string(forKey: SecureStorage.Key.nickname)
        self.currentProfileImageURL = SecureStorage.string(forKey: SecureStorage.Key.profileImageURL)
    }

    func logout() {
        currentUserID          = nil
        currentNickname        = nil
        currentProfileImageURL = nil
        pendingUserID          = nil
        SecureStorage.remove(forKey: SecureStorage.Key.userID)
        SecureStorage.remove(forKey: SecureStorage.Key.nickname)
        SecureStorage.remove(forKey: SecureStorage.Key.profileImageURL)
    }
}

// MARK: - SecureStorage optional helper

private extension SecureStorage {
    /// nil이면 삭제, 값이 있으면 저장
    static func set(or value: String?, forKey key: String) {
        if let value { set(value, forKey: key) }
        else { remove(forKey: key) }
    }
}
