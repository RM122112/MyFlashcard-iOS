import Foundation
import SwiftData

// MARK: - Word Status

/// Lernstatus eines Vokabeleintrags.
///
/// - `newWord`: Kürzlich hinzugefügt (< 30 Tage).
/// - `oldWord`: Schon länger vorhanden (≥ 30 Tage), aber noch nicht vollständig gelernt.
/// - `knownWord`: Erfolgreich gelernt (≥ 4 korrekte SRS-Wiederholungen).
/// - `unknownWord`: Mehrfach falsch beantwortet – hohe Review-Priorität.
enum WordStatus: String, CaseIterable, Codable {
    case newWord     = "NEW_WORD"
    case oldWord     = "OLD_WORD"
    case knownWord   = "KNOWN_WORD"
    case unknownWord = "UNKNOWN_WORD"

    var title: String {
        switch self {
        case .newWord:     return "Neue Wörter"
        case .oldWord:     return "Alte Wörter"
        case .knownWord:   return "Bekannte Wörter"
        case .unknownWord: return "Unbekannte Wörter"
        }
    }
}

// MARK: - Learning Status Helper

/// Berechnungslogik für den Lernstatus und die Review-Priorität.
///
/// Kapselt die Regeln, wann ein Wort als "alt", "bekannt" oder "unbekannt"
/// eingestuft wird. Wird von `SRSService` und ViewModels genutzt.
enum LearningStatusHelper {
    static let thirtyDays: TimeInterval = 30 * 24 * 60 * 60

    /// Gibt den korrekten Status zurück – berücksichtigt das Alter des Eintrags.
    static func normalizedStatus(for vocabulary: Vocabulary, now: Date = Date()) -> WordStatus {
        switch vocabulary.wordStatusValue {
        case .knownWord, .unknownWord:
            return vocabulary.wordStatusValue
        case .newWord, .oldWord:
            return now.timeIntervalSince(vocabulary.createdAt) >= thirtyDays ? .oldWord : .newWord
        }
    }

    /// Berechnet den neuen Status nach einem Review-Ergebnis.
    static func statusAfterReview(for vocabulary: Vocabulary, isCorrect: Bool, quality: Int, now: Date = Date()) -> WordStatus {
        let normalized = normalizedStatus(for: vocabulary, now: now)
        if !isCorrect || quality <= 2 { return .unknownWord }
        if quality >= 4 { return .knownWord }
        if normalized == .newWord, now.timeIntervalSince(vocabulary.createdAt) >= thirtyDays { return .oldWord }
        return normalized
    }

    /// Numerischer Prioritätswert für die Review-Reihenfolge.
    /// Höherer Wert = wird zuerst angezeigt.
    static func reviewPriority(for vocabulary: Vocabulary, now: Date = Date()) -> Int {
        let status = normalizedStatus(for: vocabulary, now: now)
        let dueBoost            = (vocabulary.srsNextReview == nil || vocabulary.srsNextReview! <= now) ? 12 : 0
        let weaknessBoost       = max(vocabulary.timesReviewed - vocabulary.timesCorrect, 0)
        let recentFailuresBoost = vocabulary.failedReviewCount * 2
        let consecutiveBoost    = vocabulary.consecutiveFailures * 4
        switch status {
        case .unknownWord: return 100 + dueBoost + weaknessBoost + recentFailuresBoost + consecutiveBoost
        case .oldWord:     return 70  + dueBoost + weaknessBoost + recentFailuresBoost + consecutiveBoost
        case .newWord:     return 55  + dueBoost + weaknessBoost + recentFailuresBoost
        case .knownWord:   return 25  + dueBoost
        }
    }
}

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
    var wordStatus: String = WordStatus.newWord.rawValue
    var lastQuizCorrect: Bool?
    var lastStatusChangedAt: Date?
    var failedReviewCount: Int = 0
    var consecutiveFailures: Int = 0
    var lastFailedAt: Date?
    var recentFailureDates: String = ""
    var ipaPronunciation: String = ""

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
        contextSentences: String = "",
        wordStatus: WordStatus = .newWord,
        lastQuizCorrect: Bool? = nil,
        lastStatusChangedAt: Date? = nil,
        failedReviewCount: Int = 0,
        consecutiveFailures: Int = 0,
        lastFailedAt: Date? = nil,
        recentFailureDates: String = "",
        ipaPronunciation: String = ""
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
        self.wordStatus = wordStatus.rawValue
        self.lastQuizCorrect = lastQuizCorrect
        self.lastStatusChangedAt = lastStatusChangedAt
        self.failedReviewCount = failedReviewCount
        self.consecutiveFailures = consecutiveFailures
        self.lastFailedAt = lastFailedAt
        self.recentFailureDates = recentFailureDates
        self.ipaPronunciation = ipaPronunciation
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

    var wordStatusValue: WordStatus {
        get { WordStatus(rawValue: wordStatus) ?? .newWord }
        set { wordStatus = newValue.rawValue }
    }

    /// Tag list
    var tagList: [String] {
        tags.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
    }

    /// Context sentence list
    var contextSentenceList: [String] {
        contextSentences.split(separator: ";").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
    }

    /// ISO-8601 encoded failure dates (kept small for lightweight analytics)
    var recentFailureDateList: [Date] {
        let parser = ISO8601DateFormatter()
        return recentFailureDates
            .split(separator: ",")
            .compactMap { parser.date(from: String($0)) }
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



