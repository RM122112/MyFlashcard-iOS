import SwiftUI
import SwiftData

/// Spaced Repetition Review – zeigt fällige Karten nach SM-2
struct SRSReviewView: View {
    @Query private var allVocabulary: [Vocabulary]
    @Environment(\.modelContext) private var modelContext
    @StateObject private var speech = SpeechService.shared

    @State private var dueCards: [Vocabulary] = []
    @State private var currentIndex = 0
    @State private var isFlipped = false
    @State private var sessionCorrect = 0
    @State private var sessionTotal = 0
    @State private var isFinished = false
    @State private var showQualityPicker = false

    var currentCard: Vocabulary? {
        guard currentIndex < dueCards.count else { return nil }
        return dueCards[currentIndex]
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Status bar
                srsStatusBar

                if dueCards.isEmpty {
                    nothingDueView
                } else if isFinished {
                    sessionResultView
                } else if let card = currentCard {
                    cardArea(card: card)
                }
            }
            .navigationTitle("🧠 SRS-Wiederholung")
            .onAppear { loadDueCards() }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: loadDueCards) {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
        }
    }

    // MARK: - Status Bar
    private var srsStatusBar: some View {
        HStack {
            VStack(alignment: .leading) {
                Text("📅 Heute fällig")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("\(dueCards.count)")
                    .font(.title2).bold()
            }
            Spacer()
            VStack {
                Text("✅ Richtig")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("\(sessionCorrect)")
                    .font(.title2).bold().foregroundColor(.green)
            }
            Spacer()
            VStack(alignment: .trailing) {
                Text("📊 Fortschritt")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("\(currentIndex)/\(dueCards.count)")
                    .font(.title2).bold()
            }
        }
        .padding()
        .background(Color(.systemGroupedBackground))
    }

    // MARK: - Card Area
    private func cardArea(card: Vocabulary) -> some View {
        VStack(spacing: 16) {
            ProgressView(value: Double(currentIndex), total: Double(dueCards.count))
                .padding(.horizontal)

            Text("Tippe auf die Karte, um die Antwort zu sehen")
                .font(.caption)
                .foregroundColor(.secondary)

            // Flip Card
            ZStack {
                // Front
                cardFace(
                    content: {
                        VStack(spacing: 12) {
                            Text(card.englishWord)
                                .font(.system(size: 36, weight: .bold))
                            if !card.ipaPronunciation.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                Text("/\(card.ipaPronunciation)/")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            } else {
                                Text("Aussprachehilfe: \(speech.pronunciationHint(for: card.englishWord))")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            if !card.cefrLevel.isEmpty {
                                Text(card.cefrLevel)
                                    .font(.caption)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background(Color.blue.opacity(0.2))
                                    .cornerRadius(8)
                            }
                            HStack(spacing: 8) {
                                Button(action: { speech.speak(card.englishWord) }) {
                                    Label("Anhören", systemImage: "speaker.wave.2.fill")
                                        .font(.callout)
                                }
                                .buttonStyle(.bordered)

                                Button(action: { speech.speakSlow(card.englishWord) }) {
                                    Label("Langsam", systemImage: "tortoise.fill")
                                        .font(.callout)
                                }
                                .buttonStyle(.bordered)
                            }
                            Text(SRSService.difficultyLabel(easeFactor: card.srsEaseFactor))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    },
                    color: .blue.opacity(0.08)
                )
                .opacity(isFlipped ? 0 : 1)
                .rotation3DEffect(.degrees(isFlipped ? 180 : 0), axis: (x: 0, y: 1, z: 0))

                // Back
                cardFace(
                    content: {
                        VStack(spacing: 10) {
                            Text(card.englishWord)
                                .font(.headline)
                                .foregroundColor(.secondary)
                            Divider()
                            Text(card.german)
                                .font(.title2).bold()
                            if !card.persian.isEmpty {
                                Text(card.persian)
                                    .font(.title3)
                                    .environment(\.layoutDirection, .rightToLeft)
                                    .foregroundColor(.purple)
                            }
                            if !card.exampleSentence.isEmpty {
                                Text("💬 \(card.exampleSentence)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                                    .padding(.top, 4)
                            }
                        }
                    },
                    color: .green.opacity(0.08)
                )
                .opacity(isFlipped ? 1 : 0)
                .rotation3DEffect(.degrees(isFlipped ? 0 : -180), axis: (x: 0, y: 1, z: 0))
            }
            .onTapGesture {
                withAnimation(.spring(duration: 0.4)) {
                    isFlipped.toggle()
                }
            }

            // Quality Buttons (only after flip)
            if isFlipped {
                qualityButtons(card: card)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }

            Spacer()
        }
        .padding()
        .animation(.easeInOut, value: isFlipped)
    }

    @ViewBuilder
    private func cardFace<Content: View>(content: @escaping () -> Content, color: Color) -> some View {
        content()
            .multilineTextAlignment(.center)
            .padding(24)
            .frame(maxWidth: .infinity, minHeight: 200)
            .background(color)
            .cornerRadius(20)
            .shadow(color: .black.opacity(0.08), radius: 8, y: 4)
    }

    // MARK: - Quality Buttons
    private func qualityButtons(card: Vocabulary) -> some View {
        VStack(spacing: 10) {
            Text("Wie gut konntest du dich erinnern?")
                .font(.subheadline)
                .foregroundColor(.secondary)
            HStack(spacing: 8) {
                ForEach([
                    SRSService.Quality.blackout,
                    .incorrect_easy,
                    .correct_difficult,
                    .correct_hesitation,
                    .perfect
                ], id: \.rawValue) { quality in
                    Button(action: { applyQuality(quality, to: card) }) {
                        Text(quality.label)
                            .font(.caption2)
                            .multilineTextAlignment(.center)
                            .padding(.vertical, 8)
                            .padding(.horizontal, 4)
                            .frame(maxWidth: .infinity)
                            .background(qualityColor(quality))
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
    }

    private func qualityColor(_ q: SRSService.Quality) -> Color {
        switch q {
        case .blackout, .incorrect_hard: return .red
        case .incorrect_easy: return .orange
        case .correct_difficult: return .yellow
        case .correct_hesitation: return .blue
        case .perfect: return .green
        }
    }

    // MARK: - Nothing Due
    private var nothingDueView: some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 80))
                .foregroundColor(.green)
            Text("Alles erledigt! 🎉")
                .font(.title).bold()
            Text("Heute sind keine Karten mehr fällig.")
                .foregroundColor(.secondary)
            VStack(alignment: .leading, spacing: 8) {
                Text("📊 Deine nächsten Wiederholungen:")
                    .font(.headline)
                ForEach(upcomingReviews(), id: \.0) { day, count in
                    HStack {
                        Text(day)
                        Spacer()
                        Text("\(count) Karten")
                            .foregroundColor(.blue)
                    }
                }
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .cornerRadius(12)
            .padding(.horizontal)
        }
        .padding()
    }

    private func upcomingReviews() -> [(String, Int)] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        var result: [(String, Int)] = []
        for offset in 1...7 {
            let day = calendar.date(byAdding: .day, value: offset, to: today)!
            let count = allVocabulary.filter { vocab in
                guard let next = vocab.srsNextReview else { return false }
                return calendar.startOfDay(for: next) == day
            }.count
            if count > 0 {
                let formatter = DateFormatter()
                formatter.dateFormat = "EEEE"
                result.append((formatter.string(from: day), count))
            }
        }
        return result
    }

    // MARK: - Session Result
    private var sessionResultView: some View {
        VStack(spacing: 20) {
            Text(sessionCorrect == sessionTotal ? "🏆" : sessionCorrect > sessionTotal / 2 ? "🎉" : "📚")
                .font(.system(size: 80))
            Text("Sitzung abgeschlossen!")
                .font(.title).bold()
            Text("\(sessionCorrect) / \(sessionTotal) richtig")
                .font(.title2)
            Text("Die nächste Wiederholung wurde vom SRS eingeplant")
                .foregroundColor(.secondary)
            Button("Neue Sitzung starten") {
                loadDueCards()
                isFinished = false
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }

    // MARK: - Logic
    private func loadDueCards() {
        dueCards = SRSService.dueCards(from: allVocabulary)
        currentIndex = 0
        sessionCorrect = 0
        sessionTotal = 0
        isFlipped = false
        isFinished = false
    }

    private func applyQuality(_ quality: SRSService.Quality, to card: Vocabulary) {
        SRSService.applyReview(to: card, quality: quality)
        try? modelContext.save()

        sessionTotal += 1
        if quality.rawValue >= 3 { sessionCorrect += 1 }

        isFlipped = false
        if currentIndex < dueCards.count - 1 {
            currentIndex += 1
        } else {
            isFinished = true
        }
    }
}

