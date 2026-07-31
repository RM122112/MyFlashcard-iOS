import SwiftUI
import NaturalLanguage
import os

// MARK: - Modes

enum AIChatMode: String, CaseIterable, Identifiable {
    case chat = "Chat"
    case grammar = "Grammatik"
    case improve = "Stil verbessern"
    case analyze = "Analysieren"
    case translate = "Übersetzen"
    case professional = "Professionell schreiben"
    case vocabulary = "Wortschatz"

    var id: String { rawValue }

    var shortLabel: String {
        switch self {
        case .professional: return "Pro"
        default: return rawValue
        }
    }

    var placeholder: String {
        switch self {
        case .chat: return "Stelle eine Frage ..."
        case .grammar: return "Füge einen Text zur Grammatikprüfung ein ..."
        case .improve: return "Füge einen Text zur stilistischen Verbesserung ein ..."
        case .analyze: return "Füge einen Text zur Analyse ein ..."
        case .translate: return "Gib Text für die Übersetzung ein ..."
        case .professional: return "Schreibe deinen Entwurf für eine professionelle Formulierung ..."
        case .vocabulary: return "Frage nach Bedeutung, Synonymen oder Verwendung ..."
        }
    }
}

struct AIChatMessage: Identifiable {
    let id = UUID()
    let isUser: Bool
    let text: String
    let timestamp: Date = Date()
}

// MARK: - Intent + Language

enum DetectedLanguage {
    case english
    case nonEnglish
    case unknown
}

private struct AIIntentDecision {
    let mode: AIChatMode
    let inputForModel: String
}

private final class AIIntentRouter {
    private let grammarTriggers = [
        "correct grammar", "grammar check", "check grammar", "fix grammar", "grammar correction"
    ]

    private let translationPatterns: [NSRegularExpression] = [
        // German word-order: "Wie kann ich auf Englisch sagen ich habe Durst"
        try! NSRegularExpression(pattern: "(?i)wie kann ich auf\\s+(?:englisch|deutsch|persisch|dari|französisch|arabisch|spanisch)\\s+sagen\\s+['\u{201E}\u{2018}]?(.+?)['\u{201C}\u{201D}\u{2019}]?\\s*$"),
        // German word-order: "Übersetze auf Englisch 'ich habe Durst'"
        try! NSRegularExpression(pattern: "(?i)übersetze\\s+auf\\s+(?:englisch|deutsch|persisch|dari|französisch|arabisch|spanisch)\\s+['\u{201E}\u{2018}]?(.+?)['\u{201C}\u{201D}\u{2019}]?\\s*$"),
        try! NSRegularExpression(pattern: "(?i)wie sagt man\\s+(.+?)\\s+auf englisch\\??\\s*$"),
        try! NSRegularExpression(pattern: "(?i)was heißt\\s+(.+?)\\s+auf englisch\\??\\s*$"),
        try! NSRegularExpression(pattern: "(?i)(.+?)\\s+auf englisch sagen\\??\\s*$"),
        try! NSRegularExpression(pattern: "(?i)translate\\s+(.+?)\\s+to english\\??\\s*$"),
        try! NSRegularExpression(pattern: "(?i)how do you say\\s+(.+?)\\s+in english\\??\\s*$"),
        try! NSRegularExpression(pattern: "(?i)how can i say\\s+(.+?)(?:\\s+in english)?\\??\\s*$"),
        try! NSRegularExpression(pattern: "(?i)übersetze\\s+(.+?)\\s+ins englische\\??\\s*$"),
        try! NSRegularExpression(pattern: "(?i)(.+?)\\s+wie kann ich (?:es|das|diesen satz)?\\s*auf englisch sagen\\??\\s*$"),
        try! NSRegularExpression(pattern: "(?i)wie heißt\\s+(.+?)\\s+auf\\s+(englisch|deutsch|persisch|dari|französisch|arabisch|spanisch)\\??\\s*$"),
        try! NSRegularExpression(pattern: "(?i)übersetze\\s+(.+?)\\s+auf\\s+(englisch|deutsch|persisch|dari|französisch|arabisch|spanisch)\\??\\s*$"),
        try! NSRegularExpression(pattern: "(?i)translate\\s+(.+?)\\s+to\\s+(english|german|persian|farsi|dari|french|arabic|spanish)\\??\\s*$")
    ]

    private let translationKeywords = [
        "übersetze", "übersetzen", "translate", "translation", "wie heißt", "wie sagt man",
        "auf englisch", "auf deutsch", "auf persisch", "auf dari", "auf französisch",
        "auf arabisch", "auf spanisch", "to english", "to german", "to persian", "to farsi",
        "to dari", "to french", "to arabic", "to spanish"
    ]

    /// Small-Talk-Phrasen die NICHT als Uebersetzung/Analyse behandelt werden sollen
    private let smallTalkPhrases: Set<String> = [
        "wie geht es dir", "wie gehts", "wie geht's", "wie geht es",
        "na wie gehts", "hallo", "hi", "hey", "moin",
        "guten tag", "guten morgen", "guten abend", "gute nacht",
        "danke", "vielen dank", "dankeschoen", "tschuess", "tschüss",
        "bye", "auf wiedersehen", "bis bald", "ciao",
        "ja", "nein", "ok", "okay", "alles klar",
        "was kannst du", "hilfe",
        "how are you", "hello", "good morning", "good evening",
        "good night", "thank you", "thanks", "bye", "goodbye",
        "what's up", "whats up"
    ]

    func route(userInput: String, selectedMode: AIChatMode) -> AIIntentDecision {
        let trimmed = userInput.trimmingCharacters(in: .whitespacesAndNewlines)

        // Small Talk immer als Chat behandeln
        if isSmallTalk(trimmed) {
            return AIIntentDecision(mode: .chat, inputForModel: trimmed)
        }

        let language = detectLanguage(trimmed)

        if selectedMode == .translate || isTranslationRequest(trimmed) {
            return AIIntentDecision(mode: .translate, inputForModel: buildTranslationInput(from: trimmed))
        }

        let lower = trimmed.lowercased()
        let explicitGrammar = grammarTriggers.contains { lower.contains($0) }
        if explicitGrammar && language == .english {
            return AIIntentDecision(mode: .grammar, inputForModel: extractGrammarPayload(trimmed))
        }

        if selectedMode == .grammar && language != .english {
            return AIIntentDecision(mode: .chat, inputForModel: trimmed)
        }

        return AIIntentDecision(mode: selectedMode, inputForModel: trimmed)
    }

    private func isSmallTalk(_ input: String) -> Bool {
        let cleaned = input.lowercased()
            .trimmingCharacters(in: CharacterSet(charactersIn: " ?!.,;:"))
        if smallTalkPhrases.contains(cleaned) { return true }
        // Persische Gruesse
        let persianGreetings = ["سلام", "درود", "خوبم", "ممنون", "مرسی", "چطوری", "حالت چطوره"]
        for greeting in persianGreetings {
            if input.contains(greeting) { return true }
        }
        return false
    }

    private func detectLanguage(_ text: String) -> DetectedLanguage {
        if text.isEmpty { return .unknown }
        let recognizer = NLLanguageRecognizer()
        recognizer.processString(text)
        switch recognizer.dominantLanguage {
        case .english?: return .english
        case nil: return .unknown
        default: return .nonEnglish
        }
    }

    private func extractTranslationPayload(from input: String) -> String? {
        let nsInput = input as NSString
        for pattern in translationPatterns {
            let fullRange = NSRange(location: 0, length: nsInput.length)
            guard let match = pattern.firstMatch(in: input, range: fullRange), match.numberOfRanges > 1 else { continue }
            let captured = nsInput.substring(with: match.range(at: 1)).cleanedPayload()
            if !captured.isEmpty { return captured }
        }

        let lower = input.lowercased()
        if lower.contains("auf englisch") || lower.contains("to english") || lower.contains("ins englische") {
            let cleaned = input
                .replacingOccurrences(of: "(?i)wie sagt man", with: "", options: .regularExpression)
                .replacingOccurrences(of: "(?i)was heißt", with: "", options: .regularExpression)
                .replacingOccurrences(of: "(?i)translate", with: "", options: .regularExpression)
                .replacingOccurrences(of: "(?i)how do you say", with: "", options: .regularExpression)
                .replacingOccurrences(of: "(?i)übersetze", with: "", options: .regularExpression)
                .replacingOccurrences(of: "(?i)auf englisch sagen", with: "", options: .regularExpression)
                .replacingOccurrences(of: "(?i)auf englisch", with: "", options: .regularExpression)
                .replacingOccurrences(of: "(?i)to english", with: "", options: .regularExpression)
                .replacingOccurrences(of: "(?i)ins englische", with: "", options: .regularExpression)
                .cleanedPayload()
            return cleaned.isEmpty ? nil : cleaned
        }

        return nil
    }

    private func isTranslationRequest(_ input: String) -> Bool {
        if extractTranslationPayload(from: input) != nil {
            return true
        }
        let lower = input.lowercased()
        return translationKeywords.contains(where: { lower.contains($0) })
    }

    /// Detects the target language mentioned in the user's request.
    private func extractTargetLanguage(from input: String) -> String? {
        let lower = input.lowercased()
        if lower.contains("auf englisch") || lower.contains("ins englische") || lower.contains("to english") { return "English" }
        if lower.contains("auf deutsch") || lower.contains("ins deutsche") || lower.contains("to german") { return "German" }
        if lower.contains("auf persisch") || lower.contains("auf dari") || lower.contains("to persian") || lower.contains("to farsi") || lower.contains("to dari") { return "Persian/Farsi" }
        if lower.contains("auf französisch") || lower.contains("to french") { return "French" }
        if lower.contains("auf arabisch") || lower.contains("to arabic") { return "Arabic" }
        if lower.contains("auf spanisch") || lower.contains("to spanish") { return "Spanish" }
        return nil
    }

    private func buildTranslationInput(from input: String) -> String {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        let targetLanguage = extractTargetLanguage(from: trimmed)
        let payload = extractTranslationPayload(from: trimmed)

        if let payload = payload, !payload.isEmpty, let lang = targetLanguage {
            // Explicit, unambiguous instruction: AI always knows source text AND target language.
            return "Translate to \(lang): \"\(payload)\""
        } else if let payload = payload, !payload.isEmpty {
            return payload
        } else if let lang = targetLanguage {
            // Couldn't isolate the exact payload — pass the full request with the explicit language.
            return "Translate the following request to \(lang): \(trimmed)"
        }
        return trimmed
    }

    private func extractGrammarPayload(_ input: String) -> String {
        if let idx = input.firstIndex(of: ":") {
            let after = String(input[input.index(after: idx)...]).trimmingCharacters(in: .whitespaces)
            if !after.isEmpty { return after }
        }

        return input
            .replacingOccurrences(of: "(?i)correct grammar", with: "", options: .regularExpression)
            .replacingOccurrences(of: "(?i)grammar check", with: "", options: .regularExpression)
            .replacingOccurrences(of: "(?i)check grammar", with: "", options: .regularExpression)
            .replacingOccurrences(of: "(?i)fix grammar", with: "", options: .regularExpression)
            .replacingOccurrences(of: "(?i)grammar correction", with: "", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

private extension String {
    func cleanedPayload() -> String {
        trimmingCharacters(in: CharacterSet(charactersIn: " \n\t\"'„“”?!.,:;"))
    }
}

struct DictionaryExample: Codable, Hashable {
    let source: String
    let translation: String
}

struct DictionaryLookup: Codable, Hashable {
    let query: String
    let normalizedQuery: String
    let sourceName: String
    let sourceURL: String
    let description: String
    let translations: [String]
    let synonyms: [String]
    let examples: [DictionaryExample]
    let primaryPartOfSpeech: String?
    let cachedAt: Date
    let expiresAt: Date
    let fromCache: Bool
    let isStale: Bool

    var summaryText: String {
        var lines: [String] = []
        if !translations.isEmpty {
            lines.append(translations.joined(separator: " • "))
        }
        if !description.isEmpty {
            lines.append(description)
        }
        return lines.joined(separator: "\n")
    }

    func withCacheFlags(fromCache: Bool, isStale: Bool) -> DictionaryLookup {
        DictionaryLookup(
            query: query,
            normalizedQuery: normalizedQuery,
            sourceName: sourceName,
            sourceURL: sourceURL,
            description: description,
            translations: translations,
            synonyms: synonyms,
            examples: examples,
            primaryPartOfSpeech: primaryPartOfSpeech,
            cachedAt: cachedAt,
            expiresAt: expiresAt,
            fromCache: fromCache,
            isStale: isStale
        )
    }

    func withExpiry(_ ttl: TimeInterval) -> DictionaryLookup {
        let now = Date()
        return DictionaryLookup(
            query: query,
            normalizedQuery: normalizedQuery,
            sourceName: sourceName,
            sourceURL: sourceURL,
            description: description,
            translations: translations,
            synonyms: synonyms,
            examples: examples,
            primaryPartOfSpeech: primaryPartOfSpeech,
            cachedAt: now,
            expiresAt: now.addingTimeInterval(ttl),
            fromCache: false,
            isStale: false
        )
    }
}

// MARK: - Online AI Repository

private struct AIRepositoryResult {
    let response: String
    let mode: AIChatMode
    let recommendedTopics: [String]
}

private final class AIConversationMemory {
    private var messages: [AIChatMessage] = []
    private let maxMessages = 30

    func add(_ message: AIChatMessage) {
        messages.append(message)
        if messages.count > maxMessages {
            messages.removeFirst(messages.count - maxMessages)
        }
    }

    func all() -> [AIChatMessage] { messages }

    func clear() { messages.removeAll() }
}

private final class GrammarTopicRecommender {
    func recommendTopics(from input: String, limit: Int = 3) -> [String] {
        let patterns: [(String, [String])] = [
            ("Tenses", ["yesterday", "already", "since", "for", "have", "had", "will"]),
            ("Articles", [" a ", " an ", " the "]),
            ("Pronouns", [" i ", " me ", " she ", " he ", " they ", " them ", " my ", " your "]),
            ("Prepositions", [" in ", " on ", " at ", " by ", " with ", " to ", " for "]),
            ("Passive Voice", [" was ", " were ", " been ", " by "]),
            ("Conditionals", ["if ", "would", "could", "might"]),
            ("Reported Speech", ["said", "told", "asked"]),
            ("Modal Verbs", ["can", "could", "may", "might", "must", "should"]),
            ("Questions", ["?", "why", "what", "how"]),
            ("Negation", ["not", "don't", "doesn't", "didn't", "never"])
        ]

        let lower = " " + input.lowercased() + " "
        return patterns
            .map { topic, tokens in
                let score = tokens.reduce(0) { $0 + (lower.contains($1.lowercased()) ? 1 : 0) }
                return (topic, score)
            }
            .filter { $0.1 > 0 }
            .sorted { $0.1 > $1.1 }
            .map { $0.0 }
            .prefix(limit)
            .map { $0 }
    }
}

private final class AIChatRepository {
    private let router = AIIntentRouter()
    private let memory = AIConversationMemory()
    private let recommender = GrammarTopicRecommender()
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "MyFlashcard", category: "AIChatRepository")

    func sendMessage(userInput: String, selectedMode: AIChatMode) async throws -> AIRepositoryResult {
        let decision = router.route(userInput: userInput, selectedMode: selectedMode)
        memory.add(AIChatMessage(isUser: true, text: userInput))

        let response = try await requestOnlineResponse(input: decision.inputForModel, mode: decision.mode)
        let topics = decision.mode == .grammar ? recommender.recommendTopics(from: decision.inputForModel) : []
        let finalResponse = response

        let assistant = AIChatMessage(isUser: false, text: finalResponse)
        memory.add(assistant)

        return AIRepositoryResult(
            response: finalResponse,
            mode: decision.mode,
            recommendedTopics: topics
        )
    }

    private func requestOnlineResponse(input: String, mode: AIChatMode) async throws -> String {
        let manager = AIProviderManager.shared
        manager.reloadKeys()
        guard manager.activeProviderCount > 0 else {
            throw AIProviderError.noAvailableProvider
        }

        let systemPrompt = buildSystemPrompt(for: mode)
        let messages = AIProviderManager.optimizeMessages([
            AIMessage(role: "system", content: systemPrompt),
            AIMessage(role: "user", content: input)
        ])

        let maxAttempts = 3
        var delayNs: UInt64 = 500_000_000
        var lastError: Error?

        for attempt in 1...maxAttempts {
            let startedAt = Date()
            do {
                let response = try await manager.sendMessage(
                    messages: messages,
                    preferredProvider: nil,
                    model: nil,
                    maxTokens: 800,
                    temperature: 0.7
                )

                let latencyMs = Int(Date().timeIntervalSince(startedAt) * 1000)
                logger.info(
                    "ai_success provider=\(response.provider?.rawValue ?? "unknown", privacy: .public) model=\(response.model ?? "unknown", privacy: .public) latency_ms=\(latencyMs) tokens=\(response.tokensUsed ?? -1)"
                )

                let content = response.content.trimmingCharacters(in: .whitespacesAndNewlines)
                if !content.isEmpty { return content }
                lastError = AIProviderError.invalidResponse(statusCode: -1)
            } catch {
                let latencyMs = Int(Date().timeIntervalSince(startedAt) * 1000)
                logger.error("ai_failure attempt=\(attempt) latency_ms=\(latencyMs) error=\(error.localizedDescription, privacy: .public)")
                lastError = error
                if attempt < maxAttempts, shouldRetry(error) {
                    try? await Task.sleep(nanoseconds: delayNs)
                    delayNs *= 2
                    continue
                }
                break
            }
        }

        if let lastError {
            throw lastError
        }
        throw AIProviderError.allProvidersFailed
    }

    private func shouldRetry(_ error: Error) -> Bool {
        guard let providerError = error as? AIProviderError else { return true }
        switch providerError {
        case .timeout, .networkError, .rateLimited, .invalidResponse:
            return true
        case .noAvailableProvider, .authenticationFailed, .allKeysExhausted, .allProvidersFailed:
            return false
        }
    }

    private func buildSystemPrompt(for mode: AIChatMode) -> String {
        switch mode {
        case .grammar:
            return """
            You are an English grammar tutor for a Persian-speaking learner.
            Rules:
            - Correct the user's text and explain mistakes briefly in German and Persian.
            - Mark errors with → correction format.
            - Give max 1 sentence explanation per error.
            - If the text has no errors, confirm it's correct.
            """
        case .translate:
            return """
            You are a professional multilingual translator.
            Always provide natural, grammatically correct translations.
            Detect source and target language from the user request (German, English, Persian/Farsi, Dari, French, Arabic, Spanish).
            If multiple translations are possible, show the most natural one first, followed by alternatives and a short explanation.
            Never respond with dictionary URLs or external links.
            Output must always follow exactly this structure:

            **Übersetzung**
            <best translation>

            **Alternative Formulierungen**
            - <alternative 1>
            - <alternative 2>
            - <alternative 3>

            **Erklärung**
            <short explanation why the best translation is the most natural in context>
            """
        case .improve:
            return "Improve the style of this English text. Respond in German with the improved version and 2-3 short tips. Keep it concise."
        case .analyze:
            return "Analyze the following English text linguistically. Respond in German with word count, CEFR estimate, and issues. Be concise (max 4 sentences)."
        case .professional:
            return "Rewrite this text in a professional, formal English tone. Keep it concise and clear, no slang."
        case .vocabulary:
            return """
            You are a vocabulary coach for a Persian-speaking English learner.
            For the given word/phrase, provide:
            - Meaning in German and Persian (فارسی)
            - 2-3 synonyms
            - 1 example sentence
            - CEFR level estimate
            Keep it concise (max 3-4 lines).
            """
        case .chat:
            return """
            Du bist ein personalisierter Englisch-Lerncoach fuer einen persischsprachigen Lerner.

            Kernregeln:
            1. SPRACHE: Erklaere auf Deutsch. Bei Bedarf ergaenze auf Persisch (فارسی).
            2. KUERZE: Antworte in maximal 3-4 Saetzen.
            3. KONVERSATION: Bei Small Talk (Begruessungen, alltaegliche Fragen) antworte natuerlich und freundlich - KEINE Sprachanalyse, KEINE Grammatikkorrektur.
            4. VOKABULAR: Fuehre maximal 2-3 neue Woerter pro Antwort ein.
            5. Sei warm, ermutigend und hilfreich.

            Beispiele fuer natuerliche Antworten:
            - "Wie geht es dir?" → "Mir geht es gut, danke! Wie geht es dir? Bist du bereit zum Lernen?"
            - "Hallo" → "Hallo! Schoen, dass du da bist. Was moechtest du heute lernen?"
            - "سلام" → "سلام! حالت چطوره؟ امروز چی میخوای یاد بگیری?"
            """
        }
    }

    func history() -> [AIChatMessage] { memory.all() }

    func clearHistory() { memory.clear() }
}

// MARK: - ViewModel

@MainActor
final class AIChatViewModel: ObservableObject {
    @Published var selectedMode: AIChatMode = .chat
    @Published var messages: [AIChatMessage] = []
    @Published var inputText: String = ""
    @Published var isLoading: Bool = false
    @Published var showModeSheet: Bool = false
    @Published var showErrorAlert: Bool = false
    @Published var errorMessage: String = ""

    private let repository = AIChatRepository()

    func sendMessage() {
        let trimmed = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !isLoading else { return }

        withAnimation(.spring(response: 0.28, dampingFraction: 0.85)) {
            messages.append(AIChatMessage(isUser: true, text: trimmed))
            inputText = ""
            isLoading = true
        }

        Task {
            do {
                let result = try await repository.sendMessage(userInput: trimmed, selectedMode: selectedMode)
                if !result.recommendedTopics.isEmpty {
                    GrammarRecommendationStore.shared.setTopics(result.recommendedTopics)
                }

                withAnimation(.spring(response: 0.32, dampingFraction: 0.9)) {
                    messages.append(AIChatMessage(isUser: false, text: result.response))
                    isLoading = false
                }
            } catch {
                errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
                showErrorAlert = true
                isLoading = false
            }
        }
    }

    func clear() {
        withAnimation(.easeInOut(duration: 0.2)) {
            messages.removeAll()
        }
        repository.clearHistory()
    }
}

// MARK: - View

struct AIChatView: View {
    @StateObject private var viewModel = AIChatViewModel()

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if viewModel.messages.isEmpty {
                    ContentUnavailableView(
                        "KI-Chat",
                        systemImage: "sparkles",
                        description: Text("Chatten, Grammatik prüfen, Texte verbessern, analysieren, übersetzen und Wortschatz trainieren")
                    )
                    .frame(maxHeight: .infinity)
                } else {
                    ScrollViewReader { proxy in
                        ScrollView {
                            LazyVStack(spacing: 10) {
                                ForEach(viewModel.messages) { msg in
                                    MessageRow(message: msg)
                                        .id(msg.id)
                                        .transition(.move(edge: msg.isUser ? .trailing : .leading).combined(with: .opacity))
                                }
                                if viewModel.isLoading {
                                    HStack {
                                        ProgressView()
                                        Text("Die KI denkt nach ...")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                        Spacer()
                                    }
                                    .padding(.horizontal)
                                }
                            }
                            .padding(.horizontal)
                            .padding(.vertical, 8)
                        }
                        .onChange(of: viewModel.messages.count) { _, _ in
                            if let last = viewModel.messages.last {
                                withAnimation(.easeOut(duration: 0.25)) {
                                    proxy.scrollTo(last.id, anchor: .bottom)
                                }
                            }
                        }
                    }
                }

                Divider()

                VStack(spacing: 8) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(AIChatMode.allCases.prefix(4)) { mode in
                                ModeChip(mode: mode, isSelected: viewModel.selectedMode == mode) {
                                    withAnimation(.easeInOut(duration: 0.2)) { viewModel.selectedMode = mode }
                                }
                            }

                            Button {
                                viewModel.showModeSheet = true
                            } label: {
                                Label("Mehr", systemImage: "chevron.down")
                                    .font(.caption)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(Color.secondary.opacity(0.15))
                                    .clipShape(Capsule())
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.horizontal)
                    }

                    HStack(alignment: .bottom, spacing: 8) {
                        TextField(viewModel.selectedMode.placeholder, text: $viewModel.inputText, axis: .vertical)
                            .textFieldStyle(.plain)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            .background(Color(uiColor: .secondarySystemBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .lineLimit(1...5)

                        Button {
                            viewModel.sendMessage()
                        } label: {
                            ZStack {
                                Circle()
                                    .fill(viewModel.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.isLoading ? Color.gray.opacity(0.4) : Color.accentColor)
                                    .frame(width: 42, height: 42)
                                if viewModel.isLoading {
                                    ProgressView().tint(.white)
                                } else {
                                    Image(systemName: "paperplane.fill")
                                        .foregroundStyle(.white)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                        .disabled(viewModel.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.isLoading)
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 8)
                }
                .background(.ultraThinMaterial)
            }
            .navigationTitle("KI-Chat")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        viewModel.clear()
                    } label: {
                        Image(systemName: "trash")
                    }
                    .disabled(viewModel.messages.isEmpty)
                }
            }
            .sheet(isPresented: $viewModel.showModeSheet) {
                ModePickerSheet(selectedMode: $viewModel.selectedMode)
                    .presentationDetents([.medium])
            }
            .alert("KI-Anfrage fehlgeschlagen", isPresented: $viewModel.showErrorAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(viewModel.errorMessage)
            }
        }
    }
}

// Backward compatibility for older references
struct TextAnalysisView: View {
    var body: some View { AIChatView() }
}

private struct MessageRow: View {
    let message: AIChatMessage

    var body: some View {
        HStack {
            if message.isUser { Spacer() }
            VStack(alignment: .leading, spacing: 4) {
                if message.isUser {
                    Text(message.text)
                        .font(.body)
                } else {
                    markdownText(message.text)
                        .font(.body)
                }
                Text(message.timestamp.formatted(date: .omitted, time: .shortened))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .padding(10)
            .background(message.isUser ? Color.accentColor.opacity(0.18) : Color(uiColor: .secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .frame(maxWidth: 320, alignment: .leading)
            if !message.isUser { Spacer() }
        }
    }

    @ViewBuilder
    private func markdownText(_ string: String) -> some View {
        if let attributed = try? AttributedString(markdown: string, options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace)) {
            Text(attributed)
        } else {
            Text(string)
        }
    }
}

private struct ModeChip: View {
    let mode: AIChatMode
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(mode.shortLabel)
                .font(.caption)
                .fontWeight(.medium)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(isSelected ? Color.accentColor.opacity(0.2) : Color.secondary.opacity(0.12))
                .foregroundStyle(isSelected ? Color.accentColor : Color.primary)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

private struct ModePickerSheet: View {
    @Binding var selectedMode: AIChatMode
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                ForEach(AIChatMode.allCases) { mode in
                    Button {
                        selectedMode = mode
                        dismiss()
                    } label: {
                        HStack {
                            Text(mode.rawValue)
                            Spacer()
                            if selectedMode == mode {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .navigationTitle("Modus auswählen")
        }
    }
}
