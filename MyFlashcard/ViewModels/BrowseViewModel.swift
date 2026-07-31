import SwiftUI
import SwiftData

// MARK: - BrowseViewModel

/// ViewModel für den Browse-Screen.
///
/// Verwaltet die Suche, Statusfilterung und Löschbestätigung.
/// Die eigentliche Datenbankabfrage erfolgt via `@Query` im View –
/// dieses ViewModel übernimmt nur die Filter- und UI-Logik.
@MainActor
@Observable
class BrowseViewModel {
    var searchText: String = ""
    var selectedStatus: WordStatus?
    var vocabularyToDelete: Vocabulary?
    var showDeleteAlert: Bool = false

    /// Löscht einen Vokabeleintrag aus dem SwiftData-Store.
    func deleteVocabulary(_ vocabulary: Vocabulary, modelContext: ModelContext) {
        modelContext.delete(vocabulary)
        do {
            try modelContext.save()
        } catch {
            // TODO: P1.5 – Error State im ViewModel exponieren
            print("[BrowseViewModel] Fehler beim Löschen: \(error.localizedDescription)")
        }
    }

    /// Gibt die gefilterte und nach Review-Priorität sortierte Vokabelliste zurück.
    ///
    /// - Parameter allVocabulary: Alle Einträge aus dem SwiftData-Store.
    /// - Returns: Gefilterte und sortierte Liste.
    func filteredVocabulary(_ allVocabulary: [Vocabulary]) -> [Vocabulary] {
        SRSService.normalizeWordAges(for: allVocabulary)
        let query = searchText.lowercased()
        return allVocabulary.filter { vocab in
            let matchesQuery = query.isEmpty ||
                vocab.englishWord.lowercased().contains(query) ||
                vocab.german.lowercased().contains(query) ||
                vocab.persian.contains(query) ||
                vocab.exampleSentence.lowercased().contains(query)
            let matchesStatus = selectedStatus == nil ||
                LearningStatusHelper.normalizedStatus(for: vocab) == selectedStatus
            return matchesQuery && matchesStatus
        }.sorted { SRSService.reviewPriority(for: $0) > SRSService.reviewPriority(for: $1) }
    }
}
