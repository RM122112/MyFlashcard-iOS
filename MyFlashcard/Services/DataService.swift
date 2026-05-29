import Foundation
import SwiftData

/// Result of insert operation
enum InsertResult {
    case success(Vocabulary)
    case duplicate(String)
}

/// Result of bulk import
struct BulkImportResult {
    let successCount: Int
    let duplicates: [String]
    var hasDuplicates: Bool { !duplicates.isEmpty }
}

@MainActor
class DataService {
    static let shared = DataService()
    
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
    
    func initializeSampleDataIfNeeded(modelContext: ModelContext) {
        let descriptor = FetchDescriptor<Vocabulary>()
        let count = (try? modelContext.fetchCount(descriptor)) ?? 0
        
        if count == 0 {
            for vocab in DataService.sampleVocabulary {
                modelContext.insert(vocab)
            }
            try? modelContext.save()
        }
    }
    
    /// Check if English word already exists
    func wordExists(_ englishWord: String, in context: ModelContext) -> Bool {
        let searchWord = englishWord.lowercased().trimmingCharacters(in: .whitespaces)
        let descriptor = FetchDescriptor<Vocabulary>()
        let allVocab = (try? context.fetch(descriptor)) ?? []
        return allVocab.contains { 
            $0.englishWord.lowercased().trimmingCharacters(in: .whitespaces) == searchWord 
        }
    }
    
    /// Insert with duplicate check
    func insertWithDuplicateCheck(
        englishWord: String,
        german: String,
        persian: String,
        exampleSentence: String,
        context: ModelContext
    ) -> InsertResult {
        if wordExists(englishWord, in: context) {
            return .duplicate(englishWord)
        }
        
        let vocab = Vocabulary(
            englishWord: englishWord,
            german: german,
            persian: persian,
            exampleSentence: exampleSentence
        )
        context.insert(vocab)
        try? context.save()
        return .success(vocab)
    }
    
    /// Bulk import with duplicate check
    func bulkImportWithDuplicateCheck(
        entries: [ParsedEntry],
        context: ModelContext
    ) -> BulkImportResult {
        var successCount = 0
        var duplicates: [String] = []
        
        for entry in entries where entry.isValid {
            if wordExists(entry.englishWord, in: context) {
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
        
        try? context.save()
        return BulkImportResult(successCount: successCount, duplicates: duplicates)
    }
}

// MARK: - Improved TextParser
class TextParser {
    
    /// Parse bulk text - handles various formats including numbered lists
    static func parseText(_ text: String) -> [ParsedEntry] {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return []
        }
        
        var entries: [ParsedEntry] = []
        let lines = text.components(separatedBy: .newlines)
        
        for line in lines {
            let trimmedLine = line.trimmingCharacters(in: .whitespaces)
            
            // Skip empty lines
            if trimmedLine.isEmpty { continue }
            
            // Skip header lines
            if trimmedLine.hasPrefix("#") { continue }
            if trimmedLine.lowercased().contains("english word") { continue }
            if trimmedLine.lowercased().hasPrefix("english") && trimmedLine.lowercased().contains("german") { continue }
            
            if let entry = parseLine(trimmedLine) {
                entries.append(entry)
            }
        }
        
        return entries
    }
    
    /// Parse a single line - handles numbered entries and various separators
    private static func parseLine(_ line: String) -> ParsedEntry? {
        var workingLine = line
        
        // Remove leading number (e.g., "1", "1.", "1 ", "10")
        if let range = workingLine.range(of: #"^\d+\.?\s*"#, options: .regularExpression) {
            workingLine = String(workingLine[range.upperBound...])
        }
        
        // Try tab-separated first
        var parts = workingLine.components(separatedBy: "\t").map { 
            $0.trimmingCharacters(in: .whitespaces) 
        }.filter { !$0.isEmpty }
        
        // If not enough parts, try multiple spaces (2 or more)
        if parts.count < 3 {
            if let regex = try? NSRegularExpression(pattern: #"\s{2,}"#, options: []) {
                let range = NSRange(workingLine.startIndex..., in: workingLine)
                let modified = regex.stringByReplacingMatches(
                    in: workingLine, 
                    options: [], 
                    range: range, 
                    withTemplate: "\t"
                )
                parts = modified.components(separatedBy: "\t").map { 
                    $0.trimmingCharacters(in: .whitespaces) 
                }.filter { !$0.isEmpty }
            }
        }
        
        // Still not enough? Try to find Persian text pattern to split
        if parts.count < 3 {
            // Persian Unicode range: U+0600 to U+06FF
            let persianPattern = #"[\u{0600}-\u{06FF}]"#
            if let persianRange = workingLine.range(of: persianPattern, options: .regularExpression) {
                // Find where Persian starts
                let beforePersian = String(workingLine[..<persianRange.lowerBound])
                let persianAndAfter = String(workingLine[persianRange.lowerBound...])
                
                // Split before Persian by space
                let beforeParts = beforePersian.trimmingCharacters(in: .whitespaces)
                    .components(separatedBy: " ")
                    .filter { !$0.isEmpty }
                
                if beforeParts.count >= 2 {
                    let english = beforeParts[0]
                    let german = beforeParts[1..<beforeParts.count].joined(separator: " ")
                    
                    // Find where Persian ends (next Latin character or end)
                    var persian = ""
                    var example = ""
                    
                    // Split Persian from example sentence
                    let latinPattern = "[A-Za-z]"
                    if let latinRange = persianAndAfter.range(of: latinPattern, options: .regularExpression) {
                        persian = String(persianAndAfter[..<latinRange.lowerBound]).trimmingCharacters(in: .whitespaces)
                        example = String(persianAndAfter[latinRange.lowerBound...]).trimmingCharacters(in: .whitespaces)
                    } else {
                        persian = persianAndAfter.trimmingCharacters(in: .whitespaces)
                    }
                    
                    if !english.isEmpty && !german.isEmpty {
                        return ParsedEntry(
                            englishWord: english,
                            german: german,
                            persian: persian,
                            exampleSentence: example
                        )
                    }
                }
            }
        }
        
        // Process parts normally
        guard parts.count >= 2 else { return nil }
        
        switch parts.count {
        case 4...:
            return ParsedEntry(
                englishWord: parts[0],
                german: parts[1],
                persian: parts[2],
                exampleSentence: parts[3..<parts.count].joined(separator: " ")
            )
        case 3:
            return ParsedEntry(
                englishWord: parts[0],
                german: parts[1],
                persian: parts[2],
                exampleSentence: ""
            )
        case 2:
            return ParsedEntry(
                englishWord: parts[0],
                german: parts[1],
                persian: "",
                exampleSentence: ""
            )
        default:
            return nil
        }
    }
}
