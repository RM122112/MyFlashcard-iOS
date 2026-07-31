import Foundation

// MARK: - Part of Speech

/// Wortart eines analysierten Wortes.
/// Wird bei der grammatikalischen Textanalyse verwendet.
enum PartOfSpeech: String, CaseIterable {
    case noun         = "Noun"
    case verb         = "Verb"
    case adjective    = "Adjective"
    case adverb       = "Adverb"
    case pronoun      = "Pronoun"
    case preposition  = "Preposition"
    case conjunction  = "Conjunction"
    case determiner   = "Determiner"
    case interjection = "Interjection"
    case unknown      = "Unknown"

    /// Farb-Token für UI-Darstellung.
    var color: String {
        switch self {
        case .noun:         return "blue"
        case .verb:         return "red"
        case .adjective:    return "green"
        case .adverb:       return "orange"
        case .pronoun:      return "purple"
        case .preposition:  return "pink"
        case .conjunction:  return "yellow"
        case .determiner:   return "cyan"
        case .interjection: return "mint"
        case .unknown:      return "gray"
        }
    }

    var germanName: String {
        switch self {
        case .noun:         return "Nomen"
        case .verb:         return "Verb"
        case .adjective:    return "Adjektiv"
        case .adverb:       return "Adverb"
        case .pronoun:      return "Pronomen"
        case .preposition:  return "Präposition"
        case .conjunction:  return "Konjunktion"
        case .determiner:   return "Artikel"
        case .interjection: return "Interjektion"
        case .unknown:      return "Unbekannt"
        }
    }
}

// MARK: - Analyzed Word

/// Ein analysiertes Wort mit grammatikalischen Metadaten.
struct AnalyzedWord: Identifiable {
    let id = UUID()
    let word: String
    let partOfSpeech: PartOfSpeech
    let lemma: String
    let language: String
}

// MARK: - Issue Type

/// Art eines gefundenen Sprachproblems im Analysetext.
enum IssueType: String, CaseIterable {
    case spelling   = "Spelling"
    case grammar    = "Grammar"
    case structure  = "Sentence Structure"
    case suggestion = "Improvement"

    var germanName: String {
        switch self {
        case .spelling:   return "Rechtschreibung"
        case .grammar:    return "Grammatik"
        case .structure:  return "Satzbau"
        case .suggestion: return "Verbesserungsvorschlag"
        }
    }

    var icon: String {
        switch self {
        case .spelling:   return "textformat.abc.dottedunderline"
        case .grammar:    return "exclamationmark.triangle"
        case .structure:  return "text.alignleft"
        case .suggestion: return "lightbulb"
        }
    }
}

// MARK: - Grammar Issue

/// Ein einzelnes Sprachproblem (Fehler oder Verbesserungsvorschlag) in einem Text.
struct GrammarIssue: Identifiable {
    let id = UUID()
    let word: String
    let issue: String
    let suggestion: String
    let position: Int
    let type: IssueType

    init(
        word: String,
        issue: String,
        suggestion: String,
        position: Int,
        type: IssueType = .grammar
    ) {
        self.word = word
        self.issue = issue
        self.suggestion = suggestion
        self.position = position
        self.type = type
    }
}

// MARK: - Text Analysis Result

/// Vollständiges Ergebnis einer Textanalyse-Sitzung.
struct TextAnalysisResult {
    let originalText: String
    let words: [AnalyzedWord]
    let sentences: Int
    let wordCount: Int
    let characterCount: Int
    let detectedLanguage: String
    let grammarIssues: [GrammarIssue]
    let cefrEstimate: String
    let weaknessAreas: [String]
    let recommendedExercises: [String]
}
