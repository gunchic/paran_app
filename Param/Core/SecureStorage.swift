import Foundation
import Security

/// Keychain 기반 보안 저장소
/// userID 등 민감 정보를 UserDefaults 대신 Keychain에 저장
enum SecureStorage {

    private static let service = "app.param.secure"

    // MARK: - Write

    @discardableResult
    static func set(_ value: String, forKey key: String) -> Bool {
        let data = Data(value.utf8)
        let query: [CFString: Any] = [
            kSecClass:            kSecClassGenericPassword,
            kSecAttrService:      service,
            kSecAttrAccount:      key,
        ]
        // 기존 항목 삭제 후 재등록 (update보다 단순하고 일관됨)
        SecItemDelete(query as CFDictionary)

        var attrs = query
        attrs[kSecValueData] = data
        let status = SecItemAdd(attrs as CFDictionary, nil)
        return status == errSecSuccess
    }

    // MARK: - Read

    static func string(forKey key: String) -> String? {
        let query: [CFString: Any] = [
            kSecClass:            kSecClassGenericPassword,
            kSecAttrService:      service,
            kSecAttrAccount:      key,
            kSecReturnData:       true,
            kSecMatchLimit:       kSecMatchLimitOne,
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess,
              let data = result as? Data,
              let value = String(data: data, encoding: .utf8)
        else { return nil }
        return value
    }

    // MARK: - Delete

    @discardableResult
    static func remove(forKey key: String) -> Bool {
        let query: [CFString: Any] = [
            kSecClass:       kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: key,
        ]
        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess || status == errSecItemNotFound
    }

    // MARK: - Keys

    enum Key {
        static let userID           = "userID"
        static let nickname         = "nickname"
        static let profileImageURL  = "profileImageURL"
    }
}
