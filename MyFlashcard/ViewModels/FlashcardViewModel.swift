import SwiftUI
import SwiftData

// MARK: - FlashcardViewModel

/// ViewModel für den Flashcard-Screen.
///
/// Verwaltet die aktuelle Kartenposition, den Flip-Zustand
/// und das SRS-Review-Ergebnis (richtig/falsch).
/// Karten werden nach Review-Priorität sortiert angezeigt.
@MainActor
@Observable
class FlashcardViewModel {
    var cards: [Vocabulary] = []
    var currentIndex: Int = 0
    var isFlipped: Bool = false

    // MARK: - Card Loading

    /// Lädt und sortiert Karten nach SRS-Priorität.
    func loadCards(_ vocabulary: [Vocabulary]) {
        SRSService.normalizeWordAges(for: vocabulary)
        cards = vocabulary.sorted { SRSService.reviewPriority(for: $0) > SRSService.reviewPriority(for: $1) }
        currentIndex = 0
        isFlipped = false
    }

    // MARK: - Navigation

    func shuffleCards() {
        cards = cards.shuffled().sorted { SRSService.reviewPriority(for: $0) > SRSService.reviewPriority(for: $1) }
        currentIndex = 0
        isFlipped = false
    }

    func flipCard() {
        isFlipped.toggle()
    }

    func nextCard() {
        guard currentIndex < cards.count - 1 else { return }
        currentIndex += 1
        isFlipped = false
    }

    func previousCard() {
        guard currentIndex > 0 else { return }
        currentIndex -= 1
        isFlipped = false
    }

    // MARK: - Review

    /// Bewertet die aktuelle Karte und speichert das SRS-Ergebnis.
    func markAsLearned(isCorrect: Bool, modelContext: ModelContext) {
        guard currentIndex < cards.count else { return }
        let card = cards[currentIndex]
        SRSService.applyReview(to: card, quality: isCorrect ? .perfect : .incorrect_hard, modelContext: modelContext)
        do {
            try modelContext.save()
        } catch {
            print("[FlashcardViewModel] Speichern fehlgeschlagen: \(error.localizedDescription)")
        }
        nextCard()
    }

    // MARK: - Computed

    var currentCard: Vocabulary? {
        guard currentIndex < cards.count else { return nil }
        return cards[currentIndex]
    }

    var progress: Double {
        guard !cards.isEmpty else { return 0 }
        return Double(currentIndex + 1) / Double(cards.count)
    }
}
