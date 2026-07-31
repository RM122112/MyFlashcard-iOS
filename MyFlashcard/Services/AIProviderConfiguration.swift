import Foundation
import os

struct AIProviderConfigEntry {
    let provider: AIProviderIdentifier
    let priority: Int
    let isEnabled: Bool
}

enum AIProviderConfiguration {
    private static let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "MyFlashcard", category: "AIProviderConfiguration")

    // Aktivierungs-/Prioritätsreihenfolge (1 = höchste Priorität)
    static let providerConfigs: [AIProviderConfigEntry] = [
        .init(provider: .openAI, priority: 1, isEnabled: true),
        .init(provider: .openRouter, priority: 2, isEnabled: true),
        .init(provider: .claude, priority: 3, isEnabled: true),
        .init(provider: .gemini, priority: 4, isEnabled: true),
        .init(provider: .deepSeek, priority: 5, isEnabled: true),
        .init(provider: .groq, priority: 6, isEnabled: true),
        .init(provider: .mistral, priority: 7, isEnabled: true)
    ]

    static let environmentVariableNames: [AIProviderIdentifier: String] = [
        .openAI: "AI_PROXY_SECRET",
        .openRouter: "OPENROUTER_API_KEY",
        .claude: "CLAUDE_API_KEY",
        .gemini: "GEMINI_API_KEY",
        .deepSeek: "DEEPSEEK_API_KEY",
        .groq: "GROQ_API_KEY",
        .mistral: "MISTRAL_API_KEY"
    ]

    static let plistKeyNames: [AIProviderIdentifier: String] = [
        .openAI: "AI_PROXY_SECRET",
        .openRouter: "OPENROUTER_API_KEY",
        .claude: "CLAUDE_API_KEY",
        .gemini: "GEMINI_API_KEY",
        .deepSeek: "DEEPSEEK_API_KEY",
        .groq: "GROQ_API_KEY",
        .mistral: "MISTRAL_API_KEY"
    ]

    static func keys(for provider: AIProviderIdentifier) -> [String] {
        var sources: [String] = []

        if let keychainName = plistKeyNames[provider],
           let keychainValue = KeychainService.shared.read(for: keychainName),
           !keychainValue.isEmpty {
            sources.append(keychainValue)
        }

        if let plistName = plistKeyNames[provider],
           let plistValue = Bundle.main.object(forInfoDictionaryKey: plistName) as? String,
           !plistValue.isEmpty {
            sources.append(plistValue)
        }

        if let envName = environmentVariableNames[provider],
           let envValue = ProcessInfo.processInfo.environment[envName],
           !envValue.isEmpty {
            sources.append(envValue)
        }

        let keys = sources
            .flatMap { $0.split(separator: "|").map(String.init) }
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter(isRuntimeKeyValue)

        return Array(NSOrderedSet(array: keys)) as? [String] ?? keys
    }

    static func bootstrapStoredSecrets() {
        for entry in providerConfigs where entry.isEnabled {
            guard let plistName = plistKeyNames[entry.provider] else { continue }
            let fallbackSecret = Bundle.main.object(forInfoDictionaryKey: plistName) as? String
            logger.debug("bootstrap provider=\(entry.provider.rawValue, privacy: .public) key=\(plistName, privacy: .public) hasFallback=\((fallbackSecret?.isEmpty == false), privacy: .public)")
            KeychainService.shared.bootstrapIfNeeded(key: plistName, fallbackSecret: fallbackSecret)
        }
    }

    private static func isRuntimeKeyValue(_ value: String) -> Bool {
        guard !value.isEmpty else { return false }

        if value.hasPrefix("$("), value.hasSuffix(")") { return false }
        if value.hasPrefix("${"), value.hasSuffix("}") { return false }

        let normalized = value.lowercased()
        let invalidTokens: Set<String> = [
            "changeme",
            "your_api_key_here",
            "api_key_here"
        ]
        return !invalidTokens.contains(normalized)
    }
}
