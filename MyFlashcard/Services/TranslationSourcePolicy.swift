import Foundation

enum TranslationSourcePolicy {
    static let primaryName = "b-amooz dictionary"
    static let primaryURL = URL(string: "https://dic.b-amooz.com/en/dictionary")!

    static var primaryLabel: String {
        "Primärquelle: \(primaryName)"
    }

    static func lookupText(for query: String) -> String {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return primaryURL.absoluteString }
        return "\(primaryURL.absoluteString)?word=\(trimmed.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? trimmed)"
    }
}
