import Foundation
import Security

final class KeychainService {
    static let shared = KeychainService()

    enum SecretKey: String {
        case proxyAI = "proxy_ai_secret"
    }

    private let service: String

    private init() {
        self.service = (Bundle.main.bundleIdentifier ?? "com.example.MyFlashcardR") + ".secrets"
    }

    func bootstrapIfNeeded(key: SecretKey, fallbackSecret: String?) {
        guard let fallbackSecret else { return }
        let trimmed = fallbackSecret.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, read(for: key) == nil else { return }
        _ = save(trimmed, for: key)
    }

    func save(_ value: String, for key: SecretKey) -> Bool {
        let encoded = Data(value.utf8)

        let baseQuery: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: key.rawValue
        ]

        let attributes: [CFString: Any] = [
            kSecValueData: encoded,
            kSecAttrAccessible: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]

        let updateStatus = SecItemUpdate(baseQuery as CFDictionary, attributes as CFDictionary)
        if updateStatus == errSecSuccess {
            return true
        }

        var addQuery = baseQuery
        attributes.forEach { addQuery[$0.key] = $0.value }

        let addStatus = SecItemAdd(addQuery as CFDictionary, nil)
        return addStatus == errSecSuccess
    }

    func read(for key: SecretKey) -> String? {
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: key.rawValue,
            kSecReturnData: true,
            kSecMatchLimit: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess,
              let data = result as? Data,
              let value = String(data: data, encoding: .utf8),
              !value.isEmpty
        else {
            return nil
        }

        return value
    }
}

