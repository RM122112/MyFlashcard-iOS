import SwiftUI
import Combine

// MARK: - Grammar Hub Domain

struct GrammarChapter: Identifiable {
    let id: String
    let title: String
    let description: String
    let categories: [GrammarCategory]
}

enum GrammarChapterCatalog {
    static let chapters: [GrammarChapter] = [
        GrammarChapter(
            id: "foundations",
            title: "Grundlagen",
            description: "Artikel, Pronomen und Satzgrundlagen.",
            categories: [.articles, .pronouns, .questions, .negation]
        ),
        GrammarChapter(
            id: "verb_system",
            title: "Verbensystem",
            description: "Zeitformen, Modalverben und Passivkonstruktionen.",
            categories: [.tenses, .modals, .passiveVoice]
        ),
        GrammarChapter(
            id: "connections",
            title: "Verknüpfungen",
            description: "Präpositionen, Konditionalsätze und indirekte Rede.",
            categories: [.prepositions, .conditionals, .reportedSpeech, .conjunctions]
        ),
        GrammarChapter(
            id: "accuracy",
            title: "Genauigkeit",
            description: "Vergleiche, Phrasal Verbs und häufige Fehler.",
            categories: [.comparatives, .phrasalVerbs, .adjectives, .adverbs]
        )
    ]
}

@MainActor
final class GrammarLearningRepository: ObservableObject {
    static let shared = GrammarLearningRepository()

    @Published private(set) var favoriteRuleKeys: Set<String> = []
    @Published private(set) var completedRuleKeys: Set<String> = []

    private let defaults = UserDefaults.standard
    private let favoriteKey = "grammar.favorites"
    private let completedKey = "grammar.completed"

    private init() {
        favoriteRuleKeys = loadKeys(for: favoriteKey)
        completedRuleKeys = loadKeys(for: completedKey)
    }

    func toggleFavorite(_ key: String) {
        if favoriteRuleKeys.contains(key) {
            favoriteRuleKeys.remove(key)
        } else {
            favoriteRuleKeys.insert(key)
        }
        save(favoriteRuleKeys, key: favoriteKey)
    }

    func toggleCompleted(_ key: String) {
        if completedRuleKeys.contains(key) {
            completedRuleKeys.remove(key)
        } else {
            completedRuleKeys.insert(key)
        }
        save(completedRuleKeys, key: completedKey)
    }

    private func loadKeys(for key: String) -> Set<String> {
        Set(defaults.stringArray(forKey: key) ?? [])
    }

    private func save(_ keys: Set<String>, key: String) {
        defaults.set(Array(keys), forKey: key)
    }
}

@MainActor
final class GrammarHubViewModel: ObservableObject {
    @Published var searchText: String = ""
    @Published var selectedCategory: GrammarCategory?
    @Published var selectedChapterId: String?
    @Published var favoritesOnly = false
    @Published var expandedRuleIds: Set<UUID> = []

    @Published private(set) var rules: [GrammarRule] = GrammarDatabase.allRules

    private let learningRepository: GrammarLearningRepository
    private let recommendationStore: GrammarRecommendationStore
    private var cancellables: Set<AnyCancellable> = []

    init(
        learningRepository: GrammarLearningRepository,
        recommendationStore: GrammarRecommendationStore
    ) {
        self.learningRepository = learningRepository
        self.recommendationStore = recommendationStore

        learningRepository.objectWillChange
            .sink { [weak self] _ in self?.objectWillChange.send() }
            .store(in: &cancellables)

        recommendationStore.objectWillChange
            .sink { [weak self] _ in self?.objectWillChange.send() }
            .store(in: &cancellables)
    }

    convenience init() {
        self.init(learningRepository: .shared, recommendationStore: .shared)
    }

    private func ruleKey(_ rule: GrammarRule) -> String {
        "\(rule.category.rawValue)|\(rule.title)"
    }

    var allCategories: [GrammarCategory] {
        Array(Set(rules.map(\.category))).sorted { $0.rawValue < $1.rawValue }
    }

    var recommendedTopics: [String] {
        recommendationStore.topics
    }

    var filteredRules: [GrammarRule] {
        rules.filter { rule in
            let chapterMatch: Bool = {
                guard let selectedChapterId else { return true }
                guard let chapter = GrammarChapterCatalog.chapters.first(where: { $0.id == selectedChapterId }) else { return true }
                return chapter.categories.contains(rule.category)
            }()

            let categoryMatch = selectedCategory == nil || rule.category == selectedCategory
            let favoritesMatch = !favoritesOnly || learningRepository.favoriteRuleKeys.contains(ruleKey(rule))
            let searchMatch: Bool = {
                guard !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return true }
                let query = searchText.lowercased()
                let haystack = [
                    rule.title,
                    rule.explanation,
                    rule.formula,
                    rule.examples.map(\.english).joined(separator: " "),
                    rule.tips.joined(separator: " "),
                    rule.category.rawValue
                ].joined(separator: " ").lowercased()
                return haystack.contains(query)
            }()

            return chapterMatch && categoryMatch && favoritesMatch && searchMatch
        }
    }

    var progressFraction: Double {
        guard !rules.isEmpty else { return 0 }
        return Double(learningRepository.completedRuleKeys.count) / Double(rules.count)
    }

    var completedCount: Int { learningRepository.completedRuleKeys.count }
    var favoriteCount: Int { learningRepository.favoriteRuleKeys.count }

    func chapterProgress(for chapter: GrammarChapter) -> Double {
        let chapterKeys = rules.filter { chapter.categories.contains($0.category) }.map(ruleKey)
        guard !chapterKeys.isEmpty else { return 0 }
        let done = chapterKeys.filter { learningRepository.completedRuleKeys.contains($0) }.count
        return Double(done) / Double(chapterKeys.count)
    }

    func chapterCounter(for chapter: GrammarChapter) -> String {
        let chapterKeys = rules.filter { chapter.categories.contains($0.category) }.map(ruleKey)
        let done = chapterKeys.filter { learningRepository.completedRuleKeys.contains($0) }.count
        return "\(done)/\(chapterKeys.count)"
    }

    func toggleFavorite(_ rule: GrammarRule) {
        learningRepository.toggleFavorite(ruleKey(rule))
    }

    func toggleCompleted(_ rule: GrammarRule) {
        learningRepository.toggleCompleted(ruleKey(rule))
    }

    func isFavorite(_ rule: GrammarRule) -> Bool {
        learningRepository.favoriteRuleKeys.contains(ruleKey(rule))
    }

    func isCompleted(_ rule: GrammarRule) -> Bool {
        learningRepository.completedRuleKeys.contains(ruleKey(rule))
    }

    func toggleExpanded(_ id: UUID) {
        if expandedRuleIds.contains(id) {
            expandedRuleIds.remove(id)
        } else {
            expandedRuleIds.insert(id)
        }
    }

    func mapRecommendedTopicToCategory(_ topic: String) -> GrammarCategory? {
        switch topic.lowercased() {
        case let t where t.contains("tense"): return .tenses
        case let t where t.contains("article"): return .articles
        case let t where t.contains("pronoun"): return .pronouns
        case let t where t.contains("preposition"): return .prepositions
        case let t where t.contains("passive"): return .passiveVoice
        case let t where t.contains("conditional"): return .conditionals
        case let t where t.contains("reported"): return .reportedSpeech
        case let t where t.contains("modal"): return .modals
        case let t where t.contains("question"): return .questions
        case let t where t.contains("negation"): return .negation
        case let t where t.contains("mistake"): return .negation
        default: return nil
        }
    }

    func applyRecommendation(_ topic: String) {
        if let category = mapRecommendedTopicToCategory(topic) {
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedCategory = category
                selectedChapterId = nil
            }
        }
    }
}

// MARK: - View

struct GrammarView: View {
    @StateObject private var viewModel = GrammarHubViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 12) {
                    ProgressCard(
                        fraction: viewModel.progressFraction,
                        completed: viewModel.completedCount,
                        total: viewModel.rules.count,
                        favorites: viewModel.favoriteCount
                    )

                    if !viewModel.recommendedTopics.isEmpty {
                        RecommendationCard(topics: viewModel.recommendedTopics) { topic in
                            viewModel.applyRecommendation(topic)
                        }
                    }

                    SearchSection(searchText: $viewModel.searchText)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Kapitel")
                            .font(.headline)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                ChapterChip(
                                    title: "Alle",
                                    subtitle: "\(viewModel.completedCount)/\(viewModel.rules.count)",
                                    progress: viewModel.progressFraction,
                                    isSelected: viewModel.selectedChapterId == nil
                                ) {
                                    viewModel.selectedChapterId = nil
                                }

                                ForEach(GrammarChapterCatalog.chapters) { chapter in
                                    ChapterChip(
                                        title: chapter.title,
                                        subtitle: viewModel.chapterCounter(for: chapter),
                                        progress: viewModel.chapterProgress(for: chapter),
                                        isSelected: viewModel.selectedChapterId == chapter.id
                                    ) {
                                        viewModel.selectedChapterId = (viewModel.selectedChapterId == chapter.id) ? nil : chapter.id
                                    }
                                }
                            }
                            .padding(.horizontal, 2)
                        }
                    }

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            FilterChip(
                                title: "Favoriten",
                                systemImage: viewModel.favoritesOnly ? "heart.fill" : "heart",
                                isSelected: viewModel.favoritesOnly
                            ) {
                                viewModel.favoritesOnly.toggle()
                            }

                            FilterChip(
                                title: "Alle Kategorien",
                                systemImage: "square.grid.2x2",
                                isSelected: viewModel.selectedCategory == nil
                            ) {
                                viewModel.selectedCategory = nil
                            }

                            ForEach(viewModel.allCategories, id: \.self) { category in
                                FilterChip(
                                    title: category.localizedTitle,
                                    systemImage: category.icon,
                                    isSelected: viewModel.selectedCategory == category
                                ) {
                                    viewModel.selectedCategory = (viewModel.selectedCategory == category) ? nil : category
                                }
                            }
                        }
                        .padding(.horizontal, 2)
                    }

                    if viewModel.filteredRules.isEmpty {
                        ContentUnavailableView("Keine Regeln gefunden", systemImage: "book.closed")
                            .frame(maxWidth: .infinity)
                            .padding(.top, 24)
                    } else {
                        LazyVStack(spacing: 10) {
                            ForEach(viewModel.filteredRules) { rule in
                                GrammarRuleCard(
                                    rule: rule,
                                    isExpanded: viewModel.expandedRuleIds.contains(rule.id),
                                    isFavorite: viewModel.isFavorite(rule),
                                    isCompleted: viewModel.isCompleted(rule),
                                    onToggleExpanded: { viewModel.toggleExpanded(rule.id) },
                                    onToggleFavorite: { viewModel.toggleFavorite(rule) },
                                    onToggleCompleted: { viewModel.toggleCompleted(rule) }
                                )
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Grammatik-Hub")
            .animation(.easeInOut(duration: 0.2), value: viewModel.filteredRules.count)
        }
    }
}

// MARK: - Reusable Components

private struct ProgressCard: View {
    let fraction: Double
    let completed: Int
    let total: Int
    let favorites: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Lernfortschritt", systemImage: "chart.bar.fill")
                .font(.headline)
            ProgressView(value: fraction)
                .progressViewStyle(.linear)
            HStack {
                Text("\(completed)/\(total) abgeschlossen")
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(favorites) Favoriten")
                    .foregroundStyle(.secondary)
            }
            .font(.caption)
        }
        .padding()
        .background(
            LinearGradient(
                colors: [Color.accentColor.opacity(0.22), Color.purple.opacity(0.16)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

private struct SearchSection: View {
    @Binding var searchText: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
            TextField("Regeln, Formeln und Beispiele durchsuchen ...", text: $searchText)
                .textInputAutocapitalization(.never)
            if !searchText.isEmpty {
                Button {
                    searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color(uiColor: .secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

private struct RecommendationCard: View {
    let topics: [String]
    let onTap: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Empfohlen aus dem KI-Chat", systemImage: "sparkles")
                .font(.headline)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(topics, id: \.self) { topic in
                        Button {
                            onTap(topic)
                        } label: {
                            Text(topic)
                                .font(.caption)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 7)
                                .background(Color.accentColor.opacity(0.16))
                                .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

private struct ChapterChip: View {
    let title: String
    let subtitle: String
    let progress: Double
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                ProgressView(value: progress)
            }
            .padding(10)
            .frame(width: 180, alignment: .leading)
            .background(
                isSelected
                    ? LinearGradient(
                        colors: [Color.accentColor.opacity(0.28), Color.cyan.opacity(0.22)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    : LinearGradient(
                        colors: [Color(uiColor: .secondarySystemBackground), Color(uiColor: .tertiarySystemBackground)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }
}

private struct FilterChip: View {
    let title: String
    let systemImage: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: systemImage)
                Text(title)
            }
            .font(.caption)
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(isSelected ? Color.accentColor.opacity(0.2) : Color.gray.opacity(0.12))
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

private struct GrammarRuleCard: View {
    let rule: GrammarRule
    let isExpanded: Bool
    let isFavorite: Bool
    let isCompleted: Bool
    let onToggleExpanded: () -> Void
    let onToggleFavorite: () -> Void
    let onToggleCompleted: () -> Void

    var body: some View {
        let style = grammarCategoryStyle(rule.category)

        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 6) {
                        Image(systemName: rule.category.icon)
                            .foregroundStyle(style.accent)
                        Text(rule.category.localizedTitle)
                            .font(.caption)
                            .foregroundStyle(style.accent)
                    }
                    Text(rule.title)
                        .font(.headline)
                }

                Spacer()

                Button(action: onToggleFavorite) {
                    Image(systemName: isFavorite ? "heart.fill" : "heart")
                        .foregroundStyle(isFavorite ? .pink : .secondary)
                }
                .buttonStyle(.plain)

                Button(action: onToggleCompleted) {
                    Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                        .foregroundStyle(isCompleted ? .green : .secondary)
                }
                .buttonStyle(.plain)
            }

            Text(rule.explanationPersian.isEmpty ? rule.explanation : rule.explanationPersian)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(isExpanded ? nil : 2)
                .multilineTextAlignment(.leading)

            if isExpanded {
                if !rule.formula.isEmpty {
                    Text(rule.formula)
                        .font(.system(.subheadline, design: .monospaced))
                        .padding(8)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(style.background)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }

                if !rule.examples.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        Label("Englische Beispiele", systemImage: "text.quote")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(.secondary)
                        ForEach(rule.examples.prefix(3)) { example in
                            Text("• \(example.english)")
                                .font(.subheadline)
                        }
                    }
                }

                if !rule.tips.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        Label("Wichtige Hinweise", systemImage: "lightbulb.fill")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(style.accent)
                        ForEach(rule.tips.prefix(3), id: \.self) { tip in
                            Text("- \(tip)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }

            Button(action: onToggleExpanded) {
                HStack {
                    Text(isExpanded ? "Weniger anzeigen" : "Mehr anzeigen")
                    Spacer()
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
        }
        .padding()
        .background(
            LinearGradient(
                colors: [style.background.opacity(0.55), Color(uiColor: .systemBackground)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(style.accent.opacity(0.2), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .animation(.easeInOut(duration: 0.2), value: isExpanded)
    }
}

private struct GrammarCategoryStyle {
    let accent: Color
    let background: Color
}

private func grammarCategoryStyle(_ category: GrammarCategory) -> GrammarCategoryStyle {
    switch category {
    case .tenses, .conditionals:
        return GrammarCategoryStyle(accent: .indigo, background: .indigo.opacity(0.18))
    case .articles, .pronouns, .questions:
        return GrammarCategoryStyle(accent: .orange, background: .orange.opacity(0.18))
    case .prepositions, .conjunctions, .reportedSpeech:
        return GrammarCategoryStyle(accent: .teal, background: .teal.opacity(0.18))
    case .modals, .passiveVoice:
        return GrammarCategoryStyle(accent: .purple, background: .purple.opacity(0.18))
    default:
        return GrammarCategoryStyle(accent: .accentColor, background: .accentColor.opacity(0.16))
    }
}

