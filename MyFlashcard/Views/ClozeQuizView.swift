import SwiftUI
import SwiftData
import NaturalLanguage

/// Lückentext (Cloze) Quiz Modus – verbessert mit NLP-basierter Wortauswahl
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
    @State private var showHint = false
    @FocusState private var focused: Bool

    var currentQ: ClozeQuestion? {
        guard currentIndex < questions.count else { return nil }
        return questions[currentIndex]
    }

    var body: some View {
        VStack(spacing: 20) {
            if vocabulary.isEmpty {
                ContentUnavailableView("Keine Wörter vorhanden", systemImage: "text.badge.plus", description: Text("Füge zuerst Wörter hinzu."))
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
            Text("Lückentext")
                .font(.title).bold()
            Text("Ergänze die Lücke mit dem richtigen Wort")
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            Button("Starten") {
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
                Text("Ergänze die Lücke:")
                    .font(.caption)
                    .foregroundColor(.secondary)

                // Sentence with blank
                Text(q.displaySentence)
                    .font(.title3)
                    .multilineTextAlignment(.center)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.purple.opacity(0.08))
                    .cornerRadius(12)

                // Translations as hint
                VStack(spacing: 4) {
                    Text("🇩🇪 \(q.vocab.german)")
                    Text("🇦🇫 \(q.vocab.persian)")
                        .environment(\.layoutDirection, .rightToLeft)
                }
                .font(.subheadline)
                .foregroundColor(.secondary)
                .padding(8)
                .background(Color(.secondarySystemBackground))
                .cornerRadius(8)

                // Smart hint
                if showHint {
                    Text("Hinweis: \(q.hint)")
                        .font(.caption)
                        .foregroundColor(.orange)
                        .padding(6)
                        .background(Color.orange.opacity(0.1))
                        .cornerRadius(8)
                        .transition(.opacity)
                }
            }

            // Input
            TextField("Tippe das fehlende Wort ein ...", text: $userAnswer)
                .textFieldStyle(.roundedBorder)
                .font(.title2)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .focused($focused)
                .onSubmit { checkAnswer(q) }

            if showResult {
                VStack(spacing: 4) {
                    HStack {
                        Image(systemName: isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundColor(isCorrect ? .green : .red)
                        Text(isCorrect ? "Richtig! 🎉" : "Antwort: \(q.blankWord)")
                            .foregroundColor(isCorrect ? .green : .red)
                    }
                    if !isCorrect && q.isCloseMatch(userAnswer) {
                        Text("Fast richtig! Achte auf die Schreibweise.")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                }
                .font(.subheadline)
            }

            HStack(spacing: 12) {
                if !showResult {
                    Button {
                        withAnimation { showHint = true }
                    } label: {
                        Label("Hinweis", systemImage: "lightbulb")
                    }
                    .buttonStyle(.bordered)
                    .disabled(showHint)

                    Button(action: { checkAnswer(q) }) {
                        Label("Prüfen", systemImage: "checkmark")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(userAnswer.trimmingCharacters(in: .whitespaces).isEmpty)
                } else {
                    Button(action: next) {
                        Label("Weiter", systemImage: "arrow.right")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                }
            }

            Spacer()
        }
        .onAppear {
            userAnswer = ""
            showResult = false
            showHint = false
            focused = true
        }
    }

    // MARK: - Result
    private var resultView: some View {
        VStack(spacing: 20) {
            Text(correctCount == questions.count ? "🏆" : correctCount > questions.count / 2 ? "🎉" : "📚")
                .font(.system(size: 80))
            Text("Lückentext abgeschlossen!")
                .font(.title).bold()
            Text("\(correctCount) / \(questions.count) richtig")
                .font(.title2)
            Text("\(Int(Double(correctCount) / Double(max(questions.count, 1)) * 100))%")
                .font(.system(size: 60, weight: .bold))
                .foregroundColor(.purple)
            Button("Noch einmal") {
                generateQuestions()
                isFinished = false
            }
            .buttonStyle(.borderedProminent)
        }
    }

    // MARK: - Helpers

    private func generateQuestions() {
        SRSService.normalizeWordAges(for: vocabulary)
        let sorted = vocabulary
            .sorted { SRSService.reviewPriority(for: $0) > SRSService.reviewPriority(for: $1) }

        questions = sorted.prefix(10).compactMap { vocab in
            ClozeQuestion.generate(for: vocab, allVocabulary: vocabulary)
        }

        // Fill up if we didn't get 10
        if questions.count < 10 {
            let remaining = sorted.dropFirst(10).prefix(10 - questions.count)
            for vocab in remaining {
                if let q = ClozeQuestion.generate(for: vocab, allVocabulary: vocabulary) {
                    questions.append(q)
                }
            }
        }

        currentIndex = 0
        correctCount = 0
        isFinished = false
        userAnswer = ""
        showResult = false
        showHint = false
    }

    private func checkAnswer(_ q: ClozeQuestion) {
        let ans = userAnswer.trimmingCharacters(in: .whitespaces).lowercased()
        let correct = q.blankWord.lowercased()
        isCorrect = ans == correct
        showResult = true
        if isCorrect { correctCount += 1 }

        let quality: SRSService.Quality
        if isCorrect {
            quality = showHint ? .correct_difficult : .correct_hesitation
        } else if q.isCloseMatch(userAnswer) {
            quality = .incorrect_easy
        } else {
            quality = .incorrect_hard
        }
        SRSService.applyReview(to: q.vocab, quality: quality, modelContext: modelContext)
        try? modelContext.save()
    }

    private func next() {
        if currentIndex < questions.count - 1 {
            currentIndex += 1
            userAnswer = ""
            showResult = false
            showHint = false
        } else {
            isFinished = true
        }
    }
}

struct ClozeQuestion: Identifiable {
    let id = UUID()
    let vocab: Vocabulary
    let blankWord: String       // The word that was removed
    let sentenceWithBlank: String
    let hint: String
    let partOfSpeech: String

    var displaySentence: String { sentenceWithBlank }

    /// Fuzzy match: Levenshtein-Distanz <= 2
    func isCloseMatch(_ input: String) -> Bool {
        let a = input.trimmingCharacters(in: .whitespaces).lowercased()
        let b = blankWord.lowercased()
        if a == b { return true }
        if a.isEmpty { return false }
        return levenshtein(a, b) <= 2
    }

    private func levenshtein(_ s1: String, _ s2: String) -> Int {
        let a = Array(s1), b = Array(s2)
        var d = [[Int]](repeating: [Int](repeating: 0, count: b.count + 1), count: a.count + 1)
        for i in 0...a.count { d[i][0] = i }
        for j in 0...b.count { d[0][j] = j }
        for i in 1...a.count {
            for j in 1...b.count {
                d[i][j] = a[i-1] == b[j-1]
                    ? d[i-1][j-1]
                    : min(d[i-1][j], d[i][j-1], d[i-1][j-1]) + 1
            }
        }
        return d[a.count][b.count]
    }

    /// NLP-basierte Cloze-Generierung
    static func generate(for vocab: Vocabulary, allVocabulary: [Vocabulary]) -> ClozeQuestion? {
        let sentence: String
        if !vocab.exampleSentence.isEmpty {
            sentence = vocab.exampleSentence
        } else {
            // Einfachen Satz generieren
            sentence = "The word \(vocab.englishWord) means \(vocab.german) in German."
        }

        // NLP: Finde das beste Wort zum Entfernen
        let tagger = NLTagger(tagSchemes: [.lexicalClass])
        tagger.string = sentence

        struct TaggedWord {
            let word: String
            let range: Range<String.Index>
            let pos: NLTag
            let priority: Int
        }

        var candidates: [TaggedWord] = []
        let contentTags: Set<NLTag> = [.noun, .verb, .adjective, .adverb]

        tagger.enumerateTags(in: sentence.startIndex..<sentence.endIndex, unit: .word, scheme: .lexicalClass, options: [.omitWhitespace, .omitPunctuation]) { tag, range in
            guard let tag = tag else { return true }
            let word = String(sentence[range])
            guard word.count >= 3 else { return true }

            // Priorität: Zielwort > Inhaltswörter > Rest
            let priority: Int
            if word.lowercased() == vocab.englishWord.lowercased() {
                priority = 100
            } else if contentTags.contains(tag) {
                priority = 50 + (tag == .noun ? 10 : tag == .verb ? 8 : 5)
            } else {
                priority = 0
            }

            if priority > 0 {
                candidates.append(TaggedWord(word: word, range: range, pos: tag, priority: priority))
            }
            return true
        }

        guard !candidates.isEmpty else { return nil }

        // Bevorzuge das Zielwort, sonst zufällig gewichtetes Inhaltswort
        let chosen: TaggedWord
        if let target = candidates.first(where: { $0.priority == 100 }) {
            chosen = target
        } else {
            // Gewichtete Zufallsauswahl
            let weighted = candidates.sorted { $0.priority > $1.priority }
            chosen = weighted[Int.random(in: 0..<min(3, weighted.count))]
        }

        let blanked = sentence.replacingCharacters(in: chosen.range, with: "______")

        // Hinweis generieren
        let hint: String
        let posLabel: String
        switch chosen.pos {
        case .noun: posLabel = "Nomen"
        case .verb: posLabel = "Verb"
        case .adjective: posLabel = "Adjektiv"
        case .adverb: posLabel = "Adverb"
        default: posLabel = "Wort"
        }

        let firstLetter = String(chosen.word.prefix(1))
        let wordLen = chosen.word.count
        hint = "\(posLabel), beginnt mit \"\(firstLetter)\", \(wordLen) Buchstaben"

        return ClozeQuestion(
            vocab: vocab,
            blankWord: chosen.word,
            sentenceWithBlank: blanked,
            hint: hint,
            partOfSpeech: posLabel
        )
    }
}

