import Foundation

struct AIProviderConfigEntry {
    let provider: AIProviderIdentifier
    let priority: Int
    let isEnabled: Bool
}

enum AIProviderConfiguration {
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

    // ZENTRALE API-KEY-KONFIGURATION:
    // - Trage je Provider einen oder mehrere Keys ein.
    // - Mehrere Keys mit "|" trennen.
    // Beispiel: "key1|key2|key3"
    static let apiKeys: [AIProviderIdentifier: String] = [
        .openAI: "",
        .openRouter: "",
        .claude: "",
        .gemini: "",
        .deepSeek: "",
        .groq: "",
        .mistral: ""
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

        if let configured = apiKeys[provider], !configured.isEmpty {
            sources.append(configured)
        }

        if let envName = environmentVariableNames[provider],
           let envValue = ProcessInfo.processInfo.environment[envName],
           !envValue.isEmpty {
            sources.append(envValue)
        }

        if let plistName = plistKeyNames[provider],
           let plistValue = Bundle.main.object(forInfoDictionaryKey: plistName) as? String,
           !plistValue.isEmpty {
            sources.append(plistValue)
        }

        let keys = sources
            .flatMap { $0.split(separator: "|").map(String.init) }
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        return Array(NSOrderedSet(array: keys)) as? [String] ?? keys
    }
}
