import SwiftUI
import SwiftData
import AVFoundation
import Speech

/// Diktat-Modus: Wort hören → tippen
struct DictationView: View {
    @Query private var vocabulary: [Vocabulary]
    @Environment(\.modelContext) private var modelContext
    @StateObject private var speech = SpeechService.shared

    @State private var cards: [Vocabulary] = []
    @State private var currentIndex = 0
    @State private var userInput = ""
    @State private var showResult = false
    @State private var isCorrect = false
    @State private var correctCount = 0
    @State private var isFinished = false
    @State private var hasPlayed = false
    @FocusState private var inputFocused: Bool

    var currentCard: Vocabulary? {
        guard currentIndex < cards.count else { return nil }
        return cards[currentIndex]
    }

    var body: some View {
        VStack(spacing: 20) {
            if vocabulary.isEmpty {
                ContentUnavailableView("No Words", systemImage: "waveform", description: Text("Add vocabulary first!"))
            } else if isFinished {
                dictationResultView
            } else if cards.isEmpty {
                startButton
            } else if let card = currentCard {
                dictationCard(card)
            }
        }
        .padding()
    }

    // MARK: - Start
    private var startButton: some View {
        VStack(spacing: 16) {
            Image(systemName: "waveform.circle.fill")
                .font(.system(size: 70))
                .foregroundColor(.blue)
            Text("Dictation Mode")
                .font(.title).bold()
            Text("Listen to the word and type what you hear")
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            Button("Start Dictation") {
                cards = Array(vocabulary.shuffled().prefix(10))
                currentIndex = 0
                correctCount = 0
                isFinished = false
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
    }

    // MARK: - Card
    private func dictationCard(_ card: Vocabulary) -> some View {
        VStack(spacing: 20) {
            ProgressView(value: Double(currentIndex + 1), total: Double(cards.count))
            HStack {
                Text("✅ \(correctCount)")
                    .foregroundColor(.green)
                Spacer()
                Text("\(currentIndex + 1) / \(cards.count)")
                Spacer()
                Text("❌ \(currentIndex - correctCount)")
                    .foregroundColor(.red)
            }
            .font(.subheadline)

            // Speaker Buttons
            VStack(spacing: 12) {
                Text("🎧 Listen and type what you hear")
                    .font(.headline)
                    .foregroundColor(.secondary)

                HStack(spacing: 16) {
                    Button(action: {
                        speech.speak(card.englishWord)
                        hasPlayed = true
                    }) {
                        Label("Play", systemImage: "speaker.wave.2.fill")
                            .frame(minWidth: 120)
                    }
                    .buttonStyle(.borderedProminent)

                    Button(action: { speech.speakSlow(card.englishWord) }) {
                        Label("Slow", systemImage: "tortoise.fill")
                            .frame(minWidth: 120)
                    }
                    .buttonStyle(.bordered)
                }

                // German hint
                Text("🇩🇪 \(card.german)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(8)
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(8)
            }
            .padding()
            .background(Color.blue.opacity(0.06))
            .cornerRadius(16)

            // Input Field
            VStack(alignment: .leading, spacing: 6) {
                Text("Your answer:")
                    .font(.caption)
                    .foregroundColor(.secondary)
                TextField("Type the English word...", text: $userInput)
                    .textFieldStyle(.roundedBorder)
                    .font(.title2)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .focused($inputFocused)
                    .onSubmit { checkAnswer(card) }

                if showResult {
                    HStack {
                        Image(systemName: isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundColor(isCorrect ? .green : .red)
                        Text(isCorrect ? "Correct! 🎉" : "Correct answer: \(card.englishWord)")
                            .foregroundColor(isCorrect ? .green : .red)
                    }
                    .font(.subheadline)
                }
            }

            if !showResult {
                Button(action: { checkAnswer(card) }) {
                    Label("Check", systemImage: "checkmark")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(userInput.trimmingCharacters(in: .whitespaces).isEmpty || !hasPlayed)
            } else {
                Button(action: nextCard) {
                    Label("Next", systemImage: "arrow.right")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
            }

            Spacer()
        }
        .onAppear {
            hasPlayed = false
            showResult = false
            userInput = ""
            inputFocused = true
            // Auto-play
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                speech.speak(card.englishWord)
                hasPlayed = true
            }
        }
    }

    // MARK: - Result
    private var dictationResultView: some View {
        VStack(spacing: 20) {
            Text(correctCount == cards.count ? "🏆" : correctCount > cards.count / 2 ? "🎉" : "📚")
                .font(.system(size: 80))
            Text("Dictation Complete!")
                .font(.title).bold()
            Text("\(correctCount) / \(cards.count) correct")
                .font(.title2)
            Text("\(Int(Double(correctCount) / Double(cards.count) * 100))%")
                .font(.system(size: 60, weight: .bold))
                .foregroundColor(.blue)
            Button("Try Again") {
                cards = Array(vocabulary.shuffled().prefix(10))
                currentIndex = 0
                correctCount = 0
                isFinished = false
            }
            .buttonStyle(.borderedProminent)
        }
    }

    // MARK: - Logic
    private func checkAnswer(_ card: Vocabulary) {
        let answer = userInput.trimmingCharacters(in: .whitespaces).lowercased()
        let correct = card.englishWord.lowercased()
        isCorrect = answer == correct
        showResult = true
        if isCorrect { correctCount += 1 }

        SRSService.applyReview(to: card, quality: isCorrect ? .correct_hesitation : .incorrect_easy)
        try? modelContext.save()
    }

    private func nextCard() {
        if currentIndex < cards.count - 1 {
            currentIndex += 1
            showResult = false
            userInput = ""
            hasPlayed = false
        } else {
            isFinished = true
        }
    }
}

