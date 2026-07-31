import Foundation
import Security
import os

extension Notification.Name {
    static let aiProviderSecretsDidChange = Notification.Name("aiProviderSecretsDidChange")
}

final class KeychainService {
    static let shared = KeychainService()

    private let service: String
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "MyFlashcard", category: "KeychainService")

    private init() {
        self.service = Bundle.main.bundleIdentifier ?? "MyFlashcard"
    }

    func bootstrapIfNeeded(key: String, fallbackSecret: String?) {
        let normalizedKey = key.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalizedKey.isEmpty else { return }

        guard let secret = normalizedRuntimeSecret(fallbackSecret) else { return }

        if let current = read(for: normalizedKey), current == secret {
            return
        }

        do {
            try save(secret, for: normalizedKey, notify: false)
        } catch {
            logger.error("bootstrap_failed key=\(normalizedKey, privacy: .public) error=\(error.localizedDescription, privacy: .public)")
        }
    }

    @discardableResult
    func save(_ value: String, for key: String, notify: Bool = true) throws -> Bool {
        let normalizedKey = key.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalizedKey.isEmpty else {
            throw KeychainServiceError.emptyKey
        }

        let normalizedValue = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalizedValue.isEmpty else {
            throw KeychainServiceError.emptyValue
        }

        let query = baseQuery(for: normalizedKey)
        let attributes: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: normalizedKey,
            kSecValueData as String: Data(normalizedValue.utf8)
        ]

        let status = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
        if status == errSecSuccess {
            if notify { NotificationCenter.default.post(name: .aiProviderSecretsDidChange, object: nil) }
            return true
        }

        if status != errSecItemNotFound {
            throw KeychainServiceError.unexpectedStatus(status)
        }

        var addQuery = query
        addQuery[kSecValueData as String] = Data(normalizedValue.utf8)
        addQuery[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly

        let addStatus = SecItemAdd(addQuery as CFDictionary, nil)
        guard addStatus == errSecSuccess else {
            throw KeychainServiceError.unexpectedStatus(addStatus)
        }

        if notify { NotificationCenter.default.post(name: .aiProviderSecretsDidChange, object: nil) }
        return true
    }

    func read(for key: String) -> String? {
        let normalizedKey = key.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalizedKey.isEmpty else { return nil }

        var query = baseQuery(for: normalizedKey)
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        switch status {
        case errSecSuccess:
            guard let data = item as? Data else { return nil }
            return String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines)
        case errSecItemNotFound:
            return nil
        default:
            logger.error("read_failed key=\(normalizedKey, privacy: .public) status=\(status)")
            return nil
        }
    }

    private func baseQuery(for key: String) -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]
    }

    private func normalizedRuntimeSecret(_ secret: String?) -> String? {
        guard let trimmed = secret?.trimmingCharacters(in: .whitespacesAndNewlines), !trimmed.isEmpty else {
            return nil
        }

        if trimmed.hasPrefix("$("), trimmed.hasSuffix(")") { return nil }
        if trimmed.hasPrefix("${"), trimmed.hasSuffix("}") { return nil }

        let lower = trimmed.lowercased()
        let invalidTokens: Set<String> = [
            "changeme",
            "your_api_key_here",
            "api_key_here"
        ]
        return invalidTokens.contains(lower) ? nil : trimmed
    }
}

enum KeychainServiceError: LocalizedError {
    case emptyKey
    case emptyValue
    case unexpectedStatus(OSStatus)

    var errorDescription: String? {
        switch self {
        case .emptyKey:
            return "Keychain key is empty."
        case .emptyValue:
            return "Keychain value is empty."
        case .unexpectedStatus(let status):
            return "Keychain error: \(status)"
        }
    }
}
