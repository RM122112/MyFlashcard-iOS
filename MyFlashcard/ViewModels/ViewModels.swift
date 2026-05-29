import SwiftUI
import SwiftData

/// ViewModel für Browse-Screen
@MainActor
@Observable
class BrowseViewModel {
    var searchText: String = ""
    var vocabularyToDelete: Vocabulary?
    var showDeleteAlert: Bool = false

    func deleteVocabulary(_ vocabulary: Vocabulary, modelContext: ModelContext) {
        modelContext.delete(vocabulary)
        try? modelContext.save()
    }

    func filteredVocabulary(_ allVocabulary: [Vocabulary]) -> [Vocabulary] {
        if searchText.isEmpty {
            return allVocabulary.sorted { $0.englishWord < $1.englishWord }
        }
        let query = searchText.lowercased()
        return allVocabulary.filter { vocab in
            vocab.englishWord.lowercased().contains(query) ||
            vocab.german.lowercased().contains(query) ||
            vocab.persian.contains(query) ||
            vocab.exampleSentence.lowercased().contains(query)
        }.sorted { $0.englishWord < $1.englishWord }
    }
}

/// ViewModel für Input-Screen
@MainActor
@Observable
class InputViewModel {
    // Single entry
    var englishWord: String = ""
    var german: String = ""
    var persian: String = ""
    var exampleSentence: String = ""

    // Bulk import
    var bulkText: String = ""
    var isBulkMode: Bool = true
    var parsedEntries: [ParsedEntry] = []

    // State
    var isEditing: Bool = false
    var editingVocabulary: Vocabulary?
    var isSaving: Bool = false
    var error: String?
    var importedCount: Int = 0
    var showSuccessAlert: Bool = false

    func toggleMode() {
        isBulkMode.toggle()
        error = nil
    }

    func setBulkText(_ text: String) {
        bulkText = text
        error = nil
        parsedEntries = TextParser.parseText(text)
    }

    func loadForEditing(_ vocabulary: Vocabulary) {
        editingVocabulary = vocabulary
        englishWord = vocabulary.englishWord
        german = vocabulary.german
        persian = vocabulary.persian
        exampleSentence = vocabulary.exampleSentence
        isEditing = true
        isBulkMode = false
    }

    func importBulk(modelContext: ModelContext) {
        let validEntries = parsedEntries.filter { $0.isValid }

        guard !validEntries.isEmpty else {
            error = "No valid entries to import"
            return
        }

        isSaving = true
        error = nil

        var count = 0
        for entry in validEntries {
            let vocabulary = Vocabulary(
                englishWord: entry.englishWord,
                german: entry.german,
                persian: entry.persian,
                exampleSentence: entry.exampleSentence
            )
            modelContext.insert(vocabulary)
            count += 1
        }

        try? modelContext.save()
        importedCount = count
        isSaving = false
        showSuccessAlert = true
        clearForm()
    }

    func save(modelContext: ModelContext) -> Bool {
        // Validation
        guard !englishWord.trimmingCharacters(in: .whitespaces).isEmpty else {
            error = "English word is required"
            return false
        }
        guard !german.trimmingCharacters(in: .whitespaces).isEmpty else {
            error = "German translation is required"
            return false
        }
        guard !persian.trimmingCharacters(in: .whitespaces).isEmpty else {
            error = "Persian translation is required"
            return false
        }

        isSaving = true
        error = nil

        if isEditing, let vocab = editingVocabulary {
            vocab.englishWord = englishWord.trimmingCharacters(in: .whitespaces)
            vocab.german = german.trimmingCharacters(in: .whitespaces)
            vocab.persian = persian.trimmingCharacters(in: .whitespaces)
            vocab.exampleSentence = exampleSentence.trimmingCharacters(in: .whitespaces)
        } else {
            let vocabulary = Vocabulary(
                englishWord: englishWord.trimmingCharacters(in: .whitespaces),
                german: german.trimmingCharacters(in: .whitespaces),
                persian: persian.trimmingCharacters(in: .whitespaces),
                exampleSentence: exampleSentence.trimmingCharacters(in: .whitespaces)
            )
            modelContext.insert(vocabulary)
        }

        try? modelContext.save()
        importedCount = 1
        isSaving = false
        showSuccessAlert = true
        clearForm()
        return true
    }

    func clearForm() {
        englishWord = ""
        german = ""
        persian = ""
        exampleSentence = ""
        bulkText = ""
        parsedEntries = []
        isEditing = false
        editingVocabulary = nil
        error = nil
    }
}

/// ViewModel für Flashcard-Screen
@MainActor
@Observable
class FlashcardViewModel {
    var cards: [Vocabulary] = []
    var currentIndex: Int = 0
    var isFlipped: Bool = false

    func loadCards(_ vocabulary: [Vocabulary]) {
        cards = vocabulary.shuffled()
        currentIndex = 0
        isFlipped = false
    }

    func shuffleCards() {
        cards.shuffle()
        currentIndex = 0
        isFlipped = false
    }

    func flipCard() {
        isFlipped.toggle()
    }

    func nextCard() {
        if currentIndex < cards.count - 1 {
            currentIndex += 1
            isFlipped = false
        }
    }

    func previousCard() {
        if currentIndex > 0 {
            currentIndex -= 1
            isFlipped = false
        }
    }

    func markAsLearned(isCorrect: Bool, modelContext: ModelContext) {
        guard currentIndex < cards.count else { return }
        let card = cards[currentIndex]
        card.timesReviewed += 1
        if isCorrect {
            card.timesCorrect += 1
        }
        card.lastReviewedAt = Date()
        if card.timesCorrect >= 5 {
            card.isLearned = true
        }
        try? modelContext.save()
        nextCard()
    }

    var currentCard: Vocabulary? {
        guard currentIndex < cards.count else { return nil }
        return cards[currentIndex]
    }
}

/// ViewModel für Quiz-Screen
@MainActor
@Observable
class QuizViewModel {
    var questions: [QuizQuestion] = []
    var currentIndex: Int = 0
    var isFinished: Bool = false
    var correctCount: Int = 0
    var incorrectCount: Int = 0

    func startNewQuiz(vocabulary: [Vocabulary]) {
        guard vocabulary.count >= 4 else {
            questions = []
            return
        }

        let shuffled = vocabulary.shuffled()
        let selected = Array(shuffled.prefix(10))

        questions = selected.map { vocab in
            let questionType = QuestionType.allCases.randomElement()!
            return createQuestion(vocab: vocab, type: questionType, allVocab: vocabulary)
        }

        currentIndex = 0
        isFinished = false
        correctCount = 0
        incorrectCount = 0
    }

    private func createQuestion(vocab: Vocabulary, type: QuestionType, allVocab: [Vocabulary]) -> QuizQuestion {
        let correctAnswer: String
        switch type {
        case .englishToGerman: correctAnswer = vocab.german
        case .englishToPersian: correctAnswer = vocab.persian
        case .germanToEnglish: correctAnswer = vocab.englishWord
        }

        // Generate wrong options
        var wrongOptions = allVocab
            .filter { $0.id != vocab.id }
            .shuffled()
            .prefix(3)
            .map { wrongVocab -> String in
                switch type {
                case .englishToGerman: return wrongVocab.german
                case .englishToPersian: return wrongVocab.persian
                case .germanToEnglish: return wrongVocab.englishWord
                }
            }

        let options = (wrongOptions + [correctAnswer]).shuffled()

        return QuizQuestion(
            vocabulary: vocab,
            questionType: type,
            options: options,
            correctAnswer: correctAnswer
        )
    }

    func selectAnswer(_ answer: String, modelContext: ModelContext) {
        guard currentIndex < questions.count else { return }

        let isCorrect = answer == questions[currentIndex].correctAnswer
        questions[currentIndex].userAnswer = answer
        questions[currentIndex].isCorrect = isCorrect

        if isCorrect {
            correctCount += 1
        } else {
            incorrectCount += 1
        }

        // Update vocabulary progress
        let vocab = questions[currentIndex].vocabulary
        vocab.timesReviewed += 1
        if isCorrect {
            vocab.timesCorrect += 1
        }
        vocab.lastReviewedAt = Date()
        if vocab.timesCorrect >= 5 {
            vocab.isLearned = true
        }
        try? modelContext.save()
    }

    func nextQuestion() {
        if currentIndex < questions.count - 1 {
            currentIndex += 1
        } else {
            isFinished = true
        }
    }

    var currentQuestion: QuizQuestion? {
        guard currentIndex < questions.count else { return nil }
        return questions[currentIndex]
    }

    var hasAnswered: Bool {
        currentQuestion?.userAnswer != nil
    }
}

