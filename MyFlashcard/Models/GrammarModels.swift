import Foundation

// MARK: - Grammar Category

/// Enum aller verfügbaren Grammatik-Kategorien.
/// Jede Case bildet einen eigenständigen Lernbereich ab.
enum GrammarCategory: String, CaseIterable, Codable {
    case tenses         = "Tenses"
    case articles       = "Articles"
    case prepositions   = "Prepositions"
    case pronouns       = "Pronouns"
    case adjectives     = "Adjectives"
    case adverbs        = "Adverbs"
    case conjunctions   = "Conjunctions"
    case modals         = "Modal Verbs"
    case conditionals   = "Conditionals"
    case passiveVoice   = "Passive Voice"
    case reportedSpeech = "Reported Speech"
    case questions      = "Questions"
    case negation       = "Negation"
    case comparatives   = "Comparatives"
    case phrasalVerbs   = "Phrasal Verbs"

    var localizedTitle: String {
        switch self {
        case .tenses:         return "Zeitformen"
        case .articles:       return "Artikel"
        case .prepositions:   return "Präpositionen"
        case .pronouns:       return "Pronomen"
        case .adjectives:     return "Adjektive"
        case .adverbs:        return "Adverbien"
        case .conjunctions:   return "Konjunktionen"
        case .modals:         return "Modalverben"
        case .conditionals:   return "Konditionalsätze"
        case .passiveVoice:   return "Passiv"
        case .reportedSpeech: return "Indirekte Rede"
        case .questions:      return "Fragen"
        case .negation:       return "Verneinung"
        case .comparatives:   return "Vergleiche"
        case .phrasalVerbs:   return "Phrasal Verbs"
        }
    }

    var icon: String {
        switch self {
        case .tenses:         return "clock"
        case .articles:       return "a.circle"
        case .prepositions:   return "arrow.up.arrow.down"
        case .pronouns:       return "person.2"
        case .adjectives:     return "paintpalette"
        case .adverbs:        return "hare"
        case .conjunctions:   return "link"
        case .modals:         return "questionmark.diamond"
        case .conditionals:   return "arrow.triangle.branch"
        case .passiveVoice:   return "arrow.left.arrow.right"
        case .reportedSpeech: return "quote.bubble"
        case .questions:      return "questionmark.circle"
        case .negation:       return "xmark.circle"
        case .comparatives:   return "greaterthan.circle"
        case .phrasalVerbs:   return "text.word.spacing"
        }
    }
}

// MARK: - Grammar Rule

/// Eine einzelne Grammatikregel mit mehrsprachiger Erklärung,
/// Formel, Beispielen und Lerntipps.
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

// MARK: - Grammar Example

/// Ein Beispielsatz für eine Grammatikregel.
/// `isCorrect: false` wird für fehlerhafte Beispiele (mit Korrektur) verwendet.
struct GrammarExample: Identifiable, Codable {
    let id: UUID
    let english: String
    let german: String
    let persian: String
    let isCorrect: Bool
    let correction: String?

    init(
        english: String,
        german: String = "",
        persian: String = "",
        isCorrect: Bool = true,
        correction: String? = nil
    ) {
        self.id = UUID()
        self.english = english
        self.german = german
        self.persian = persian
        self.isCorrect = isCorrect
        self.correction = correction
    }
}
