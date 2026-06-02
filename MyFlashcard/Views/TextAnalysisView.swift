import SwiftUI
import NaturalLanguage

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
    let directTranslationOnly: Bool
}

private final class AIIntentRouter {
    private let grammarTriggers = [
        "correct grammar", "grammar check", "check grammar", "fix grammar", "grammar correction"
    ]

    private let translationPatterns: [NSRegularExpression] = [
        try! NSRegularExpression(pattern: "(?i)wie sagt man\\s+(.+?)\\s+auf englisch\\??\\s*$"),
        try! NSRegularExpression(pattern: "(?i)was heißt\\s+(.+?)\\s+auf englisch\\??\\s*$"),
        try! NSRegularExpression(pattern: "(?i)(.+?)\\s+auf englisch sagen\\??\\s*$"),
        try! NSRegularExpression(pattern: "(?i)translate\\s+(.+?)\\s+to english\\??\\s*$"),
        try! NSRegularExpression(pattern: "(?i)how do you say\\s+(.+?)\\s+in english\\??\\s*$"),
        try! NSRegularExpression(pattern: "(?i)how can i say\\s+(.+?)(?:\\s+in english)?\\??\\s*$"),
        try! NSRegularExpression(pattern: "(?i)übersetze\\s+(.+?)\\s+ins englische\\??\\s*$"),
        try! NSRegularExpression(pattern: "(?i)(.+?)\\s+wie kann ich (?:es|das|diesen satz)?\\s*auf englisch sagen\\??\\s*$")
    ]

    func route(userInput: String, selectedMode: AIChatMode) -> AIIntentDecision {
        let trimmed = userInput.trimmingCharacters(in: .whitespacesAndNewlines)
        let language = detectLanguage(trimmed)

        if let translationPayload = extractTranslationPayload(from: trimmed) {
            return AIIntentDecision(mode: .translate, inputForModel: translationPayload, directTranslationOnly: true)
        }

        let lower = trimmed.lowercased()
        let explicitGrammar = grammarTriggers.contains { lower.contains($0) }
        if explicitGrammar && language == .english {
            return AIIntentDecision(mode: .grammar, inputForModel: extractGrammarPayload(trimmed), directTranslationOnly: false)
        }

        if selectedMode == .grammar && language != .english {
            return AIIntentDecision(mode: .chat, inputForModel: trimmed, directTranslationOnly: false)
        }

        return AIIntentDecision(mode: selectedMode, inputForModel: trimmed, directTranslationOnly: false)
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

private enum TranslationSourcePolicy {
    static let primaryName = "b-amooz dictionary"
    static let primaryURL = "https://dic.b-amooz.com/en/dictionary"

    static var primaryLabel: String {
        "Primärquelle: \(primaryName)"
    }

    static func lookupURL(for query: String) -> String {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return primaryURL }
        let encoded = trimmed.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? trimmed
        return "\(primaryURL)/w?word=\(encoded)"
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

private protocol DictionarySource {
    var sourceName: String { get }
    func lookup(query: String) async -> DictionaryLookup?
}

private final class DictionaryCacheStore {
    private let defaults = UserDefaults.standard
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    private let prefix = "dictionary.cache."

    func load(query: String, now: Date = Date()) -> DictionaryLookup? {
        let normalized = normalize(query)
        guard !normalized.isEmpty,
              let data = defaults.data(forKey: prefix + normalized),
              let lookup = try? decoder.decode(DictionaryLookup.self, from: data)
        else {
            return nil
        }
        return lookup.withCacheFlags(fromCache: true, isStale: lookup.expiresAt <= now)
    }

    func save(_ lookup: DictionaryLookup) {
        let normalized = normalize(lookup.normalizedQuery)
        guard !normalized.isEmpty, let data = try? encoder.encode(lookup.withCacheFlags(fromCache: false, isStale: false)) else { return }
        defaults.set(data, forKey: prefix + normalized)
    }

    private func normalize(_ value: String) -> String {
        value
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
            .replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
    }
}

private final class BamoozDictionarySource: DictionarySource {
    let sourceName = TranslationSourcePolicy.primaryName

    func lookup(query: String) async -> DictionaryLookup? {
        let normalized = normalize(query)
        guard !normalized.isEmpty,
              let url = URL(string: TranslationSourcePolicy.lookupURL(for: normalized))
        else {
            return nil
        }

        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode),
                  let html = String(data: data, encoding: .utf8)
            else {
                return nil
            }

            let description = parseMetaDescription(from: html)
            let senses = parseTranslations(description: description, html: html)
            let synonyms = parseSynonyms(from: html)
            let examples = parseExamples(from: html)
            guard !description.isEmpty || !senses.isEmpty || !synonyms.isEmpty || !examples.isEmpty else {
                return nil
            }

            let now = Date()
            return DictionaryLookup(
                query: query.trimmingCharacters(in: .whitespacesAndNewlines),
                normalizedQuery: normalized,
                sourceName: sourceName,
                sourceURL: url.absoluteString,
                description: description,
                translations: senses.map { $0.translation },
                synonyms: synonyms,
                examples: examples,
                primaryPartOfSpeech: senses.first?.partOfSpeech,
                cachedAt: now,
                expiresAt: now,
                fromCache: false,
                isStale: false
            )
        } catch {
            return nil
        }
    }

    private func parseMetaDescription(from html: String) -> String {
        guard let captured = firstMatch(#"<meta\s+name=\"Description\"\s+content=\"([^\"]+)\""#, in: html, options: [.caseInsensitive])?[safe: 0] else {
            return ""
        }
        return decodeHTML(captured)
    }

    private func parseTranslations(description: String, html: String) -> [(translation: String, partOfSpeech: String?)] {
        var senses: [(String, String?)] = allMatches(#"\d+\s*-\s*([^()]+?)\s*\(([^)]+)\)"#, in: description)
            .compactMap { groups in
                guard let translation = groups[safe: 0]?.trimmingCharacters(in: .whitespacesAndNewlines), !translation.isEmpty else { return nil }
                let partOfSpeech = groups[safe: 1]?.trimmingCharacters(in: .whitespacesAndNewlines)
                return (decodeHTML(translation), partOfSpeech.flatMap { decodeHTML($0) })
            }

        if senses.isEmpty {
            senses = allMatches(#"<span[^>]*translation-index[^>]*>.*?</span>\s*<strong>(.*?)</strong>"#, in: html, options: [.caseInsensitive, .dotMatchesLineSeparators])
                .compactMap { groups in
                    guard let translation = groups[safe: 0].map(cleanHTMLText), !translation.isEmpty else { return nil }
                    return (translation, nil)
                }
        }

        var seen = Set<String>()
        return senses.filter { seen.insert($0.0.lowercased()).inserted }.prefix(5).map { $0 }
    }

    private func parseSynonyms(from html: String) -> [String] {
        guard let section = firstMatch(#"مترادف و متضاد(.*?)</div>\s*</div>"#, in: html, options: [.caseInsensitive, .dotMatchesLineSeparators])?.first else {
            return []
        }

        var seen = Set<String>()
        return allMatches(#"badge-pill\s+badge-primary[^>]*>(.*?)</small>"#, in: section, options: [.caseInsensitive])
            .compactMap { $0[safe: 0].map(cleanHTMLText) }
            .filter { !$0.isEmpty && seen.insert($0).inserted }
            .prefix(6)
            .map { $0 }
    }

    private func parseExamples(from html: String) -> [DictionaryExample] {
        allMatches(
            #"<div class=\"col-12 example-box\">.*?<span class=\"m-0\">(.*?)</span>.*?<span class=\"m-0 translation-example-box\">(.*?)</span>"#,
            in: html,
            options: [.caseInsensitive, .dotMatchesLineSeparators]
        )
        .compactMap { groups in
            let source = groups[safe: 0].map(cleanHTMLText)?.removingNumericPrefix() ?? ""
            let translation = groups[safe: 1].map(cleanHTMLText)?.removingNumericPrefix() ?? ""
            guard !source.isEmpty || !translation.isEmpty else { return nil }
            return DictionaryExample(source: source, translation: translation)
        }
        .prefix(3)
        .map { $0 }
    }

    private func firstMatch(_ pattern: String, in text: String, options: NSRegularExpression.Options = []) -> [String]? {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: options) else { return nil }
        let range = NSRange(text.startIndex..., in: text)
        guard let match = regex.firstMatch(in: text, options: [], range: range) else { return nil }
        return (1..<match.numberOfRanges).compactMap { idx in
            guard let range = Range(match.range(at: idx), in: text) else { return nil }
            return String(text[range])
        }
    }

    private func allMatches(_ pattern: String, in text: String, options: NSRegularExpression.Options = []) -> [[String]] {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: options) else { return [] }
        let range = NSRange(text.startIndex..., in: text)
        return regex.matches(in: text, options: [], range: range).map { match in
            (1..<match.numberOfRanges).compactMap { idx in
                guard let range = Range(match.range(at: idx), in: text) else { return nil }
                return String(text[range])
            }
        }
    }

    private func cleanHTMLText(_ value: String) -> String {
        decodeHTML(value.replacingOccurrences(of: #"<[^>]+>"#, with: " ", options: .regularExpression))
            .replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func decodeHTML(_ value: String) -> String {
        value
            .replacingOccurrences(of: "&nbsp;", with: " ")
            .replacingOccurrences(of: "&amp;", with: "&")
            .replacingOccurrences(of: "&quot;", with: "\"")
            .replacingOccurrences(of: "&#39;", with: "'")
            .replacingOccurrences(of: "&lt;", with: "<")
            .replacingOccurrences(of: "&gt;", with: ">")
    }

    private func normalize(_ value: String) -> String {
        value
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
            .replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
    }
}

private final class DictionaryRepository {
    private let cacheStore: DictionaryCacheStore
    private let source: DictionarySource
    private let ttl: TimeInterval

    init(
        cacheStore: DictionaryCacheStore = DictionaryCacheStore(),
        source: DictionarySource = BamoozDictionarySource(),
        ttl: TimeInterval = 7 * 24 * 60 * 60
    ) {
        self.cacheStore = cacheStore
        self.source = source
        self.ttl = ttl
    }

    func lookup(query: String, isOnline: Bool) async -> DictionaryLookup? {
        let normalized = query
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
            .replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)

        guard !normalized.isEmpty else { return nil }

        let now = Date()
        if let cached = cacheStore.load(query: normalized, now: now), cached.expiresAt > now {
            return cached
        }

        if isOnline, let live = await source.lookup(query: query)?.withExpiry(ttl) {
            cacheStore.save(live)
            return live
        }

        return cacheStore.load(query: normalized, now: now)
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

private extension String {
    func removingNumericPrefix() -> String {
        replacingOccurrences(of: #"^\d+[.)-]?\s*"#, with: "", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

// MARK: - Offline Engine + Repository

private struct AIRepositoryResult {
    let response: String
    let mode: AIChatMode
    let recommendedTopics: [String]
    let dictionaryLookup: DictionaryLookup?
    let inferencePath: AIInferencePath
}

private enum AIInferencePath {
    case onDevice
    case proxy

    var label: String {
        switch self {
        case .onDevice: return "On-device"
        case .proxy: return "Proxy-Fallback"
        }
    }
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

private final class OfflineAIEngine {
    private let analysisService = TextAnalysisService.shared
    private let recommender = GrammarTopicRecommender()

    func generateResponse(input: String, mode: AIChatMode, directTranslationOnly: Bool, dictionaryLookup: DictionaryLookup?) -> String {
        switch mode {
        case .translate:
            return translateToEnglish(input, directOnly: directTranslationOnly, dictionaryLookup: dictionaryLookup)
        case .grammar:
            return grammarResponse(input)
        case .analyze:
            let result = analysisService.analyzeText(input)
            let weaknessBlock = result.weaknessAreas.isEmpty ? "Keine klaren Schwachstellen erkannt." : result.weaknessAreas.joined(separator: "\n- ")
            let exerciseBlock = result.recommendedExercises.prefix(2).joined(separator: "\n- ")
            return "Wörter: \(result.wordCount)\nSätze: \(result.sentences)\nAuffälligkeiten: \(result.grammarIssues.count)\nCEFR (Schätzung): \(result.cefrEstimate)\n\nSchwächen:\n- \(weaknessBlock)\n\nAktive Übung:\n- \(exerciseBlock)"
        case .improve:
            let analysis = analysisService.analyzeText(input)
            let taskHint = analysis.recommendedExercises.first ?? "Überarbeite den Text mit Fokus auf klare Satzstruktur."
            return "Verbesserter Entwurf:\n\n\(input)\n\n- Verwende präzisere Verben\n- Entferne unnötige Füllwörter\n- Bevorzuge kürzere, klarere Sätze\n- Nächster Lernschritt: \(taskHint)"
        case .professional:
            return "Professionelle Version:\n\nThank you for your message. I would appreciate your feedback by tomorrow."
        case .vocabulary:
            return vocabularyResponse(for: input, dictionaryLookup: dictionaryLookup)
        case .chat:
            return chatResponse(input, dictionaryLookup: dictionaryLookup)
        }
    }

    private func chatResponse(_ input: String, dictionaryLookup: DictionaryLookup?) -> String {
        if let payload = phrasePayload(from: input) {
            let candidate = payload.cleanedPayload()
            if !candidate.isEmpty {
                let suggestion = candidate.hasSuffix("?") ? candidate : "\(candidate)?"
                let grammarScan = analysisService.analyzeText(suggestion)
                let qualityLine = grammarScan.grammarIssues.first.map { "Hinweis: \($0.suggestion)" }
                    ?? "Hinweis: Die Formulierung ist bereits gut verständlich."
                return "Du kannst sagen:\n\"\(suggestion)\"\n\n\(qualityLine)"
            }
        }

        if let lookup = dictionaryLookup, !lookup.translations.isEmpty {
            return vocabularyResponse(for: input, dictionaryLookup: lookup)
        }

        let analysis = analysisService.analyzeText(input)
        let topIssue = analysis.grammarIssues.first?.suggestion
        let topics = recommender.recommendTopics(from: input, limit: 2)
        let topicLine = topics.isEmpty ? "" : "\nEmpfohlene Themen: \(topics.joined(separator: ", "))"

        if let topIssue {
            return "Zu deiner Anfrage: \"\(input)\"\n\nSchneller Sprachhinweis: \(topIssue)\(topicLine)"
        }

        return "Verstanden: \"\(input)\"\n\nWenn du willst, kann ich den Satz direkt korrigieren, natürlicher formulieren oder uebersetzen.\(topicLine)"
    }

    private func phrasePayload(from input: String) -> String? {
        let patterns = [
            "(?i)^how can i say\\s+(.+?)\\??\\s*$",
            "(?i)^how do i say\\s+(.+?)\\??\\s*$",
            "(?i)^can i say\\s+(.+?)\\??\\s*$",
            "(?i)^wie kann ich\\s+(.+?)\\s+auf englisch sagen\\??\\s*$"
        ]

        for pattern in patterns {
            if let captured = firstCapturedGroup(pattern, in: input), !captured.cleanedPayload().isEmpty {
                return captured
            }
        }
        return nil
    }

    private func firstCapturedGroup(_ pattern: String, in text: String) -> String? {
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
              match.numberOfRanges > 1,
              let range = Range(match.range(at: 1), in: text)
        else {
            return nil
        }
        return String(text[range])
    }

    private func grammarResponse(_ input: String) -> String {
        let result = analysisService.analyzeText(input)
        let top = result.grammarIssues.prefix(5)
        if top.isEmpty {
            return "Korrigierter Text:\n\(input)\n\nKeine größeren Grammatikprobleme gefunden."
        }

        let bullets = top.map { "- \($0.issue): \($0.suggestion)" }.joined(separator: "\n")
        return "Grammatik-Feedback:\n\n\(bullets)\n\nOriginal:\n\(input)"
    }

    private func translateToEnglish(_ input: String, directOnly: Bool, dictionaryLookup: DictionaryLookup?) -> String {
        if let lookup = dictionaryLookup, !lookup.translations.isEmpty {
            let synonymsBlock = lookup.synonyms.isEmpty ? "" : "\nSynonyme: \(lookup.synonyms.joined(separator: ", "))"
            let exampleBlock = lookup.examples.first.map { "\nBeispiel: \($0.source)\nفارسی: \($0.translation)" } ?? ""
            let partOfSpeechBlock = lookup.primaryPartOfSpeech.map { "\nWortart: \($0)" } ?? ""
            return """
            Beste Übersetzung aus dem Dictionary:
            \(lookup.translations.joined(separator: " • "))\(partOfSpeechBlock)\(synonymsBlock)\(exampleBlock)

            Primärquelle:
            \(lookup.sourceName)
            \(lookup.sourceURL)
            """
        }

        let normalized = input.lowercased().trimmingCharacters(in: CharacterSet(charactersIn: " .!?\"'"))
        let dictionary: [String: String] = [
            "steh auf und geh": "Get up and go",
            "ich liebe dich": "I love you",
            "wie geht es dir": "How are you",
            "danke": "Thank you",
            "gute nacht": "Good night"
        ]

        if let value = dictionary[normalized] {
            return """
            Beste Übersetzung:
            \(value)

            توضیح فارسی:
            این عبارت به‌صورت طبیعی و روزمره در انگلیسی استفاده می‌شود.

            Primärquelle:
            \(TranslationSourcePolicy.primaryLabel)
            \(TranslationSourcePolicy.lookupURL(for: input))
            """
        }
        if directOnly {
            return """
            Keine verlässliche Offline-Direktübersetzung gefunden.

            Bitte prüfe Bedeutung und Übersetzung über die Primärquelle:
            \(TranslationSourcePolicy.primaryLabel)
            \(TranslationSourcePolicy.lookupURL(for: input))
            """
        }
        return """
        Für eine präzise Übersetzung oder Bedeutungsprüfung nutze bitte:
        \(TranslationSourcePolicy.primaryLabel)
        \(TranslationSourcePolicy.lookupURL(for: input))
        """
    }

    private func vocabularyResponse(for input: String, dictionaryLookup: DictionaryLookup?) -> String {
        if let lookup = dictionaryLookup {
            let translations = lookup.translations.isEmpty ? "–" : lookup.translations.joined(separator: " • ")
            let synonyms = lookup.synonyms.isEmpty ? "–" : lookup.synonyms.joined(separator: ", ")
            let example = lookup.examples.first.map { "\($0.source)\n\($0.translation)" } ?? "–"
            return """
            Wortschatzhilfe:
            Bedeutung: \(translations)
            Wortart: \(lookup.primaryPartOfSpeech ?? "–")
            Synonyme: \(synonyms)
            Beispiel:
            \(example)

            Quelle:
            \(lookup.sourceName)
            \(lookup.sourceURL)
            """
        }

        return "Wortschatzhilfe:\n- resilient: توانایی بازیابی سریع پس از فشار یا مشکل\n- concise: kurz, klar und ohne unnötige Details\n- accurate: korrekt, präzise und verlässlich"
    }
}

private final class AIChatRepository {
    private let router = AIIntentRouter()
    private let memory = AIConversationMemory()
    private let engine = OfflineAIEngine()
    private let recommender = GrammarTopicRecommender()
    private let dictionaryRepository = DictionaryRepository()

    func sendMessage(userInput: String, selectedMode: AIChatMode, isOnline: Bool) async -> AIRepositoryResult {
        let decision = router.route(userInput: userInput, selectedMode: selectedMode)
        let dictionaryLookup = await lookupDictionaryIfRelevant(userInput: userInput, decision: decision, isOnline: isOnline)
        let inferencePath = preferredInferencePath(input: decision.inputForModel, isOnline: isOnline)

        memory.add(AIChatMessage(isUser: true, text: userInput))
        try? await Task.sleep(nanoseconds: 450_000_000)

        let response: String
        var effectiveInferencePath = inferencePath
        if inferencePath == .proxy,
           let proxyResponse = await requestProxyResponse(input: decision.inputForModel, mode: decision.mode) {
            response = proxyResponse
        } else {
            effectiveInferencePath = .onDevice
            response = engine.generateResponse(
                input: decision.inputForModel,
                mode: decision.mode,
                directTranslationOnly: decision.directTranslationOnly,
                dictionaryLookup: dictionaryLookup
            )
        }

        let topics = decision.mode == .grammar ? recommender.recommendTopics(from: decision.inputForModel) : []
        let finalResponse: String
        if topics.isEmpty || decision.mode != .grammar {
            finalResponse = "\(response)\n\nEngine: \(effectiveInferencePath.label)"
        } else {
            let topicLines = topics.map { "- \($0)" }.joined(separator: "\n")
            finalResponse = "\(response)\n\nPassende Grammatikthemen:\n\(topicLines)\n\nEngine: \(effectiveInferencePath.label)"
        }

        let assistant = AIChatMessage(isUser: false, text: finalResponse)
        memory.add(assistant)

        return AIRepositoryResult(
            response: finalResponse,
            mode: decision.mode,
            recommendedTopics: topics,
            dictionaryLookup: dictionaryLookup,
            inferencePath: effectiveInferencePath
        )
    }

    private func preferredInferencePath(input: String, isOnline: Bool) -> AIInferencePath {
        let onDeviceAvailable = input.count <= 1500
        if onDeviceAvailable { return .onDevice }
        return isOnline ? .proxy : .onDevice
    }

    private func requestProxyResponse(input: String, mode: AIChatMode) async -> String? {
        // Existing proxy structure is preserved intentionally; concrete provider wiring remains optional.
        _ = input
        _ = mode
        return nil
    }

    private func lookupDictionaryIfRelevant(userInput: String, decision: AIIntentDecision, isOnline: Bool) async -> DictionaryLookup? {
        let candidate: String?
        switch decision.mode {
        case .translate:
            candidate = decision.inputForModel
        case .vocabulary:
            candidate = extractDictionaryCandidate(from: userInput, fallback: decision.inputForModel)
        default:
            candidate = nil
        }

        guard let candidate, candidate.trimmingCharacters(in: .whitespacesAndNewlines).count >= 2 else {
            return nil
        }
        return await dictionaryRepository.lookup(query: candidate, isOnline: isOnline)
    }

    private func extractDictionaryCandidate(from originalInput: String, fallback: String) -> String {
        if let quoted = firstCaptured(#"[\"']([^\"']+)[\"']"#, in: originalInput), !quoted.isEmpty {
            return quoted
        }

        let cleaned = fallback
            .replacingOccurrences(of: #"(?i)(erkläre|explain|define|definition|meaning|bedeutung|was bedeutet|what does|wortschatz|vocabulary)\s+"#, with: "", options: .regularExpression)
            .replacingOccurrences(of: #"[^\p{L}\p{N}\s-]"#, with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)

        return cleaned
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .prefix(3)
            .joined(separator: " ")
    }

    private func firstCaptured(_ pattern: String, in text: String) -> String? {
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
              let range = Range(match.range(at: 1), in: text)
        else {
            return nil
        }
        return String(text[range])
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
    @Published var isOnline: Bool = false
    @Published var lastDictionaryLookup: DictionaryLookup?

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
            let result = await repository.sendMessage(userInput: trimmed, selectedMode: selectedMode, isOnline: isOnline)
            if !result.recommendedTopics.isEmpty {
                GrammarRecommendationStore.shared.setTopics(result.recommendedTopics)
            }

            withAnimation(.spring(response: 0.32, dampingFraction: 0.9)) {
                messages.append(AIChatMessage(isUser: false, text: result.response))
                lastDictionaryLookup = result.dictionaryLookup
                isLoading = false
            }
        }
    }

    func clear() {
        withAnimation(.easeInOut(duration: 0.2)) {
            messages.removeAll()
        }
        lastDictionaryLookup = nil
        repository.clearHistory()
    }
}

// MARK: - View

struct AIChatView: View {
    @StateObject private var viewModel = AIChatViewModel()

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if let lookup = viewModel.lastDictionaryLookup {
                    DictionaryLookupCard(lookup: lookup)
                        .padding(.horizontal)
                        .padding(.top, 8)
                }

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
        }
    }
}

private struct DictionaryLookupCard: View {
    let lookup: DictionaryLookup

    private var cacheLabel: String {
        if lookup.isStale { return "Cache veraltet" }
        if lookup.fromCache { return "Cache" }
        return "Live"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("Dictionary-Lookup")
                    .font(.headline)
                Spacer()
                Text(cacheLabel)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Text(lookup.sourceName)
                .font(.subheadline)
                .fontWeight(.medium)

            if !lookup.summaryText.isEmpty {
                Text(lookup.summaryText)
                    .font(.subheadline)
            }

            if !lookup.synonyms.isEmpty {
                Text("Synonyme: \(lookup.synonyms.joined(separator: ", "))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Text(lookup.sourceURL)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .textSelection(.enabled)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.accentColor.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 16))
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
                Text(message.text)
                    .font(.body)
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
