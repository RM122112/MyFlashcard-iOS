import SwiftUI
import SwiftData

// MARK: - QuizViewModel

/// ViewModel für den Quiz-Screen (Multiple Choice).
///
/// Erstellt einen Quiz-Durchlauf aus bis zu 10 Vokabeln,
/// sortiert nach SRS-Review-Priorität.
/// Das Ergebnis jeder Frage wird direkt ins SRS zurückgeschrieben.
@MainActor
@Observable
class QuizViewModel {
    var questions: [QuizQuestion] = []
    var currentIndex: Int = 0
    var isFinished: Bool = false
    var correctCount: Int = 0
    var incorrectCount: Int = 0

    // MARK: - Quiz Setup

    /// Startet einen neuen Quiz-Durchlauf.
    /// Mindestens 4 Vokabeln sind erforderlich, um Antwortoptionen zu generieren.
    func startNewQuiz(vocabulary: [Vocabulary]) {
        guard vocabulary.count >= 4 else {
            questions = []
            return
        }

        SRSService.normalizeWordAges(for: vocabulary)
        let shuffled = vocabulary
            .shuffled()
            .sorted { SRSService.reviewPriority(for: $0) > SRSService.reviewPriority(for: $1) }
        let selected = Array(shuffled.prefix(10))

        questions = selected.map { vocab in
            let questionType = QuestionType.allCases.randomElement()!
            return makeQuestion(vocab: vocab, type: questionType, allVocab: vocabulary)
        }

        currentIndex  = 0
        isFinished    = false
        correctCount  = 0
        incorrectCount = 0
    }

    // MARK: - Answer Handling

    /// Wertet die gewählte Antwort aus und aktualisiert den SRS-Eintrag.
    func selectAnswer(_ answer: String, modelContext: ModelContext) {
        guard currentIndex < questions.count else { return }

        let isCorrect = answer == questions[currentIndex].correctAnswer
        questions[currentIndex].userAnswer = answer
        questions[currentIndex].isCorrect  = isCorrect

        if isCorrect {
            correctCount += 1
        } else {
            incorrectCount += 1
        }

        let vocab = questions[currentIndex].vocabulary
        SRSService.applyReview(to: vocab, quality: isCorrect ? .perfect : .incorrect_hard, modelContext: modelContext)
        do {
            try modelContext.save()
        } catch {
            print("[QuizViewModel] Speichern fehlgeschlagen: \(error.localizedDescription)")
        }
    }

    func nextQuestion() {
        if currentIndex < questions.count - 1 {
            currentIndex += 1
        } else {
            isFinished = true
        }
    }

    // MARK: - Computed

    var currentQuestion: QuizQuestion? {
        guard currentIndex < questions.count else { return nil }
        return questions[currentIndex]
    }

    var hasAnswered: Bool {
        currentQuestion?.userAnswer != nil
    }

    /// Prozentualer Anteil korrekter Antworten (0–100).
    var scorePercent: Int {
        let total = correctCount + incorrectCount
        guard total > 0 else { return 0 }
        return (correctCount * 100) / total
    }

    // MARK: - Private Helpers

    private func makeQuestion(vocab: Vocabulary, type: QuestionType, allVocab: [Vocabulary]) -> QuizQuestion {
        let correctAnswer: String = {
            switch type {
            case .englishToGerman:  return vocab.german
            case .englishToPersian: return vocab.persian
            case .germanToEnglish:  return vocab.englishWord
            }
        }()

        let wrongOptions = allVocab
            .filter { $0.id != vocab.id }
            .shuffled()
            .prefix(3)
            .map { wrong -> String in
                switch type {
                case .englishToGerman:  return wrong.german
                case .englishToPersian: return wrong.persian
                case .germanToEnglish:  return wrong.englishWord
                }
            }

        let options = (wrongOptions + [correctAnswer]).shuffled()

        return QuizQuestion(
            vocabulary:    vocab,
            questionType:  type,
            options:       options,
            correctAnswer: correctAnswer
        )
    }
}
