import SwiftUI
import SwiftData

struct QuizView: View {
    @Query private var vocabulary: [Vocabulary]
    @Environment(\.modelContext) private var modelContext
    @StateObject private var speechService = SpeechService.shared
    
    @State private var questions: [QuizQuestion] = []
    @State private var currentIndex = 0
    @State private var correctCount = 0
    @State private var isFinished = false

    private var prioritizedVocabulary: [Vocabulary] {
        // Normalize word ages without mutation in computed property
        for vocab in vocabulary {
            let normalized = LearningStatusHelper.normalizedStatus(for: vocab)
            if normalized != vocab.wordStatusValue {
                vocab.wordStatusValue = normalized
            }
        }
        return vocabulary.sorted { SRSService.reviewPriority(for: $0) > SRSService.reviewPriority(for: $1) }
    }

    var body: some View {
        NavigationStack {
            VStack {
                if prioritizedVocabulary.count < 4 {
                    ContentUnavailableView(
                        "Zu wenig Wörter für ein Quiz",
                        systemImage: "questionmark.circle",
                        description: Text("Füge mindestens 4 Wörter hinzu, um ein Quiz zu starten.")
                    )
                } else if isFinished {
                    QuizResultView(
                        correct: correctCount,
                        total: questions.count,
                        onRestart: startNewQuiz
                    )
                } else if questions.isEmpty {
                    Button("Quiz starten") {
                        startNewQuiz()
                    }
                    .buttonStyle(.borderedProminent)
                } else {
                    // Progress
                    ProgressView(value: Double(currentIndex + 1), total: Double(questions.count))
                        .padding(.horizontal)

                    Text("Unbekannte Wörter werden bevorzugt wiederholt.")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    HStack {
                        Text("✅ \(correctCount)")
                            .foregroundColor(.green)
                        Spacer()
                        Text("Frage \(currentIndex + 1) / \(questions.count)")
                        Spacer()
                        Text("❌ \(currentIndex - correctCount)")
                            .foregroundColor(.red)
                    }
                    .padding(.horizontal)
                    
                    QuizQuestionView(
                        question: $questions[currentIndex],
                        speechService: speechService,
                        onAnswer: handleAnswer,
                        onNext: nextQuestion
                    )
                }
            }
            .navigationTitle("📝 Quiz")
            .toolbar {
                Button(action: startNewQuiz) {
                    Image(systemName: "arrow.clockwise")
                }
            }
        }
    }
    
    private func startNewQuiz() {
        questions = generateQuestions()
        currentIndex = 0
        correctCount = 0
        isFinished = false
    }
    
    private func generateQuestions() -> [QuizQuestion] {
        let shuffled = prioritizedVocabulary
        var result: [QuizQuestion] = []
        
        for vocab in shuffled.prefix(10) {
            let questionType = QuestionType.allCases.randomElement()!
            let correctAnswer: String
            
            switch questionType {
            case .englishToGerman:
                correctAnswer = vocab.german
            case .englishToPersian:
                correctAnswer = vocab.persian
            case .germanToEnglish:
                correctAnswer = vocab.englishWord
            }
            
            var options = [correctAnswer]
            let others = shuffled.filter { $0.id != vocab.id }.shuffled()
            
            for other in others.prefix(3) {
                let option: String
                switch questionType {
                case .englishToGerman:
                    option = other.german
                case .englishToPersian:
                    option = other.persian
                case .germanToEnglish:
                    option = other.englishWord
                }
                options.append(option)
            }
            
            result.append(QuizQuestion(
                vocabulary: vocab,
                questionType: questionType,
                options: options.shuffled(),
                correctAnswer: correctAnswer
            ))
        }
        
        return result
    }
    
    private func handleAnswer(_ answer: String) {
        questions[currentIndex].userAnswer = answer
        let isCorrect = answer == questions[currentIndex].correctAnswer
        questions[currentIndex].isCorrect = isCorrect
        
        let vocab = questions[currentIndex].vocabulary
        if isCorrect {
            correctCount += 1
        }
        SRSService.applyReview(to: vocab, quality: isCorrect ? .perfect : .incorrect_hard)

        try? modelContext.save()
    }
    
    private func nextQuestion() {
        if currentIndex < questions.count - 1 {
            currentIndex += 1
        } else {
            isFinished = true
        }
    }
}

struct QuizQuestionView: View {
    @Binding var question: QuizQuestion
    let speechService: SpeechService
    let onAnswer: (String) -> Void
    let onNext: () -> Void
    
    var hasAnswered: Bool { question.userAnswer != nil }
    
    var body: some View {
        VStack(spacing: 20) {
            Text(question.questionType.title)
                .font(.title)
            
            Text(question.questionType.instruction)
                .font(.subheadline)
            
            // Question Card
            VStack {
                Text(question.questionText)
                    .font(.title)
                    .fontWeight(.bold)
                    .padding()
                
                if question.questionType == .englishToGerman || 
                   question.questionType == .englishToPersian {
                    Button(action: {
                        speechService.speak(question.vocabulary.englishWord)
                    }) {
                        Label("Anhören", systemImage: "speaker.wave.2.fill")
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.blue.opacity(0.1))
            .cornerRadius(12)
            
            // Options
            ForEach(question.options, id: \.self) { option in
                Button(action: {
                    if !hasAnswered {
                        onAnswer(option)
                    }
                }) {
                    HStack {
                        Text(option)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        if hasAnswered {
                            if option == question.correctAnswer {
                                HStack {
                                    if question.questionType == .germanToEnglish {
                                        Button(action: {
                                            speechService.speak(question.vocabulary.englishWord)
                                        }) {
                                            Image(systemName: "speaker.wave.2")
                                        }
                                    }
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                }
                            } else if option == question.userAnswer {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.red)
                            }
                        }
                    }
                    .padding()
                    .background(optionBackground(option))
                    .cornerRadius(8)
                }
                .buttonStyle(.plain)
                .disabled(hasAnswered)
            }
            
            if hasAnswered {
                Button(action: onNext) {
                    Label("Weiter", systemImage: "arrow.right")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
            }
            
            Spacer()
        }
        .padding()
    }
    
    private func optionBackground(_ option: String) -> Color {
        guard hasAnswered else { return Color.gray.opacity(0.1) }
        if option == question.correctAnswer { return Color.green.opacity(0.2) }
        if option == question.userAnswer { return Color.red.opacity(0.2) }
        return Color.gray.opacity(0.1)
    }
}

struct QuizResultView: View {
    let correct: Int
    let total: Int
    let onRestart: () -> Void
    
    var percentage: Int {
        total > 0 ? (correct * 100) / total : 0
    }
    
    var emoji: String {
        switch percentage {
        case 90...100: return "🏆"
        case 70..<90: return "🎉"
        case 50..<70: return "👍"
        default: return "📚"
        }
    }
    
    var body: some View {
        VStack(spacing: 20) {
            Text(emoji)
                .font(.system(size: 80))
            
            Text(percentage >= 70 ? "Stark gemacht!" : "Weiter so – Übung lohnt sich!")
                .font(.title)
                .fontWeight(.bold)
            
            Text("\(correct) von \(total) richtig")
                .font(.title2)
            
            Text("\(percentage)%")
                .font(.system(size: 60))
                .fontWeight(.bold)
                .foregroundColor(.blue)
            
            Button(action: onRestart) {
                Label("Noch einmal", systemImage: "arrow.clockwise")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .padding()
        }
    }
}
