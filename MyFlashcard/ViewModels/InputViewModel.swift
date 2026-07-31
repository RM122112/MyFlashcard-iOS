import SwiftUI
import SwiftData

// MARK: - InputViewModel

/// ViewModel für den Eingabe-Screen (Einzeleingabe und Massenimport).
///
/// Verwaltet Formularfelder, Validierung, Speichern und Bulk-Import-Parsing.
/// Die eigentliche Persistenz erfolgt über `ModelContext`.
@MainActor
@Observable
class InputViewModel {

    // MARK: - Single Entry

    var englishWord: String = ""
    var german: String = ""
    var persian: String = ""
    var exampleSentence: String = ""

    // MARK: - Bulk Import

    var bulkText: String = ""
    var isBulkMode: Bool = true
    var parsedEntries: [ParsedEntry] = []

    // MARK: - State

    var isEditing: Bool = false
    var editingVocabulary: Vocabulary?
    var isSaving: Bool = false
    var error: String?
    var importedCount: Int = 0
    var showSuccessAlert: Bool = false

    // MARK: - Mode

    func toggleMode() {
        isBulkMode.toggle()
        error = nil
    }

    func setBulkText(_ text: String) {
        bulkText = text
        error = nil
        parsedEntries = TextParser.parseText(text)
    }

    // MARK: - Editing

    func loadForEditing(_ vocabulary: Vocabulary) {
        editingVocabulary = vocabulary
        englishWord = vocabulary.englishWord
        german = vocabulary.german
        persian = vocabulary.persian
        exampleSentence = vocabulary.exampleSentence
        isEditing = true
        isBulkMode = false
    }

    // MARK: - Save

    /// Importiert alle gültigen Einträge aus dem geparseten Bulk-Text.
    func importBulk(modelContext: ModelContext) {
        let validEntries = parsedEntries.filter { $0.isValid }

        guard !validEntries.isEmpty else {
            error = "Es wurden keine gültigen Einträge zum Import gefunden."
            return
        }

        isSaving = true
        error = nil

        var count = 0
        for entry in validEntries {
            let vocabulary = Vocabulary(
                englishWord: entry.englishWord,
                german: entry.german,
                persian: entry.persian,
                exampleSentence: entry.exampleSentence
            )
            modelContext.insert(vocabulary)
            count += 1
        }

        do {
            try modelContext.save()
        } catch {
            self.error = "Fehler beim Speichern: \(error.localizedDescription)"
            print("[InputViewModel] Bulk-Import fehlgeschlagen: \(error)")
        }

        importedCount = count
        isSaving = false
        showSuccessAlert = true
        clearForm()
    }

    /// Speichert einen einzelnen Eintrag (neu oder bearbeitet).
    /// - Returns: `true` bei Erfolg, `false` bei Validierungsfehler.
    @discardableResult
    func save(modelContext: ModelContext) -> Bool {
        guard !englishWord.trimmingCharacters(in: .whitespaces).isEmpty else {
            error = "Bitte gib ein englisches Wort ein."
            return false
        }
        guard !german.trimmingCharacters(in: .whitespaces).isEmpty else {
            error = "Bitte gib die deutsche Übersetzung ein."
            return false
        }
        guard !persian.trimmingCharacters(in: .whitespaces).isEmpty else {
            error = "Bitte gib die persische Übersetzung ein."
            return false
        }

        isSaving = true
        error = nil

        if isEditing, let vocab = editingVocabulary {
            vocab.englishWord     = englishWord.trimmingCharacters(in: .whitespaces)
            vocab.german          = german.trimmingCharacters(in: .whitespaces)
            vocab.persian         = persian.trimmingCharacters(in: .whitespaces)
            vocab.exampleSentence = exampleSentence.trimmingCharacters(in: .whitespaces)
        } else {
            let vocabulary = Vocabulary(
                englishWord: englishWord.trimmingCharacters(in: .whitespaces),
                german:      german.trimmingCharacters(in: .whitespaces),
                persian:     persian.trimmingCharacters(in: .whitespaces),
                exampleSentence: exampleSentence.trimmingCharacters(in: .whitespaces)
            )
            modelContext.insert(vocabulary)
        }

        do {
            try modelContext.save()
        } catch {
            self.error = "Fehler beim Speichern: \(error.localizedDescription)"
            isSaving = false
            print("[InputViewModel] Speichern fehlgeschlagen: \(error)")
            return false
        }

        importedCount = 1
        isSaving = false
        showSuccessAlert = true
        clearForm()
        return true
    }

    // MARK: - Reset

    func clearForm() {
        englishWord = ""
        german = ""
        persian = ""
        exampleSentence = ""
        bulkText = ""
        parsedEntries = []
        isEditing = false
        editingVocabulary = nil
        error = nil
    }
}
