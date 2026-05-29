import Foundation
import SwiftData
import Combine

/// Vocabulary Model - Represents a vocabulary entry
@Model
final class Vocabulary {
    var id: UUID = UUID()
    var englishWord: String = ""
    var german: String = ""
    var persian: String = ""
    var exampleSentence: String = ""
    var timesReviewed: Int = 0
    var timesCorrect: Int = 0
    var lastReviewedAt: Date?
    var isLearned: Bool = false
    var createdAt: Date = Date()

    // SRS (SM-2) fields
    var srsInterval: Int = 1        // days until next review
    var srsEaseFactor: Double = 2.5 // difficulty factor (1.3 – 5.0)
    var srsRepetitions: Int = 0     // consecutive correct answers
    var srsNextReview: Date?    // scheduled next review date

    // Tags & CEFR level
    var tags: String = ""      // comma-separated tags e.g. "travel,food"
    var cefrLevel: String = "" // A1, A2, B1, B2, C1, C2

    // Extra context sentences (semicolon-separated)
    var contextSentences: String = ""

    init(
        englishWord: String,
        german: String,
        persian: String,
        exampleSentence: String = "",
        timesReviewed: Int = 0,
        timesCorrect: Int = 0,
        lastReviewedAt: Date? = nil,
        isLearned: Bool = false,
        tags: String = "",
        cefrLevel: String = "",
        contextSentences: String = ""
    ) {
        self.id = UUID()
        self.englishWord = englishWord
        self.german = german
        self.persian = persian
        self.exampleSentence = exampleSentence
        self.timesReviewed = timesReviewed
        self.timesCorrect = timesCorrect
        self.lastReviewedAt = lastReviewedAt
        self.isLearned = isLearned
        self.createdAt = Date()
        self.srsInterval = 1
        self.srsEaseFactor = 2.5
        self.srsRepetitions = 0
        self.srsNextReview = nil
        self.tags = tags
        self.cefrLevel = cefrLevel
        self.contextSentences = contextSentences
    }

    /// Accuracy percentage
    var accuracy: Int {
        guard timesReviewed > 0 else { return 0 }
        return (timesCorrect * 100) / timesReviewed
    }

    /// Tag list
    var tagList: [String] {
        tags.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
    }

    /// Context sentence list
    var contextSentenceList: [String] {
        contextSentences.split(separator: ";").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
    }
}

/// Synonym Model - English word with synonyms and translations
@Model
final class Synonym {
    var id: UUID
    var mainWord: String           // e.g., "fix"
    var synonyms: String           // e.g., "repair, mend"
    var german: String
    var persian: String
    var exampleSentence: String
    var createdAt: Date
    
    init(
        mainWord: String,
        synonyms: String,
        german: String,
        persian: String,
        exampleSentence: String = ""
    ) {
        self.id = UUID()
        self.mainWord = mainWord
        self.synonyms = synonyms
        self.german = german
        self.persian = persian
        self.exampleSentence = exampleSentence
        self.createdAt = Date()
    }
    
    /// Combined display: "fix (repair, mend)"
    var displayWord: String {
        if synonyms.isEmpty {
            return mainWord
        }
        return "\(mainWord) (\(synonyms))"
    }
}

/// Parsed entry from bulk text import
struct ParsedEntry: Identifiable {
    let id = UUID()
    let englishWord: String
    let german: String
    let persian: String
    let exampleSentence: String
    var isValid: Bool {
        !englishWord.isEmpty && !german.isEmpty
    }
}

/// Parsed synonym entry
struct ParsedSynonymEntry: Identifiable {
    let id = UUID()
    let mainWord: String
    let synonyms: String
    let german: String
    let persian: String
    let exampleSentence: String
    var isValid: Bool {
        !mainWord.isEmpty && !german.isEmpty
    }
}

/// Quiz question types
enum QuestionType: CaseIterable {
    case englishToGerman
    case englishToPersian
    case germanToEnglish

    var title: String {
        switch self {
        case .englishToGerman: return "🇬🇧 → 🇩🇪"
        case .englishToPersian: return "🇬🇧 → 🇮🇷"
        case .germanToEnglish: return "🇩🇪 → 🇬🇧"
        }
    }

    var instruction: String {
        switch self {
        case .englishToGerman: return "Translate to German:"
        case .englishToPersian: return "Translate to Persian:"
        case .germanToEnglish: return "Translate to English:"
        }
    }
}

/// Quiz question model
struct QuizQuestion: Identifiable {
    let id = UUID()
    let vocabulary: Vocabulary
    let questionType: QuestionType
    let options: [String]
    let correctAnswer: String
    var userAnswer: String?
    var isCorrect: Bool?

    var questionText: String {
        switch questionType {
        case .englishToGerman, .englishToPersian:
            return vocabulary.englishWord
        case .germanToEnglish:
            return vocabulary.german
        }
    }
}
// MARK: - Grammar Models
/// Grammar Rule Category
enum GrammarCategory: String, CaseIterable, Codable {
    case tenses = "Tenses"
    case articles = "Articles"
    case prepositions = "Prepositions"
    case pronouns = "Pronouns"
    case adjectives = "Adjectives"
    case adverbs = "Adverbs"
    case conjunctions = "Conjunctions"
    case modals = "Modal Verbs"
    case conditionals = "Conditionals"
    case passiveVoice = "Passive Voice"
    case reportedSpeech = "Reported Speech"
    case questions = "Questions"
    case negation = "Negation"
    case comparatives = "Comparatives"
    case phrasalVerbs = "Phrasal Verbs"
    var icon: String {
        switch self {
        case .tenses: return "clock"
        case .articles: return "a.circle"
        case .prepositions: return "arrow.up.arrow.down"
        case .pronouns: return "person.2"
        case .adjectives: return "paintpalette"
        case .adverbs: return "hare"
        case .conjunctions: return "link"
        case .modals: return "questionmark.diamond"
        case .conditionals: return "arrow.triangle.branch"
        case .passiveVoice: return "arrow.left.arrow.right"
        case .reportedSpeech: return "quote.bubble"
        case .questions: return "questionmark.circle"
        case .negation: return "xmark.circle"
        case .comparatives: return "greaterthan.circle"
        case .phrasalVerbs: return "text.word.spacing"
        }
    }
}
/// Grammar Rule
struct GrammarRule: Identifiable, Codable {
    let id: UUID
    let category: GrammarCategory
    let title: String
    let titleGerman: String
    let titlePersian: String
    let explanation: String
    let explanationGerman: String
    let explanationPersian: String
    let formula: String
    let examples: [GrammarExample]
    let tips: [String]
    init(
        category: GrammarCategory,
        title: String,
        titleGerman: String = "",
        titlePersian: String = "",
        explanation: String,
        explanationGerman: String = "",
        explanationPersian: String = "",
        formula: String = "",
        examples: [GrammarExample] = [],
        tips: [String] = []
    ) {
        self.id = UUID()
        self.category = category
        self.title = title
        self.titleGerman = titleGerman
        self.titlePersian = titlePersian
        self.explanation = explanation
        self.explanationGerman = explanationGerman
        self.explanationPersian = explanationPersian
        self.formula = formula
        self.examples = examples
        self.tips = tips
    }
}
/// Grammar Example
struct GrammarExample: Identifiable, Codable {
    let id: UUID
    let english: String
    let german: String
    let persian: String
    let isCorrect: Bool
    let correction: String?
    init(english: String, german: String = "", persian: String = "", isCorrect: Bool = true, correction: String? = nil) {
        self.id = UUID()
        self.english = english
        self.german = german
        self.persian = persian
        self.isCorrect = isCorrect
        self.correction = correction
    }
}
// MARK: - Text Analysis Models
/// Word with analysis info
struct AnalyzedWord: Identifiable {
    let id = UUID()
    let word: String
    let partOfSpeech: PartOfSpeech
    let lemma: String
    let language: String
}
/// Part of Speech
enum PartOfSpeech: String, CaseIterable {
    case noun = "Noun"
    case verb = "Verb"
    case adjective = "Adjective"
    case adverb = "Adverb"
    case pronoun = "Pronoun"
    case preposition = "Preposition"
    case conjunction = "Conjunction"
    case determiner = "Determiner"
    case interjection = "Interjection"
    case unknown = "Unknown"
    var color: String {
        switch self {
        case .noun: return "blue"
        case .verb: return "red"
        case .adjective: return "green"
        case .adverb: return "orange"
        case .pronoun: return "purple"
        case .preposition: return "pink"
        case .conjunction: return "yellow"
        case .determiner: return "cyan"
        case .interjection: return "mint"
        case .unknown: return "gray"
        }
    }
    var germanName: String {
        switch self {
        case .noun: return "Nomen"
        case .verb: return "Verb"
        case .adjective: return "Adjektiv"
        case .adverb: return "Adverb"
        case .pronoun: return "Pronomen"
        case .preposition: return "Präposition"
        case .conjunction: return "Konjunktion"
        case .determiner: return "Artikel"
        case .interjection: return "Interjektion"
        case .unknown: return "Unbekannt"
        }
    }
}
/// Text Analysis Result
struct TextAnalysisResult {
    let originalText: String
    let words: [AnalyzedWord]
    let sentences: Int
    let wordCount: Int
    let characterCount: Int
    let detectedLanguage: String
    let grammarIssues: [GrammarIssue]
}
/// Grammar Issue found in text
struct GrammarIssue: Identifiable {
    let id = UUID()
    let word: String
    let issue: String
    let suggestion: String
    let position: Int
    let type: IssueType

    init(word: String, issue: String, suggestion: String, position: Int, type: IssueType = .grammar) {
        self.word = word
        self.issue = issue
        self.suggestion = suggestion
        self.position = position
        self.type = type
    }
}

/// Type of text analysis issue
enum IssueType: String, CaseIterable {
    case spelling = "Spelling"
    case grammar = "Grammar"
    case structure = "Sentence Structure"
    case suggestion = "Improvement"

    var germanName: String {
        switch self {
        case .spelling: return "Rechtschreibung"
        case .grammar: return "Grammatik"
        case .structure: return "Satzbau"
        case .suggestion: return "Verbesserungsvorschlag"
        }
    }

    var icon: String {
        switch self {
        case .spelling: return "textformat.abc.dottedunderline"
        case .grammar: return "exclamationmark.triangle"
        case .structure: return "text.alignleft"
        case .suggestion: return "lightbulb"
        }
    }
}

// MARK: - Shared AI -> Grammar recommendations
@MainActor
final class GrammarRecommendationStore: ObservableObject {
    static let shared = GrammarRecommendationStore()

    @Published private(set) var topics: [String]

    private let defaults = UserDefaults.standard
    private let key = "grammar.recommended.topics"

    private init() {
        self.topics = defaults.stringArray(forKey: key) ?? []
    }

    func setTopics(_ values: [String]) {
        let normalized = values
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        topics = Array(NSOrderedSet(array: normalized)) as? [String] ?? normalized
        defaults.set(topics, forKey: key)
    }

    func clear() {
        topics = []
        defaults.removeObject(forKey: key)
    }
}

