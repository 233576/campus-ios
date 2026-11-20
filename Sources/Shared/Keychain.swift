import Foundation
import Security

/// 钥匙串存档。token / 密码只进钥匙串，其余设置进 UserDefaults。
///
/// 两个模块共用同一个 service，靠 `account` 区分（洗衣用 `token` / 账号 UUID，
/// 校园网用 `token` / `password`）。合并成一个 App 后它们互不干扰。
enum Keychain {

    private static let service = "com.campus.ios"

    @discardableResult
    static func save(_ value: String, account: String = "default") -> Bool {
        guard !value.isEmpty else {
            delete(account: account)
            return false
        }
        guard let data = value.data(using: .utf8) else { return false }
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        let attributes: [String: Any] = [
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
        ]
        if SecItemUpdate(query as CFDictionary, attributes as CFDictionary) == errSecSuccess {
            return true
        }
        var insert = query
        attributes.forEach { insert[$0.key] = $0.value }
        return SecItemAdd(insert as CFDictionary, nil) == errSecSuccess
    }

    static func load(account: String = "default") -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var item: CFTypeRef?
        guard SecItemCopyMatching(query as CFDictionary, &item) == errSecSuccess,
              let data = item as? Data,
              let text = String(data: data, encoding: .utf8) else {
            return nil
        }
        return text
    }

    static func delete(account: String = "default") {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        SecItemDelete(query as CFDictionary)
    }
}
