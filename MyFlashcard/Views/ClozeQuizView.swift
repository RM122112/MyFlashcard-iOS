import SwiftUI
import SwiftData

/// Lückentext (Cloze) Quiz Modus
struct ClozeQuizView: View {
    @Query private var vocabulary: [Vocabulary]
    @Environment(\.modelContext) private var modelContext

    @State private var questions: [ClozeQuestion] = []
    @State private var currentIndex = 0
    @State private var userAnswer = ""
    @State private var showResult = false
    @State private var isCorrect = false
    @State private var correctCount = 0
    @State private var isFinished = false
    @FocusState private var focused: Bool

    var currentQ: ClozeQuestion? {
        guard currentIndex < questions.count else { return nil }
        return questions[currentIndex]
    }

    var body: some View {
        VStack(spacing: 20) {
            if vocabulary.isEmpty {
                ContentUnavailableView("No Words", systemImage: "text.badge.plus", description: Text("Add vocabulary first!"))
            } else if isFinished {
                resultView
            } else if questions.isEmpty {
                startView
            } else if let q = currentQ {
                quizCard(q)
            }
        }
        .padding()
    }

    // MARK: - Start
    private var startView: some View {
        VStack(spacing: 16) {
            Image(systemName: "text.badge.checkmark")
                .font(.system(size: 70))
                .foregroundColor(.purple)
            Text("Cloze Quiz")
                .font(.title).bold()
            Text("Fill in the blank with the correct word")
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            Button("Start") {
                generateQuestions()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
    }

    // MARK: - Card
    private func quizCard(_ q: ClozeQuestion) -> some View {
        VStack(spacing: 20) {
            ProgressView(value: Double(currentIndex + 1), total: Double(questions.count))
            HStack {
                Text("✅ \(correctCount)").foregroundColor(.green)
                Spacer()
                Text("\(currentIndex + 1) / \(questions.count)")
                Spacer()
                Text("❌ \(currentIndex - correctCount)").foregroundColor(.red)
            }
            .font(.subheadline)

            VStack(spacing: 16) {
                Text("Fill in the blank:")
                    .font(.caption)
                    .foregroundColor(.secondary)

                // Sentence with blank
                Text(clozeText(q))
                    .font(.title3)
                    .multilineTextAlignment(.center)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.purple.opacity(0.08))
                    .cornerRadius(12)

                // Translations as hint
                VStack(spacing: 4) {
                    Text("🇩🇪 \(q.vocab.german)")
                    Text("🇮🇷 \(q.vocab.persian)")
                        .environment(\.layoutDirection, .rightToLeft)
                }
                .font(.subheadline)
                .foregroundColor(.secondary)
                .padding(8)
                .background(Color(.secondarySystemBackground))
                .cornerRadius(8)
            }

            // Input
            TextField("Type the missing word...", text: $userAnswer)
                .textFieldStyle(.roundedBorder)
                .font(.title2)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .focused($focused)
                .onSubmit { checkAnswer(q) }

            if showResult {
                HStack {
                    Image(systemName: isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundColor(isCorrect ? .green : .red)
                    Text(isCorrect ? "Correct! 🎉" : "Answer: \(q.vocab.englishWord)")
                        .foregroundColor(isCorrect ? .green : .red)
                }
                .font(.subheadline)
            }

            if !showResult {
                Button(action: { checkAnswer(q) }) {
                    Label("Check", systemImage: "checkmark")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(userAnswer.trimmingCharacters(in: .whitespaces).isEmpty)
            } else {
                Button(action: next) {
                    Label("Next", systemImage: "arrow.right")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
            }

            Spacer()
        }
        .onAppear {
            userAnswer = ""
            showResult = false
            focused = true
        }
    }

    // MARK: - Result
    private var resultView: some View {
        VStack(spacing: 20) {
            Text(correctCount == questions.count ? "🏆" : correctCount > questions.count / 2 ? "🎉" : "📚")
                .font(.system(size: 80))
            Text("Cloze Quiz Complete!")
                .font(.title).bold()
            Text("\(correctCount) / \(questions.count) correct")
                .font(.title2)
            Text("\(Int(Double(correctCount) / Double(questions.count) * 100))%")
                .font(.system(size: 60, weight: .bold))
                .foregroundColor(.purple)
            Button("Play Again") {
                generateQuestions()
                isFinished = false
            }
            .buttonStyle(.borderedProminent)
        }
    }

    // MARK: - Helpers
    private func clozeText(_ q: ClozeQuestion) -> String {
        q.sentence.replacingOccurrences(
            of: q.vocab.englishWord,
            with: "______",
            options: .caseInsensitive
        )
    }

    private func generateQuestions() {
        let available = vocabulary.filter { !$0.exampleSentence.isEmpty }
        let source = available.isEmpty ? Array(vocabulary) : available
        questions = source.shuffled().prefix(10).map { ClozeQuestion(vocab: $0) }
        currentIndex = 0
        correctCount = 0
        isFinished = false
        userAnswer = ""
        showResult = false
    }

    private func checkAnswer(_ q: ClozeQuestion) {
        let ans = userAnswer.trimmingCharacters(in: .whitespaces).lowercased()
        let correct = q.vocab.englishWord.lowercased()
        isCorrect = ans == correct
        showResult = true
        if isCorrect { correctCount += 1 }
        SRSService.applyReview(to: q.vocab, quality: isCorrect ? .correct_hesitation : .incorrect_easy)
        try? modelContext.save()
    }

    private func next() {
        if currentIndex < questions.count - 1 {
            currentIndex += 1
            userAnswer = ""
            showResult = false
        } else {
            isFinished = true
        }
    }
}

struct ClozeQuestion: Identifiable {
    let id = UUID()
    let vocab: Vocabulary
    var sentence: String {
        // Use example sentence if available, otherwise create simple one
        if !vocab.exampleSentence.isEmpty {
            return vocab.exampleSentence
        }
        return "The word \(vocab.englishWord) means \(vocab.german) in German."
    }
}

