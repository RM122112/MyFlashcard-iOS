import Foundation

// MARK: - Quiz Question Type

/// Richtung der Quiz-Frage (Übersetzungsrichtung).
enum QuestionType: CaseIterable {
    case englishToGerman
    case englishToPersian
    case germanToEnglish

    var title: String {
        switch self {
        case .englishToGerman:  return "🇬🇧 → 🇩🇪"
        case .englishToPersian: return "🇬🇧 → 🇦🇫"
        case .germanToEnglish:  return "🇩🇪 → 🇬🇧"
        }
    }

    var instruction: String {
        switch self {
        case .englishToGerman:  return "Übersetze ins Deutsche:"
        case .englishToPersian: return "Übersetze ins Persische:"
        case .germanToEnglish:  return "Übersetze ins Englische:"
        }
    }
}

// MARK: - Quiz Question

/// Eine einzelne Multiple-Choice-Quizfrage mit Antwortoptionen.
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
