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
                        "No Flashcards",
                        systemImage: "rectangle.stack",
                        description: Text("Add vocabulary to practice!")
                    )
                } else {
                    // Progress
                    ProgressView(value: Double(currentIndex + 1), total: Double(cards.count))
                        .padding(.horizontal)
                    
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
                            Label("Previous", systemImage: "arrow.left")
                        }
                        .disabled(currentIndex == 0)
                        
                        Button(action: nextCard) {
                            Label("Next", systemImage: "arrow.right")
                        }
                        .disabled(currentIndex >= cards.count - 1)
                    }
                    .padding()
                    
                    // Learning Buttons
                    HStack(spacing: 20) {
                        Button(action: { markAsLearned(false) }) {
                            Label("Don't Know", systemImage: "xmark")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.red)
                        
                        Button(action: { markAsLearned(true) }) {
                            Label("Know It!", systemImage: "checkmark")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.green)
                    }
                    .padding(.horizontal)
                }
            }
            .navigationTitle("🎴 Flashcards")
            .toolbar {
                Button(action: shuffleCards) {
                    Image(systemName: "shuffle")
                }
            }
            .onAppear { loadCards() }
        }
    }
    
    private func loadCards() {
        cards = vocabulary.shuffled()
        currentIndex = 0
        showingBack = false
    }
    
    private func shuffleCards() {
        cards.shuffle()
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
        card.timesReviewed += 1
        if correct {
            card.timesCorrect += 1
        }
        card.lastReviewedAt = Date()
        card.isLearned = card.timesCorrect >= 3
        
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
                        Text("🇮🇷")
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
                            Text("📝 Example:")
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
                    
                    Text("Tap to see English word")
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
                    
                    HStack(spacing: 12) {
                        Button {
                            speechService.speak(card.englishWord)
                        } label: {
                            Label("Play", systemImage: "speaker.wave.2.fill")
                        }
                        .buttonStyle(.borderedProminent)
                        
                        Button {
                            speechService.speakSlow(card.englishWord)
                        } label: {
                            Label("Slow", systemImage: "tortoise.fill")
                        }
                        .buttonStyle(.bordered)
                    }
                    
                    Spacer().frame(height: 20)
                    
                    Text("Tap to reveal translation")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 400)
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.3)) {
                showingBack.toggle()
            }
        }
        .id(card.id) // Reset when card changes
    }
}
