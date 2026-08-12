import Foundation
import SwiftData

@MainActor
@Observable
class InputViewModel {

    // MARK: - Single Entry

    var englishWord: String = ""
    var german: String = ""
    var persian: String = ""
    var exampleSentence: String = ""

    // MARK: - JSON Import

    var jsonText: String = ""
    var importedEntries: [ImportedVocabEntry] = []
    var importIssues: [VocabImportIssue] = []
    var duplicateWords: [String] = []
    var duplicateStrategy: VocabDuplicateStrategy = .skip

    // MARK: - State

    var isEditing: Bool = false
    var editingVocabulary: Vocabulary?
    var isSaving: Bool = false
    var error: String?
    var importedCount: Int = 0
    var overwrittenCount: Int = 0
    var skippedDuplicateCount: Int = 0
    var showSuccessAlert: Bool = false
    var successMessage: String = ""

    private let importService = VocabJSONImportService.shared

    func setJSONText(_ text: String) {
        jsonText = text
        error = nil
    }

    func parseJSONTextForPreview() {
        let trimmed = jsonText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            importedEntries = []
            importIssues = [VocabImportIssue(englishWord: "<json>", message: "Bitte JSON-Text eingeben.")]
            duplicateWords = []
            return
        }

        guard let data = trimmed.data(using: .utf8) else {
            importedEntries = []
            importIssues = [VocabImportIssue(englishWord: "<json>", message: "JSON konnte nicht als UTF-8 gelesen werden.")]
            duplicateWords = []
            return
        }
        parseJSONDataForPreview(data)
    }

    func parseJSONDataForPreview(_ data: Data) {
        let report = importService.importVocabWithReport(from: data, duplicateStrategy: duplicateStrategy)
        importedEntries = report.entries
        importIssues = report.issues
        duplicateWords = report.duplicates
        error = nil
    }

    func importPreviewEntries(modelContext: ModelContext) {
        guard !importedEntries.isEmpty else {
            error = "Es gibt keine gültigen Einträge zum Import."
            return
        }

        isSaving = true
        let result = DataService.shared.bulkImportJSONWithDuplicateCheck(
            entries: importedEntries,
            duplicateStrategy: duplicateStrategy,
            context: modelContext
        )
        isSaving = false

        importedCount = result.insertedCount
        overwrittenCount = result.overwrittenCount
        skippedDuplicateCount = result.skippedDuplicates.count

        var parts: [String] = []
        if result.insertedCount > 0 {
            parts.append("\(result.insertedCount) neu importiert")
        }
        if result.overwrittenCount > 0 {
            parts.append("\(result.overwrittenCount) überschrieben")
        }
        if result.skippedDuplicates.count > 0 {
            parts.append("\(result.skippedDuplicates.count) Duplikate übersprungen")
        }
        successMessage = parts.isEmpty ? "Keine Änderungen durchgeführt." : parts.joined(separator: " · ")
        showSuccessAlert = true
    }

    func clearJSONImport() {
        jsonText = ""
        importedEntries = []
        importIssues = []
        duplicateWords = []
        error = nil
    }

    // MARK: - Editing

    func loadForEditing(_ vocabulary: Vocabulary) {
        editingVocabulary = vocabulary
        englishWord = vocabulary.englishWord
        german = vocabulary.german
        persian = vocabulary.persian
        exampleSentence = vocabulary.exampleSentence
        isEditing = true
    }

    // MARK: - Save (single entry)

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
            error = "Bitte gib die 🇦🇫-Übersetzung ein."
            return false
        }

        isSaving = true
        error = nil

        if isEditing, let vocab = editingVocabulary {
            vocab.englishWord = englishWord.trimmingCharacters(in: .whitespaces)
            vocab.german = german.trimmingCharacters(in: .whitespaces)
            vocab.persian = persian.trimmingCharacters(in: .whitespaces)
            vocab.exampleSentence = exampleSentence.trimmingCharacters(in: .whitespaces)
        } else {
            let vocabulary = Vocabulary(
                englishWord: englishWord.trimmingCharacters(in: .whitespaces),
                german: german.trimmingCharacters(in: .whitespaces),
                persian: persian.trimmingCharacters(in: .whitespaces),
                exampleSentence: exampleSentence.trimmingCharacters(in: .whitespaces)
            )
            modelContext.insert(vocabulary)
        }

        do {
            try modelContext.save()
        } catch {
            self.error = "Fehler beim Speichern: \(error.localizedDescription)"
            isSaving = false
            return false
        }

        importedCount = 1
        isSaving = false
        showSuccessAlert = true
        successMessage = "Eintrag gespeichert."
        clearForm()
        return true
    }

    // MARK: - Reset

    func clearForm() {
        englishWord = ""
        german = ""
        persian = ""
        exampleSentence = ""
        isEditing = false
        editingVocabulary = nil
        error = nil
    }
}
