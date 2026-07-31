import Foundation
import SwiftData
import OSLog

// MARK: - Insert Results

/// Ergebnis eines einzelnen Einfüge-Vorgangs.
enum InsertResult {
    case success(Vocabulary)
    case duplicate(String)
}

/// Ergebnis eines Massenimports.
struct BulkImportResult {
    let successCount: Int
    let duplicates: [String]
    var hasDuplicates: Bool { !duplicates.isEmpty }
}

// MARK: - DataService

/// Zentrale Datenzugriffsschicht für Vokabeleinträge.
///
/// Kapselt Einfüge-, Duplikatprüf- und Seed-Logik für den SwiftData-Store.
/// Alle Methoden erwarten einen `ModelContext` und sind `@MainActor`-gebunden.
///
/// **Architekturentscheidung:** Als einfacher Singleton ohne vollständiges
/// Repository-Pattern umgesetzt, da SwiftData mit `@Query` direkt im View
/// den Großteil der Lesezugriffe übernimmt. Ein vollständiges Repository
/// wird in Phase 2 eingeführt.
@MainActor
class DataService {
    static let shared = DataService()
    private let logger = Logger(subsystem: "com.myflashcard.ios", category: "DataService")

    // MARK: - Sample Data

    static let sampleVocabulary: [Vocabulary] = [
        Vocabulary(
            englishWord: "accomplish",
            german: "erreichen, vollbringen",
            persian: "انجام دادن، به هدف رسیدن",
            exampleSentence: "I accomplished all my goals this month."
        ),
        Vocabulary(
            englishWord: "improve",
            german: "verbessern",
            persian: "بهبود بخشیدن",
            exampleSentence: "I want to improve my English speaking skills."
        ),
        Vocabulary(
            englishWord: "achieve",
            german: "erreichen, erzielen",
            persian: "دست یافتن، رسیدن به",
            exampleSentence: "She achieved her dream of becoming a doctor."
        )
    ]

    // MARK: - Initialization

    /// Befüllt die Datenbank beim ersten Start mit Beispieldaten.
    func initializeSampleDataIfNeeded(modelContext: ModelContext) {
        let descriptor = FetchDescriptor<Vocabulary>()
        let count = (try? modelContext.fetchCount(descriptor)) ?? 0
        guard count == 0 else { return }

        for vocab in DataService.sampleVocabulary {
            modelContext.insert(vocab)
        }
        save(modelContext: modelContext, context: "initializeSampleData")
    }

    // MARK: - Duplicate Check

    /// Prüft effizient, ob ein englisches Wort bereits existiert.
    ///
    /// **Vorher:** Alle Vokabeln wurden geladen und in Swift gefiltert – O(n).
    /// **Nachher:** SwiftData-`FetchDescriptor` mit `#Predicate` filtert
    /// direkt auf SQLite-Ebene – O(log n) mit Index.
    ///
    /// - Parameters:
    ///   - englishWord: Das zu prüfende englische Wort (Groß-/Kleinschreibung ignoriert).
    ///   - context: Der aktive `ModelContext`.
    /// - Returns: `true` wenn das Wort bereits vorhanden ist.
    func wordExists(_ englishWord: String, in context: ModelContext) -> Bool {
        let normalizedWord = englishWord.lowercased().trimmingCharacters(in: .whitespaces)
        var descriptor = FetchDescriptor<Vocabulary>(
            predicate: #Predicate { $0.englishWord == normalizedWord }
        )
        descriptor.fetchLimit = 1
        let count = (try? context.fetchCount(descriptor)) ?? 0
        return count > 0
    }

    // MARK: - Insert

    /// Fügt ein einzelnes Wort ein, falls es noch nicht existiert.
    func insertWithDuplicateCheck(
        englishWord: String,
        german: String,
        persian: String,
        exampleSentence: String,
        context: ModelContext
    ) -> InsertResult {
        let trimmed = englishWord.lowercased().trimmingCharacters(in: .whitespaces)
        if wordExists(trimmed, in: context) {
            return .duplicate(englishWord)
        }

        let vocab = Vocabulary(
            englishWord: englishWord.trimmingCharacters(in: .whitespaces),
            german: german,
            persian: persian,
            exampleSentence: exampleSentence
        )
        context.insert(vocab)
        save(modelContext: context, context: "insertWithDuplicateCheck")
        return .success(vocab)
    }

    /// Importiert mehrere Einträge auf einmal mit Duplikatprüfung.
    ///
    /// Optimierung: Lädt einmalig alle vorhandenen englischen Wörter als
    /// normalisiertes Set, um N Einzelabfragen zu vermeiden.
    func bulkImportWithDuplicateCheck(
        entries: [ParsedEntry],
        context: ModelContext
    ) -> BulkImportResult {
        // Einmalig alle existierenden Wörter laden (für Bulk effizienter als N Einzelabfragen)
        let existingDescriptor = FetchDescriptor<Vocabulary>()
        let existing = (try? context.fetch(existingDescriptor)) ?? []
        let existingWords = Set(existing.map { $0.englishWord.lowercased().trimmingCharacters(in: .whitespaces) })

        var successCount = 0
        var duplicates: [String] = []

        for entry in entries where entry.isValid {
            let normalized = entry.englishWord.lowercased().trimmingCharacters(in: .whitespaces)
            if existingWords.contains(normalized) {
                duplicates.append(entry.englishWord)
            } else {
                let vocab = Vocabulary(
                    englishWord: entry.englishWord,
                    german: entry.german,
                    persian: entry.persian,
                    exampleSentence: entry.exampleSentence
                )
                context.insert(vocab)
                successCount += 1
            }
        }

        save(modelContext: context, context: "bulkImport(\(successCount) Einträge)")
        return BulkImportResult(successCount: successCount, duplicates: duplicates)
    }

    // MARK: - Private Helpers

    /// Speichert den Context und loggt Fehler strukturiert.
    private func save(modelContext: ModelContext, context: String) {
        do {
            try modelContext.save()
        } catch {
            logger.error("[\(context)] Speichern fehlgeschlagen: \(error.localizedDescription)")
        }
    }
}

// MARK: - TextParser

/// Parser für tabulatorseparierte Bulk-Eingaben (Vokabellisten).
///
/// Unterstützt mehrere Formate:
/// - Tab-separiert: `word\tGerman\tPersian\tExample`
/// - Mehrfach-Leerzeichen-separiert
/// - Persisches Unicode als Trennmarker
class TextParser {

    /// Parst einen mehrzeiligen Text und gibt eine Liste von `ParsedEntry` zurück.
    static func parseText(_ text: String) -> [ParsedEntry] {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return []
        }

        return text
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty && !$0.hasPrefix("#") }
            .filter { !isHeaderLine($0) }
            .compactMap { parseLine($0) }
    }

    private static func isHeaderLine(_ line: String) -> Bool {
        let lower = line.lowercased()
        return lower.contains("english word") ||
               (lower.hasPrefix("english") && lower.contains("german"))
    }

    /// Parst eine einzelne Zeile in ein `ParsedEntry`.
    private static func parseLine(_ line: String) -> ParsedEntry? {
        var workingLine = line

        // Führende Nummerierung entfernen (z.B. "1.", "10 ")
        if let range = workingLine.range(of: #"^\d+\.?\s*"#, options: .regularExpression) {
            workingLine = String(workingLine[range.upperBound...])
        }

        // Tab-separiert (bevorzugtes Format)
        var parts = workingLine
            .components(separatedBy: "\t")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }

        // Mehrfach-Leerzeichen als Fallback
        if parts.count < 3 {
            if let regex = try? NSRegularExpression(pattern: #"\s{2,}"#) {
                let range = NSRange(workingLine.startIndex..., in: workingLine)
                let modified = regex.stringByReplacingMatches(
                    in: workingLine, range: range, withTemplate: "\t"
                )
                parts = modified
                    .components(separatedBy: "\t")
                    .map { $0.trimmingCharacters(in: .whitespaces) }
                    .filter { !$0.isEmpty }
            }
        }

        // Persisches Unicode als Trennmarker
        if parts.count < 3 {
            parts = splitByPersianScript(workingLine) ?? parts
        }

        guard parts.count >= 2 else { return nil }

        return ParsedEntry(
            englishWord: parts[0],
            german: parts[1],
            persian: parts.count >= 3 ? parts[2] : "",
            exampleSentence: parts.count >= 4 ? parts[3...].joined(separator: " ") : ""
        )
    }

    private static func splitByPersianScript(_ line: String) -> [String]? {
        let persianPattern = #"[\u{0600}-\u{06FF}]"#
        guard let persianRange = line.range(of: persianPattern, options: .regularExpression) else {
            return nil
        }

        let beforePersian = String(line[..<persianRange.lowerBound])
        let persianAndAfter = String(line[persianRange.lowerBound...])

        let beforeParts = beforePersian
            .trimmingCharacters(in: .whitespaces)
            .components(separatedBy: " ")
            .filter { !$0.isEmpty }

        guard beforeParts.count >= 2 else { return nil }

        let english = beforeParts[0]
        let german = beforeParts[1...].joined(separator: " ")

        var persian = persianAndAfter
        var example = ""

        if let latinRange = persianAndAfter.range(of: "[A-Za-z]", options: .regularExpression) {
            persian = String(persianAndAfter[..<latinRange.lowerBound]).trimmingCharacters(in: .whitespaces)
            example = String(persianAndAfter[latinRange.lowerBound...]).trimmingCharacters(in: .whitespaces)
        }

        return [english, german, persian, example].filter { !$0.isEmpty }
    }
}

