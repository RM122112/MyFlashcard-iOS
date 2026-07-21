import Foundation
import NaturalLanguage

/// Semantische Suche mit NLEmbedding für ähnliche Wörter
final class SemanticSearchService {
    static let shared = SemanticSearchService()

    private var embedding: NLEmbedding?
    private var isLoaded = false

    private init() {
        // Lazy-Load beim ersten Aufruf
    }

    private func loadEmbeddingIfNeeded() {
        guard !isLoaded else { return }
        isLoaded = true
        embedding = NLEmbedding.wordEmbedding(for: .english)
    }

    /// Semantisch ähnliche Vokabeln finden
    func search(query: String, in vocabulary: [Vocabulary], limit: Int = 20) -> [SemanticSearchResult] {
        loadEmbeddingIfNeeded()

        let queryLower = query.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        guard !queryLower.isEmpty else { return [] }

        // Wenn kein Embedding verfügbar, Fallback auf String-Matching
        guard let embedding = embedding else {
            return fallbackSearch(query: queryLower, in: vocabulary, limit: limit)
        }

        var results: [SemanticSearchResult] = []

        for vocab in vocabulary {
            let word = vocab.englishWord.lowercased()

            // Exakter Treffer bekommt höchste Score
            if word == queryLower || word.contains(queryLower) || queryLower.contains(word) {
                results.append(SemanticSearchResult(vocabulary: vocab, score: 1.0, matchType: .exact))
                continue
            }

            // Semantische Distanz berechnen
            let distance = embedding.distance(between: queryLower, and: word)
            if distance < 2.0 {
                // NLEmbedding.distance gibt Cosine-Distanz zurück (0 = identisch, 2 = gegensätzlich)
                let similarity = max(0, 1.0 - distance / 2.0)
                if similarity > 0.3 {
                    results.append(SemanticSearchResult(vocabulary: vocab, score: similarity, matchType: .semantic))
                }
            }

            // Auch in deutscher Übersetzung suchen (String-basiert)
            if vocab.german.lowercased().contains(queryLower) {
                let existing = results.first(where: { $0.vocabulary.id == vocab.id })
                if existing == nil {
                    results.append(SemanticSearchResult(vocabulary: vocab, score: 0.8, matchType: .translation))
                }
            }

            // Auch in persischer Übersetzung
            if vocab.persian.contains(query) {
                let existing = results.first(where: { $0.vocabulary.id == vocab.id })
                if existing == nil {
                    results.append(SemanticSearchResult(vocabulary: vocab, score: 0.75, matchType: .translation))
                }
            }
        }

        return results
            .sorted { $0.score > $1.score }
            .prefix(limit)
            .map { $0 }
    }

    /// Ähnliche Wörter aus dem Embedding direkt finden (nicht aus der Vokabelliste)
    func findSimilarWords(to word: String, limit: Int = 5) -> [(String, Double)] {
        loadEmbeddingIfNeeded()
        guard let embedding = embedding else { return [] }

        var neighbors: [(String, Double)] = []
        embedding.enumerateNeighbors(for: word.lowercased(), maximumCount: limit) { neighbor, distance in
            let similarity = max(0, 1.0 - distance / 2.0)
            neighbors.append((neighbor, similarity))
            return true
        }
        return neighbors
    }

    // MARK: - Fallback

    private func fallbackSearch(query: String, in vocabulary: [Vocabulary], limit: Int) -> [SemanticSearchResult] {
        vocabulary.compactMap { vocab in
            let word = vocab.englishWord.lowercased()
            let german = vocab.german.lowercased()
            if word.contains(query) || query.contains(word) {
                return SemanticSearchResult(vocabulary: vocab, score: 1.0, matchType: .exact)
            }
            if german.contains(query) {
                return SemanticSearchResult(vocabulary: vocab, score: 0.8, matchType: .translation)
            }
            if vocab.persian.contains(query) {
                return SemanticSearchResult(vocabulary: vocab, score: 0.75, matchType: .translation)
            }
            if vocab.exampleSentence.lowercased().contains(query) {
                return SemanticSearchResult(vocabulary: vocab, score: 0.5, matchType: .context)
            }
            return nil
        }
        .sorted { $0.score > $1.score }
        .prefix(limit)
        .map { $0 }
    }
}

struct SemanticSearchResult: Identifiable {
    let id = UUID()
    let vocabulary: Vocabulary
    let score: Double       // 0.0 – 1.0
    let matchType: MatchType

    enum MatchType: String {
        case exact = "Exakt"
        case semantic = "Semantisch"
        case translation = "Übersetzung"
        case context = "Kontext"

        var icon: String {
            switch self {
            case .exact: return "magnifyingglass"
            case .semantic: return "brain.head.profile"
            case .translation: return "character.book.closed"
            case .context: return "text.quote"
            }
        }
    }
}

