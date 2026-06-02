import SwiftUI
import SwiftData

struct FlashcardView: View {
    @Query private var vocabulary: [Vocabulary]
    @Environment(\.modelContext) private var modelContext
    @StateObject private var speechService = SpeechService.shared
    
    @State private var cards: [Vocabulary] = []
    @State private var currentIndex = 0
    @State private var showingBack = false
    
    var body: some View {
        NavigationStack {
            VStack {
                if cards.isEmpty {
                    ContentUnavailableView(
                        "Keine Karteikarten vorhanden",
                        systemImage: "rectangle.stack",
                        description: Text("Füge Wörter hinzu, um mit dem Üben zu beginnen.")
                    )
                } else {
                    // Progress
                    ProgressView(value: Double(currentIndex + 1), total: Double(cards.count))
                        .padding(.horizontal)

                    Text("Unbekannte und schwierige Wörter werden zuerst angezeigt.")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text("\(currentIndex + 1) / \(cards.count)")
                        .font(.caption)
                    
                    // Simplified Card - no complex rotation
                    SimpleFlashcard(
                        card: cards[currentIndex],
                        showingBack: $showingBack,
                        speechService: speechService
                    )
                    .padding()
                    
                    // Navigation
                    HStack(spacing: 20) {
                        Button(action: previousCard) {
                            Label("Zurück", systemImage: "arrow.left")
                        }
                        .disabled(currentIndex == 0)
                        
                        Button(action: nextCard) {
                            Label("Weiter", systemImage: "arrow.right")
                        }
                        .disabled(currentIndex >= cards.count - 1)
                    }
                    .padding()
                    
                    // Learning Buttons
                    HStack(spacing: 20) {
                        Button(action: { markAsLearned(false) }) {
                            Label("Unbekannt", systemImage: "xmark")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.red)
                        
                        Button(action: { markAsLearned(true) }) {
                            Label("Bekannt", systemImage: "checkmark")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.green)
                    }
                    .padding(.horizontal)
                }
            }
            .navigationTitle("🎴 Karteikarten")
            .toolbar {
                Button(action: shuffleCards) {
                    Image(systemName: "shuffle")
                }
            }
            .onAppear { loadCards() }
        }
    }
    
    private func loadCards() {
        SRSService.normalizeWordAges(for: vocabulary)
        cards = vocabulary.sorted { SRSService.reviewPriority(for: $0) > SRSService.reviewPriority(for: $1) }
        currentIndex = 0
        showingBack = false
    }
    
    private func shuffleCards() {
        cards = cards.shuffled().sorted { SRSService.reviewPriority(for: $0) > SRSService.reviewPriority(for: $1) }
        currentIndex = 0
        showingBack = false
    }
    
    private func previousCard() {
        if currentIndex > 0 {
            currentIndex -= 1
            showingBack = false
        }
    }
    
    private func nextCard() {
        if currentIndex < cards.count - 1 {
            currentIndex += 1
            showingBack = false
        }
    }
    
    private func markAsLearned(_ correct: Bool) {
        let card = cards[currentIndex]
        SRSService.applyReview(to: card, quality: correct ? .perfect : .incorrect_hard)

        try? modelContext.save()
        nextCard()
    }
}

// MARK: - Simple Flashcard without rotation issues
struct SimpleFlashcard: View {
    let card: Vocabulary
    @Binding var showingBack: Bool
    let speechService: SpeechService
    
    var body: some View {
        ZStack {
            // Card Background
            RoundedRectangle(cornerRadius: 20)
                .fill(showingBack ? Color.blue.opacity(0.1) : Color.green.opacity(0.1))
                .shadow(radius: 5)
            
            // Content - switches between front and back
            if showingBack {
                // Back: Translations
                VStack(spacing: 16) {
                    // German
                    HStack {
                        Text("🇩🇪")
                            .font(.title)
                        Text(card.german)
                            .font(.title2)
                            .fontWeight(.bold)
                    }
                    
                    Divider()
                        .padding(.horizontal, 40)
                    
                    // Persian with RTL
                    HStack {
                        Text("🇦🇫")
                            .font(.title)
                        Text(card.persian)
                            .font(.title2)
                            .fontWeight(.bold)
                            .environment(\.layoutDirection, .rightToLeft)
                    }
                    
                    // Example sentence
                    if !card.exampleSentence.isEmpty {
                        Divider()
                            .padding(.horizontal, 40)
                        
                        VStack(spacing: 8) {
                            Text("📝 Beispielsatz:")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            HStack {
                                Text(card.exampleSentence)
                                    .font(.body)
                                    .multilineTextAlignment(.center)
                                
                                Button {
                                    speechService.speak(card.exampleSentence)
                                } label: {
                                    Image(systemName: "speaker.wave.2.fill")
                                        .foregroundColor(.blue)
                                }
                                .buttonStyle(.borderless)
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    Spacer().frame(height: 20)
                    
                    Text("Tippe, um das englische Wort zu sehen")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
            } else {
                // Front: English word
                VStack(spacing: 20) {
                    Text("🇺🇸")
                        .font(.system(size: 50))

                    Text(card.englishWord)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)

                    if !card.ipaPronunciation.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        Text("/\(card.ipaPronunciation)/")
                            .font(.title3)
                            .foregroundColor(.secondary)
                    } else {
                        Text("Aussprachehilfe: \(speechService.pronunciationHint(for: card.englishWord))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }

                    HStack(spacing: 12) {
                        Button {
                            speechService.speak(card.englishWord)
                        } label: {
                            Label("Abspielen", systemImage: "speaker.wave.2.fill")
                        }
                        .buttonStyle(.borderedProminent)

                        Button {
                            speechService.speakSlow(card.englishWord)
                        } label: {
                            Label("Langsam", systemImage: "tortoise.fill")
                        }
                        .buttonStyle(.bordered)
                    }

                    Spacer().frame(height: 20)

                    Text("Tippe, um die Übersetzung zu sehen")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 440)
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.3)) {
                showingBack.toggle()
            }
        }
        .id(card.id) // Reset when card changes
    }
}
