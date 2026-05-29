import SwiftUI
import NaturalLanguage

// MARK: - Modes

enum AIChatMode: String, CaseIterable, Identifiable {
    case chat = "Chat"
    case grammar = "Grammar"
    case improve = "Improve"
    case analyze = "Analyze"
    case translate = "Translate"
    case professional = "Professional Writing"
    case vocabulary = "Vocabulary"

    var id: String { rawValue }

    var shortLabel: String {
        switch self {
        case .professional: return "Pro"
        default: return rawValue
        }
    }

    var placeholder: String {
        switch self {
        case .chat: return "Ask anything..."
        case .grammar: return "Paste text for grammar correction..."
        case .improve: return "Paste text to improve..."
        case .analyze: return "Paste text to analyze..."
        case .translate: return "Enter text to translate..."
        case .professional: return "Draft your professional message..."
        case .vocabulary: return "Ask about words, meanings, synonyms..."
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

// MARK: - Offline Engine + Repository

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

private final class OfflineAIEngine {
    private let analysisService = TextAnalysisService.shared

    func generateResponse(input: String, mode: AIChatMode, directTranslationOnly: Bool) -> String {
        switch mode {
        case .translate:
            return translateToEnglish(input, directOnly: directTranslationOnly)
        case .grammar:
            return grammarResponse(input)
        case .analyze:
            let result = analysisService.analyzeText(input)
            return "Words: \(result.wordCount)\nSentences: \(result.sentences)\nIssues: \(result.grammarIssues.count)\n\nTip: Vary sentence openings and keep tense consistent."
        case .improve:
            return "Improved draft:\n\n\(input)\n\n- Use stronger verbs\n- Remove filler phrases\n- Prefer shorter sentences"
        case .professional:
            return "Professional version:\n\nThank you for your message. I would appreciate your feedback by tomorrow."
        case .vocabulary:
            return "Vocabulary coach:\n- resilient: able to recover quickly\n- concise: brief but clear\n- accurate: correct and precise"
        case .chat:
            return "I can help with grammar, text improvement, analysis, translation, and vocabulary practice."
        }
    }

    private func grammarResponse(_ input: String) -> String {
        let result = analysisService.analyzeText(input)
        let top = result.grammarIssues.prefix(5)
        if top.isEmpty {
            return "Corrected text:\n\(input)\n\nNo major grammar issues found."
        }

        let bullets = top.map { "- \($0.issue): \($0.suggestion)" }.joined(separator: "\n")
        return "Grammar review:\n\n\(bullets)\n\nOriginal:\n\(input)"
    }

    private func translateToEnglish(_ input: String, directOnly: Bool) -> String {
        let normalized = input.lowercased().trimmingCharacters(in: CharacterSet(charactersIn: " .!?\"'"))
        let dictionary: [String: String] = [
            "steh auf und geh": "Get up and go",
            "ich liebe dich": "I love you",
            "wie geht es dir": "How are you",
            "danke": "Thank you",
            "gute nacht": "Good night"
        ]

        if let value = dictionary[normalized] { return value }
        if directOnly { return input }
        return "\(input)"
    }
}

private final class AIChatRepository {
    private let router = AIIntentRouter()
    private let memory = AIConversationMemory()
    private let engine = OfflineAIEngine()
    private let recommender = GrammarTopicRecommender()

    func sendMessage(userInput: String, selectedMode: AIChatMode, isOnline: Bool) async -> AIRepositoryResult {
        let decision = router.route(userInput: userInput, selectedMode: selectedMode)

        memory.add(AIChatMessage(isUser: true, text: userInput))
        try? await Task.sleep(nanoseconds: 450_000_000)

        let response = engine.generateResponse(
            input: decision.inputForModel,
            mode: decision.mode,
            directTranslationOnly: decision.directTranslationOnly
        )

        let topics = decision.mode == .grammar ? recommender.recommendTopics(from: decision.inputForModel) : []
        let finalResponse: String
        if topics.isEmpty || decision.mode != .grammar {
            finalResponse = response
        } else {
            let topicLines = topics.map { "- \($0)" }.joined(separator: "\n")
            finalResponse = "\(response)\n\nRelated Grammar topics:\n\(topicLines)"
        }

        let assistant = AIChatMessage(isUser: false, text: finalResponse)
        memory.add(assistant)

        return AIRepositoryResult(response: finalResponse, mode: decision.mode, recommendedTopics: topics)
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
                        "AI Chat",
                        systemImage: "sparkles",
                        description: Text("Chat, Grammar, Improve, Analyze, Translate, Professional Writing, Vocabulary")
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
                                        Text("AI is thinking...")
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
                                Label("More", systemImage: "chevron.down")
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
            .navigationTitle("AI Chat")
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
            .navigationTitle("Select Mode")
        }
    }
}
