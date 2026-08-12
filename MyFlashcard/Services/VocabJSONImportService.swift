import Foundation

enum VocabDuplicateStrategy: String, CaseIterable, Identifiable {
    case skip = "Duplikate überspringen"
    case overwrite = "Duplikate überschreiben"

    var id: String { rawValue }
}

struct VocabImportIssue: Identifiable, Equatable {
    let englishWord: String
    let message: String

    var id: String { "\(englishWord)-\(message)" }
}

struct VocabImportReport {
    let entries: [ImportedVocabEntry]
    let issues: [VocabImportIssue]
    let duplicates: [String]

    var hasIssues: Bool { !issues.isEmpty }
}

enum VocabImportServiceError: LocalizedError {
    case invalidTopLevel
    case invalidUTF8

    var errorDescription: String? {
        switch self {
        case .invalidTopLevel:
            return "Ungültiges JSON-Format: Erwartet wird ein Array von Objekten."
        case .invalidUTF8:
            return "JSON-Text konnte nicht als UTF-8 gelesen werden."
        }
    }
}

final class VocabJSONImportService {
    static let shared = VocabJSONImportService()

    private init() {}

    func importVocab(from data: Data) throws -> [ImportedVocabEntry] {
        try JSONDecoder().decode([ImportedVocabEntry].self, from: data)
    }

    func importVocab(from jsonText: String) throws -> [ImportedVocabEntry] {
        guard let data = jsonText.data(using: .utf8) else {
            throw VocabImportServiceError.invalidUTF8
        }
        return try importVocab(from: data)
    }

    func importVocabWithReport(
        from data: Data,
        duplicateStrategy: VocabDuplicateStrategy
    ) -> VocabImportReport {
        guard let objects = try? JSONSerialization.jsonObject(with: data) as? [Any] else {
            return VocabImportReport(
                entries: [],
                issues: [VocabImportIssue(englishWord: "<json>", message: VocabImportServiceError.invalidTopLevel.localizedDescription)],
                duplicates: []
            )
        }

        var decodedEntries: [ImportedVocabEntry] = []
        var issues: [VocabImportIssue] = []

        for object in objects {
            guard let dict = object as? [String: Any] else {
                issues.append(
                    VocabImportIssue(
                        englishWord: "<unknown>",
                        message: "Eintrag ist kein JSON-Objekt."
                    )
                )
                continue
            }

            let englishHint = (dict["english_word"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "<unknown>"

            do {
                let entryData = try JSONSerialization.data(withJSONObject: dict)
                let entry = try JSONDecoder().decode(ImportedVocabEntry.self, from: entryData)
                decodedEntries.append(entry)
            } catch let error as ImportedVocabEntryDecodingError {
                issues.append(
                    VocabImportIssue(
                        englishWord: englishHint,
                        message: error.localizedDescription
                    )
                )
            } catch {
                issues.append(
                    VocabImportIssue(
                        englishWord: englishHint,
                        message: "Eintrag '\(englishHint)' konnte nicht gelesen werden: \(error.localizedDescription)"
                    )
                )
            }
        }

        var seenIndex: [String: Int] = [:]
        var deduplicatedEntries: [ImportedVocabEntry] = []
        var duplicateWords: [String] = []

        for entry in decodedEntries {
            let key = entry.english_word.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
            if let existingIndex = seenIndex[key] {
                duplicateWords.append(entry.english_word)
                issues.append(
                    VocabImportIssue(
                        englishWord: entry.english_word,
                        message: "Duplikat '\(entry.english_word)' im Import erkannt."
                    )
                )
                if duplicateStrategy == .overwrite {
                    deduplicatedEntries[existingIndex] = entry
                }
                continue
            }
            seenIndex[key] = deduplicatedEntries.count
            deduplicatedEntries.append(entry)
        }

        return VocabImportReport(
            entries: deduplicatedEntries,
            issues: issues,
            duplicates: duplicateWords.uniquedPreservingOrder()
        )
    }
}

private extension Array where Element == String {
    func uniquedPreservingOrder() -> [String] {
        var seen: Set<String> = []
        var output: [String] = []
        for value in self {
            let key = value.lowercased()
            if seen.insert(key).inserted {
                output.append(value)
            }
        }
        return output
    }
}
