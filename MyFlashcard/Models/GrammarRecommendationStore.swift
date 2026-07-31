import Foundation
import SwiftUI

// MARK: - Grammar Recommendation Store

/// Zentrale Quelle für KI-generierte Grammatikempfehlungen.
///
/// Wird vom AI-Chat befüllt und vom Grammar-Screen gelesen.
/// Speichert die aktuellen Empfehlungen persistent in `UserDefaults`.
///
/// - Note: Ist als `@MainActor` deklariert, da `@Published` direkt in der UI
///   verwendet wird. Zukünftig kann auf `@Observable` migriert werden.
@MainActor
final class GrammarRecommendationStore: ObservableObject {
    static let shared = GrammarRecommendationStore()

    @Published private(set) var topics: [String]

    private let defaults = UserDefaults.standard
    private let key = "grammar.recommended.topics"

    private init() {
        self.topics = defaults.stringArray(forKey: key) ?? []
    }

    /// Setzt neue Empfehlungen. Dedupliziert und trimmt automatisch.
    func setTopics(_ values: [String]) {
        let normalized = values
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        topics = Array(NSOrderedSet(array: normalized)) as? [String] ?? normalized
        defaults.set(topics, forKey: key)
    }

    func clear() {
        topics = []
        defaults.removeObject(forKey: key)
    }
}
