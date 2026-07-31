import Foundation
import os

// MARK: - Multi-Provider AI Service
// Zentraler AIProviderManager mit API-Key-Pooling, Failover, Load-Balancing und Health-Checks

// MARK: - Provider Protocol

/// Gemeinsames Protokoll fuer alle AI-Provider
protocol AIProvider {
    var identifier: AIProviderIdentifier { get }
    var displayName: String { get }
    var baseURL: String { get }
    var defaultModel: String { get }
    var maxTokensDefault: Int { get }
    func buildRequest(messages: [AIMessage], model: String?, maxTokens: Int?, temperature: Double?) -> AIProviderRequest
    func parseResponse(data: Data) -> AIProviderResponse?
    func authorizationHeader(for apiKey: String) -> (field: String, value: String)
}

// MARK: - Types

enum AIProviderIdentifier: String, CaseIterable, Codable {
    case openAI = "openai"
    case openRouter = "openrouter"
    case claude = "claude"
    case gemini = "gemini"
    case deepSeek = "deepseek"
    case groq = "groq"
    case mistral = "mistral"
}

struct AIMessage: Codable {
    let role: String    // "system", "user", "assistant"
    let content: String
}

struct AIProviderRequest {
    let body: Data?
    let additionalHeaders: [String: String]
}

struct AIProviderResponse {
    let content: String
    let model: String?
    let tokensUsed: Int?
    let finishReason: String?
    let provider: AIProviderIdentifier?

    init(
        content: String,
        model: String?,
        tokensUsed: Int?,
        finishReason: String?,
        provider: AIProviderIdentifier? = nil
    ) {
        self.content = content
        self.model = model
        self.tokensUsed = tokensUsed
        self.finishReason = finishReason
        self.provider = provider
    }
}

enum AIProviderError: Error, LocalizedError {
    case noAvailableProvider
    case allKeysExhausted(provider: String)
    case allProvidersFailed
    case rateLimited(retryAfter: TimeInterval?)
    case timeout
    case networkError(Error)
    case invalidResponse(statusCode: Int)
    case authenticationFailed

    var errorDescription: String? {
        switch self {
        case .noAvailableProvider:
            return "Kein KI-Provider verfuegbar. Lege lokal MyFlashcard/Config/APIKeys.local.xcconfig an und trage mindestens einen API-Key ein."
        case .allKeysExhausted(let p): return "Alle API-Keys fuer \(p) erschoepft."
        case .allProvidersFailed: return "Alle KI-Provider sind aktuell nicht erreichbar. Bitte spaeter erneut versuchen."
        case .rateLimited: return "Rate-Limit erreicht. Wechsle Provider..."
        case .timeout: return "Zeitlimit ueberschritten."
        case .networkError: return "Netzwerkfehler."
        case .invalidResponse(let code): return "Ungueltiger Antwortcode: \(code)"
        case .authenticationFailed: return "Authentifizierung fehlgeschlagen."
        }
    }
}

// MARK: - API Key State

struct APIKeyState {
    let key: String
    var isBlocked: Bool = false
    var blockedUntil: Date?
    var requestCount: Int = 0
    var lastUsed: Date?
    var lastError: Date?
    var consecutiveErrors: Int = 0

    var isAvailable: Bool {
        if isBlocked, let until = blockedUntil, until > Date() { return false }
        if isBlocked, let until = blockedUntil, until <= Date() { return true } // Cooldown abgelaufen
        return !isBlocked
    }

    mutating func markBlocked(cooldown: TimeInterval = 60) {
        isBlocked = true
        blockedUntil = Date().addingTimeInterval(cooldown)
        consecutiveErrors += 1
        lastError = Date()
    }

    mutating func markSuccess() {
        isBlocked = false
        blockedUntil = nil
        consecutiveErrors = 0
        requestCount += 1
        lastUsed = Date()
    }

    mutating func resetIfCooldownExpired() {
        if isBlocked, let until = blockedUntil, until <= Date() {
            isBlocked = false
            blockedUntil = nil
        }
    }
}

// MARK: - Provider Health

struct ProviderHealth {
    var isAvailable: Bool = false
    var latencyMs: Int = 0
    var lastChecked: Date?
    var consecutiveFailures: Int = 0
    var totalRequests: Int = 0
    var totalTokensUsed: Int = 0
    var rateLimitRemaining: Int?
    var rateLimitResetDate: Date?

    var isHealthy: Bool {
        isAvailable && consecutiveFailures < 3
    }

    var budgetUsagePercent: Double {
        guard let remaining = rateLimitRemaining else { return 0 }
        // Annahme: 100% = remaining bei 0
        return remaining < 20 ? 80.0 : Double(100 - remaining)
    }
}

// MARK: - Provider Configuration

struct ProviderConfiguration {
    let identifier: AIProviderIdentifier
    var priority: Int // Niedriger = hoehere Prioritaet
    var isEnabled: Bool
    var keys: [APIKeyState]
    var health: ProviderHealth
    var currentKeyIndex: Int = 0

    mutating func nextAvailableKey() -> String? {
        // Round-Robin mit Verfuegbarkeitspruefung
        let count = keys.count
        guard count > 0 else { return nil }

        for i in 0..<count {
            let idx = (currentKeyIndex + i) % count
            keys[idx].resetIfCooldownExpired()
            if keys[idx].isAvailable {
                currentKeyIndex = (idx + 1) % count
                return keys[idx].key
            }
        }
        return nil
    }

    mutating func markKeyFailed(key: String, cooldown: TimeInterval = 60) {
        if let idx = keys.firstIndex(where: { $0.key == key }) {
            keys[idx].markBlocked(cooldown: cooldown)
        }
        health.consecutiveFailures += 1
    }

    mutating func markKeySuccess(key: String, tokensUsed: Int = 0) {
        if let idx = keys.firstIndex(where: { $0.key == key }) {
            keys[idx].markSuccess()
        }
        health.consecutiveFailures = 0
        health.totalRequests += 1
        health.totalTokensUsed += tokensUsed
    }

    var hasAvailableKeys: Bool {
        keys.contains { state in
            var mutableState = state
            mutableState.resetIfCooldownExpired()
            return mutableState.isAvailable
        }
    }
}

// MARK: - Concrete Providers

struct OpenAIProvider: AIProvider {
    let identifier: AIProviderIdentifier = .openAI
    let displayName = "OpenAI"
    let baseURL = "https://api.openai.com/v1/chat/completions"
    let defaultModel = "gpt-4o-mini"
    let maxTokensDefault = 800

    func buildRequest(messages: [AIMessage], model: String?, maxTokens: Int?, temperature: Double?) -> AIProviderRequest {
        let body: [String: Any] = [
            "model": model ?? defaultModel,
            "messages": messages.map { ["role": $0.role, "content": $0.content] },
            "max_tokens": maxTokens ?? maxTokensDefault,
            "temperature": temperature ?? 0.7
        ]
        let data = try? JSONSerialization.data(withJSONObject: body)
        return AIProviderRequest(body: data, additionalHeaders: [:])
    }

    func parseResponse(data: Data) -> AIProviderResponse? {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let choices = json["choices"] as? [[String: Any]],
              let message = choices.first?["message"] as? [String: Any],
              let content = message["content"] as? String else { return nil }

        let usage = json["usage"] as? [String: Any]
        let tokens = usage?["total_tokens"] as? Int

        return AIProviderResponse(
            content: content.trimmingCharacters(in: .whitespacesAndNewlines),
            model: json["model"] as? String,
            tokensUsed: tokens,
            finishReason: choices.first?["finish_reason"] as? String
        )
    }

    func authorizationHeader(for apiKey: String) -> (field: String, value: String) {
        ("Authorization", "Bearer \(apiKey)")
    }
}

struct OpenRouterProvider: AIProvider {
    let identifier: AIProviderIdentifier = .openRouter
    let displayName = "OpenRouter"
    let baseURL = "https://openrouter.ai/api/v1/chat/completions"
    let defaultModel = "meta-llama/llama-3.1-8b-instruct:free"
    let maxTokensDefault = 800

    func buildRequest(messages: [AIMessage], model: String?, maxTokens: Int?, temperature: Double?) -> AIProviderRequest {
        let body: [String: Any] = [
            "model": model ?? defaultModel,
            "messages": messages.map { ["role": $0.role, "content": $0.content] },
            "max_tokens": maxTokens ?? maxTokensDefault,
            "temperature": temperature ?? 0.7
        ]
        let data = try? JSONSerialization.data(withJSONObject: body)
        return AIProviderRequest(body: data, additionalHeaders: [
            "HTTP-Referer": "https://myflashcard.app",
            "X-Title": "MyFlashcard"
        ])
    }

    func parseResponse(data: Data) -> AIProviderResponse? {
        // Gleiches Format wie OpenAI
        OpenAIProvider().parseResponse(data: data)
    }

    func authorizationHeader(for apiKey: String) -> (field: String, value: String) {
        ("Authorization", "Bearer \(apiKey)")
    }
}

struct ClaudeProvider: AIProvider {
    let identifier: AIProviderIdentifier = .claude
    let displayName = "Claude"
    let baseURL = "https://api.anthropic.com/v1/messages"
    let defaultModel = "claude-3-haiku-20240307"
    let maxTokensDefault = 800

    func buildRequest(messages: [AIMessage], model: String?, maxTokens: Int?, temperature: Double?) -> AIProviderRequest {
        let systemMsg = messages.first(where: { $0.role == "system" })?.content ?? ""
        let userMessages = messages.filter { $0.role != "system" }

        let body: [String: Any] = [
            "model": model ?? defaultModel,
            "system": systemMsg,
            "messages": userMessages.map { ["role": $0.role, "content": $0.content] },
            "max_tokens": maxTokens ?? maxTokensDefault,
            "temperature": temperature ?? 0.7
        ]
        let data = try? JSONSerialization.data(withJSONObject: body)
        return AIProviderRequest(body: data, additionalHeaders: [
            "anthropic-version": "2023-06-01"
        ])
    }

    func parseResponse(data: Data) -> AIProviderResponse? {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let content = json["content"] as? [[String: Any]],
              let text = content.first?["text"] as? String else { return nil }

        let usage = json["usage"] as? [String: Any]
        let inputTokens = usage?["input_tokens"] as? Int ?? 0
        let outputTokens = usage?["output_tokens"] as? Int ?? 0

        return AIProviderResponse(
            content: text.trimmingCharacters(in: .whitespacesAndNewlines),
            model: json["model"] as? String,
            tokensUsed: inputTokens + outputTokens,
            finishReason: json["stop_reason"] as? String
        )
    }

    func authorizationHeader(for apiKey: String) -> (field: String, value: String) {
        ("x-api-key", apiKey)
    }
}

struct GeminiProvider: AIProvider {
    let identifier: AIProviderIdentifier = .gemini
    let displayName = "Gemini"
    let baseURL = "https://generativelanguage.googleapis.com/v1beta/models"
    let defaultModel = "gemini-1.5-flash"
    let maxTokensDefault = 800

    func buildRequest(messages: [AIMessage], model: String?, maxTokens: Int?, temperature: Double?) -> AIProviderRequest {
        let parts = messages.map { msg -> [String: Any] in
            let role = msg.role == "assistant" ? "model" : (msg.role == "system" ? "user" : msg.role)
            return ["role": role, "parts": [["text": msg.content]]]
        }

        let body: [String: Any] = [
            "contents": parts,
            "generationConfig": [
                "maxOutputTokens": maxTokens ?? maxTokensDefault,
                "temperature": temperature ?? 0.7
            ]
        ]
        let data = try? JSONSerialization.data(withJSONObject: body)
        return AIProviderRequest(body: data, additionalHeaders: [:])
    }

    func parseResponse(data: Data) -> AIProviderResponse? {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let candidates = json["candidates"] as? [[String: Any]],
              let content = candidates.first?["content"] as? [String: Any],
              let parts = content["parts"] as? [[String: Any]],
              let text = parts.first?["text"] as? String else { return nil }

        let metadata = json["usageMetadata"] as? [String: Any]
        let tokens = metadata?["totalTokenCount"] as? Int

        return AIProviderResponse(
            content: text.trimmingCharacters(in: .whitespacesAndNewlines),
            model: nil,
            tokensUsed: tokens,
            finishReason: candidates.first?["finishReason"] as? String
        )
    }

    func authorizationHeader(for apiKey: String) -> (field: String, value: String) {
        // Gemini nutzt Query-Parameter, aber wir setzen trotzdem einen Header
        ("x-goog-api-key", apiKey)
    }

    func requestURL(model: String?, apiKey: String) -> String {
        let m = model ?? defaultModel
        return "\(baseURL)/\(m):generateContent?key=\(apiKey)"
    }
}

struct DeepSeekProvider: AIProvider {
    let identifier: AIProviderIdentifier = .deepSeek
    let displayName = "DeepSeek"
    let baseURL = "https://api.deepseek.com/chat/completions"
    let defaultModel = "deepseek-chat"
    let maxTokensDefault = 800

    func buildRequest(messages: [AIMessage], model: String?, maxTokens: Int?, temperature: Double?) -> AIProviderRequest {
        let body: [String: Any] = [
            "model": model ?? defaultModel,
            "messages": messages.map { ["role": $0.role, "content": $0.content] },
            "max_tokens": maxTokens ?? maxTokensDefault,
            "temperature": temperature ?? 0.7
        ]
        let data = try? JSONSerialization.data(withJSONObject: body)
        return AIProviderRequest(body: data, additionalHeaders: [:])
    }

    func parseResponse(data: Data) -> AIProviderResponse? {
        OpenAIProvider().parseResponse(data: data)
    }

    func authorizationHeader(for apiKey: String) -> (field: String, value: String) {
        ("Authorization", "Bearer \(apiKey)")
    }
}

struct GroqProvider: AIProvider {
    let identifier: AIProviderIdentifier = .groq
    let displayName = "Groq"
    let baseURL = "https://api.groq.com/openai/v1/chat/completions"
    let defaultModel = "llama-3.1-8b-instant"
    let maxTokensDefault = 800

    func buildRequest(messages: [AIMessage], model: String?, maxTokens: Int?, temperature: Double?) -> AIProviderRequest {
        let body: [String: Any] = [
            "model": model ?? defaultModel,
            "messages": messages.map { ["role": $0.role, "content": $0.content] },
            "max_tokens": maxTokens ?? maxTokensDefault,
            "temperature": temperature ?? 0.7
        ]
        let data = try? JSONSerialization.data(withJSONObject: body)
        return AIProviderRequest(body: data, additionalHeaders: [:])
    }

    func parseResponse(data: Data) -> AIProviderResponse? {
        OpenAIProvider().parseResponse(data: data)
    }

    func authorizationHeader(for apiKey: String) -> (field: String, value: String) {
        ("Authorization", "Bearer \(apiKey)")
    }
}

struct MistralProvider: AIProvider {
    let identifier: AIProviderIdentifier = .mistral
    let displayName = "Mistral"
    let baseURL = "https://api.mistral.ai/v1/chat/completions"
    let defaultModel = "mistral-small-latest"
    let maxTokensDefault = 800

    func buildRequest(messages: [AIMessage], model: String?, maxTokens: Int?, temperature: Double?) -> AIProviderRequest {
        let body: [String: Any] = [
            "model": model ?? defaultModel,
            "messages": messages.map { ["role": $0.role, "content": $0.content] },
            "max_tokens": maxTokens ?? maxTokensDefault,
            "temperature": temperature ?? 0.7
        ]
        let data = try? JSONSerialization.data(withJSONObject: body)
        return AIProviderRequest(body: data, additionalHeaders: [:])
    }

    func parseResponse(data: Data) -> AIProviderResponse? {
        OpenAIProvider().parseResponse(data: data)
    }

    func authorizationHeader(for apiKey: String) -> (field: String, value: String) {
        ("Authorization", "Bearer \(apiKey)")
    }
}

// MARK: - AI Provider Manager

final class AIProviderManager {
    static let shared = AIProviderManager()

    private let providers: [AIProviderIdentifier: AIProvider] = [
        .openAI: OpenAIProvider(),
        .openRouter: OpenRouterProvider(),
        .claude: ClaudeProvider(),
        .gemini: GeminiProvider(),
        .deepSeek: DeepSeekProvider(),
        .groq: GroqProvider(),
        .mistral: MistralProvider()
    ]

    private var configurations: [AIProviderIdentifier: ProviderConfiguration] = [:]
    private let session: URLSession
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "MyFlashcard", category: "AIProviderManager")
    private var secretChangeObserver: NSObjectProtocol?

    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        self.session = URLSession(configuration: config)
        AIProviderConfiguration.bootstrapStoredSecrets()
        loadConfigurations()
        secretChangeObserver = NotificationCenter.default.addObserver(
            forName: .aiProviderSecretsDidChange,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.reloadKeys()
        }
    }

    // MARK: - Configuration Loading

    private func loadConfigurations() {
        configurations.removeAll()

        for configEntry in AIProviderConfiguration.providerConfigs {
            let id = configEntry.provider
            let keys = AIProviderConfiguration.keys(for: id)
            let config = ProviderConfiguration(
                identifier: id,
                priority: configEntry.priority,
                isEnabled: configEntry.isEnabled && !keys.isEmpty,
                keys: keys.map { APIKeyState(key: $0) },
                health: ProviderHealth()
            )
            configurations[id] = config
        }

        logConfigurationState(reason: "load")
    }

    private func logConfigurationState(reason: String) {
        let summary = configurations
            .sorted { $0.key.rawValue < $1.key.rawValue }
            .map { id, config in
                "\(id.rawValue):enabled=\(config.isEnabled) keys=\(config.keys.count) available=\(config.hasAvailableKeys)"
            }
            .joined(separator: " | ")

        logger.debug("ai_config reason=\(reason, privacy: .public) \(summary, privacy: .public)")
    }

    // MARK: - Public API

    /// Hauptmethode: Sendet Nachricht mit automatischem Failover
    func sendMessage(
        messages: [AIMessage],
        preferredProvider: AIProviderIdentifier? = nil,
        model: String? = nil,
        maxTokens: Int? = nil,
        temperature: Double? = nil
    ) async throws -> AIProviderResponse {
        var sortedProviders = sortedAvailableProviders(preferred: preferredProvider)

        // Falls keine Provider verfuegbar sind: einmal frisch aus Keychain/Info.plist
        // neu laden, bevor wir aufgeben. Deckt den Fall ab, dass ein API-Key erst
        // nach dem App-Start gespeichert wurde, ohne dass reloadKeys() aufgerufen wurde.
        if sortedProviders.isEmpty {
            reloadKeys()
            sortedProviders = sortedAvailableProviders(preferred: preferredProvider)
        }

        guard !sortedProviders.isEmpty else {
            throw AIProviderError.noAvailableProvider
        }

        var lastError: Error = AIProviderError.noAvailableProvider

        for providerID in sortedProviders {
            guard var config = configurations[providerID],
                  let provider = providers[providerID] else { continue }

            // Proaktiv pruefen: Budget bei >= 80% → ueberspringen
            if config.health.budgetUsagePercent >= 80 && sortedProviders.count > 1 {
                continue
            }

            // Alle verfuegbaren Keys durchprobieren
            while let apiKey = config.nextAvailableKey() {
                do {
                    let result = try await executeRequest(
                        provider: provider,
                        config: &config,
                        apiKey: apiKey,
                        messages: messages,
                        model: model,
                        maxTokens: maxTokens,
                        temperature: temperature
                    )
                    // Erfolg: Config speichern
                    configurations[providerID] = config
                    return result
                } catch let error as AIProviderError {
                    switch error {
                    case .rateLimited(let retryAfter):
                        let cooldown = retryAfter ?? 60
                        config.markKeyFailed(key: apiKey, cooldown: cooldown)
                        configurations[providerID] = config
                        lastError = error
                        continue // Naechster Key
                    case .timeout, .networkError:
                        config.markKeyFailed(key: apiKey, cooldown: 30)
                        configurations[providerID] = config
                        lastError = error
                        continue
                    case .authenticationFailed:
                        config.markKeyFailed(key: apiKey, cooldown: 300) // 5 Min Cooldown
                        configurations[providerID] = config
                        lastError = error
                        continue
                    default:
                        config.markKeyFailed(key: apiKey, cooldown: 30)
                        configurations[providerID] = config
                        lastError = error
                        continue
                    }
                } catch {
                    config.markKeyFailed(key: apiKey, cooldown: 30)
                    configurations[providerID] = config
                    lastError = error
                    continue
                }
            }
            // Alle Keys dieses Providers erschoepft → naechster Provider
            configurations[providerID] = config
        }

        throw lastError
    }

    // MARK: - Request Execution

    private func executeRequest(
        provider: AIProvider,
        config: inout ProviderConfiguration,
        apiKey: String,
        messages: [AIMessage],
        model: String?,
        maxTokens: Int?,
        temperature: Double?
    ) async throws -> AIProviderResponse {
        let req = provider.buildRequest(messages: messages, model: model, maxTokens: maxTokens, temperature: temperature)

        // URL bestimmen
        let urlString: String
        if let gemini = provider as? GeminiProvider {
            urlString = gemini.requestURL(model: model, apiKey: apiKey)
        } else {
            urlString = provider.baseURL
        }

        guard let url = URL(string: urlString) else {
            throw AIProviderError.networkError(URLError(.badURL))
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = req.body
        request.timeoutInterval = 30

        // Auth Header (Gemini nutzt Query-Param, trotzdem fuer Konsistenz)
        if !(provider is GeminiProvider) {
            let auth = provider.authorizationHeader(for: apiKey)
            request.setValue(auth.value, forHTTPHeaderField: auth.field)
        }

        // Zusaetzliche Provider-spezifische Headers
        for (field, value) in req.additionalHeaders {
            request.setValue(value, forHTTPHeaderField: field)
        }

        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await session.data(for: request)
        } catch let error as URLError where error.code == .timedOut {
            throw AIProviderError.timeout
        } catch {
            throw AIProviderError.networkError(error)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw AIProviderError.networkError(URLError(.badServerResponse))
        }

        // Rate-Limit-Header auswerten
        updateRateLimitInfo(from: httpResponse, config: &config)

        switch httpResponse.statusCode {
        case 200..<300:
            guard let parsed = provider.parseResponse(data: data) else {
                throw AIProviderError.invalidResponse(statusCode: httpResponse.statusCode)
            }
            config.markKeySuccess(key: apiKey, tokensUsed: parsed.tokensUsed ?? 0)
            return AIProviderResponse(
                content: parsed.content,
                model: parsed.model,
                tokensUsed: parsed.tokensUsed,
                finishReason: parsed.finishReason,
                provider: provider.identifier
            )

        case 401, 403:
            throw AIProviderError.authenticationFailed

        case 429:
            let retryAfter = httpResponse.value(forHTTPHeaderField: "Retry-After")
                .flatMap { TimeInterval($0) }
            throw AIProviderError.rateLimited(retryAfter: retryAfter)

        case 500..<600:
            throw AIProviderError.invalidResponse(statusCode: httpResponse.statusCode)

        default:
            throw AIProviderError.invalidResponse(statusCode: httpResponse.statusCode)
        }
    }

    // MARK: - Rate Limit Monitoring

    private func updateRateLimitInfo(from response: HTTPURLResponse, config: inout ProviderConfiguration) {
        // OpenAI/Standard Headers
        if let remaining = response.value(forHTTPHeaderField: "x-ratelimit-remaining-requests") {
            config.health.rateLimitRemaining = Int(remaining)
        }
        if let reset = response.value(forHTTPHeaderField: "x-ratelimit-reset-requests") {
            // Parse ISO timestamp oder Sekunden
            if let seconds = TimeInterval(reset) {
                config.health.rateLimitResetDate = Date().addingTimeInterval(seconds)
            }
        }
    }

    // MARK: - Provider Sorting

    private func sortedAvailableProviders(preferred: AIProviderIdentifier?) -> [AIProviderIdentifier] {
        // Wichtig: Ein Provider mit gueltigem, verfuegbarem Key darf NIE allein wegen
        // eines veralteten/fehlgeschlagenen Health-Checks ausgeschlossen werden.
        // Der Health-Status dient nur zur Priorisierung (bessere Provider zuerst),
        // nicht als hartes Ausschlusskriterium - sonst kann ein einzelner
        // fehlgeschlagener Health-Check (z.B. Cold-Start ohne Netzwerk) den Provider
        // dauerhaft sperren, obwohl der eigentliche Chat-Request funktionieren wuerde.
        var available = configurations
        .filter { $0.value.isEnabled && $0.value.hasAvailableKeys }
        .sorted { lhs, rhs in
            if lhs.value.priority != rhs.value.priority {
                return lhs.value.priority < rhs.value.priority
            }
            // Bei gleicher Prioritaet: gesunde Provider zuerst, aber nichts ausschliessen
            return lhs.value.health.isHealthy && !rhs.value.health.isHealthy
        }
        .map { $0.key }

        // Bevorzugten Provider nach vorne
        if let preferred, available.contains(preferred) {
            available.removeAll { $0 == preferred }
            available.insert(preferred, at: 0)
        }

        return available
    }

    // MARK: - Health Check

    /// Fuehrt Health-Check fuer alle konfigurierten Provider durch
    func performHealthChecks() async -> [AIProviderIdentifier: ProviderHealth] {
        var results: [AIProviderIdentifier: ProviderHealth] = [:]

        await withTaskGroup(of: (AIProviderIdentifier, ProviderHealth).self) { group in
            for (id, config) in configurations where config.isEnabled {
                group.addTask { [weak self] in
                    guard let self else { return (id, ProviderHealth()) }
                    let health = await self.checkProvider(id)
                    return (id, health)
                }
            }

            for await (id, health) in group {
                results[id] = health
                configurations[id]?.health = health
            }
        }

        return results
    }

    private func checkProvider(_ id: AIProviderIdentifier) async -> ProviderHealth {
        var health = ProviderHealth()
        health.lastChecked = Date()

        guard let provider = providers[id],
              var config = configurations[id],
              let apiKey = config.nextAvailableKey() else {
            health.isAvailable = false
            return health
        }
        // Config zuruecksetzen (nextAvailableKey hat Index veraendert)
        configurations[id] = config

        let testMessages = [
            AIMessage(role: "user", content: "Antworte mit OK")
        ]

        let startTime = Date()
        do {
            let response = try await executeRequest(
                provider: provider,
                config: &config,
                apiKey: apiKey,
                messages: testMessages,
                model: nil,
                maxTokens: 10,
                temperature: 0
            )
            configurations[id] = config
            health.isAvailable = true
            health.latencyMs = Int(Date().timeIntervalSince(startTime) * 1000)
            health.consecutiveFailures = 0
            // Antwort validieren
            if response.content.isEmpty {
                health.isAvailable = false
            }
        } catch {
            health.isAvailable = false
            health.consecutiveFailures += 1
        }

        return health
    }

    // MARK: - Token Optimization

    /// Komprimiert Chat-Historie fuer Token-Effizienz
    static func optimizeMessages(_ messages: [AIMessage], maxMessages: Int = 10, maxTokenEstimate: Int = 3000) -> [AIMessage] {
        guard messages.count > 1 else { return messages }

        var result: [AIMessage] = []

        // System-Prompt immer behalten
        if let system = messages.first(where: { $0.role == "system" }) {
            result.append(system)
        }

        // Letzte N Nachrichten behalten
        let nonSystem = messages.filter { $0.role != "system" }
        let recentMessages = Array(nonSystem.suffix(maxMessages))

        // Token-Schaetzung (ca. 4 Zeichen pro Token)
        var estimatedTokens = result.reduce(0) { $0 + $1.content.count / 4 }

        for msg in recentMessages {
            let msgTokens = msg.content.count / 4
            if estimatedTokens + msgTokens > maxTokenEstimate {
                // Zusammenfassung einfuegen statt alte Nachrichten
                if result.count == 1 { // Nur System-Prompt bisher
                    result.append(AIMessage(role: "system", content: "[Vorherige Konversation zusammengefasst: Der Nutzer lernt Englisch und hat verschiedene Fragen gestellt.]"))
                }
                // Nur die letzten 4 Nachrichten erzwingen
                let forced = Array(recentMessages.suffix(4))
                result.append(contentsOf: forced)
                break
            }
            estimatedTokens += msgTokens
            result.append(msg)
        }

        return result.isEmpty ? messages : result
    }

    // MARK: - Public Accessors

    var availableProviders: [AIProviderIdentifier] {
        configurations.filter { $0.value.isEnabled && $0.value.hasAvailableKeys }.map { $0.key }
    }

    var activeProviderCount: Int {
        availableProviders.count
    }

    func healthStatus(for provider: AIProviderIdentifier) -> ProviderHealth? {
        configurations[provider]?.health
    }

    /// Manuell einen API-Key fuer einen Provider hinzufuegen
    func addKey(_ key: String, for provider: AIProviderIdentifier) {
        guard !key.isEmpty else { return }
        if let plistKeyName = AIProviderConfiguration.plistKeyNames[provider] {
            do {
                try KeychainService.shared.save(key, for: plistKeyName)
            } catch {
                logger.error("save_key_failed provider=\(provider.rawValue, privacy: .public) error=\(error.localizedDescription, privacy: .public)")
            }
        }
        if configurations[provider] == nil {
            configurations[provider] = ProviderConfiguration(
                identifier: provider,
                priority: 999,
                isEnabled: true,
                keys: [],
                health: ProviderHealth()
            )
        }
        configurations[provider]?.keys.append(APIKeyState(key: key))
        configurations[provider]?.isEnabled = true
    }

    /// Keys aus Keychain und Info.plist neu laden
    func reloadKeys() {
        loadConfigurations()
    }
}