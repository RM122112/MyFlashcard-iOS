import SwiftUI

struct DictionaryDetailView: View {
    @StateObject private var viewModel = DictionaryDetailViewModel()
    @State private var searchQuery: String = ""
    @Environment(\.openURL) var openURL

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                // Header
                Text("📖 Wörterbuch")
                    .font(.system(.headline, design: .default))
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)

                // Search Bar
                HStack(spacing: 8) {
                    TextField("Wort eingeben ...", text: $searchQuery)
                        .textFieldStyle(.roundedBorder)
                        .frame(height: 40)

                    Button(action: {
                        viewModel.lookupWord(searchQuery)
                    }) {
                        if viewModel.isLoading {
                            ProgressView()
                                .frame(width: 16, height: 16)
                        } else {
                            Text("Suchen")
                        }
                    }
                    .disabled(viewModel.isLoading || searchQuery.trimmingCharacters(in: .whitespaces).isEmpty)
                    .buttonStyle(.bordered)
                    .frame(height: 40)
                }
                .padding(.horizontal)

                // Content
                if viewModel.isLoading {
                    VStack(spacing: 16) {
                        Spacer()
                        ProgressView()
                        Spacer()
                    }
                } else if let error = viewModel.error {
                    VStack(spacing: 12) {
                        HStack(spacing: 12) {
                            Image(systemName: "info.circle")
                                .foregroundColor(.red)
                                .font(.system(size: 20))

                            Text(error)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(12)
                        .background(Color(.systemRed).opacity(0.1))
                        .cornerRadius(8)

                        Spacer()
                    }
                    .padding()
                } else if let lookup = viewModel.lookup {
                    DictionaryResultScrollView(
                        lookup: lookup,
                        onReload: {
                            viewModel.reloadLookup()
                        },
                        onSourceTap: {
                            openURL(URL(string: lookup.sourceURL) ?? URL(fileURLWithPath: ""))
                        }
                    )
                } else {
                    EmptyStateCard()
                }

                Spacer()
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct DictionaryResultScrollView: View {
    let lookup: DictionaryLookup
    let onReload: () -> Void
    let onSourceTap: () -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Source Info Card
                SourceInfoCard(
                    lookup: lookup,
                    onSourceTap: onSourceTap,
                    onReload: onReload
                )

                // Translations
                if !lookup.translations.isEmpty {
                    GroupedHitsSection(translations: lookup.translations)
                }

                // Synonyms
                if !lookup.synonyms.isEmpty {
                    SynonymsSection(synonyms: lookup.synonyms)
                }

                // Examples
                if !lookup.examples.isEmpty {
                    ExamplesSection(examples: lookup.examples)
                }

                if lookup.translations.isEmpty && lookup.synonyms.isEmpty && lookup.examples.isEmpty {
                    EmptyStateCard(small: true)
                }
            }
            .padding()
        }
    }
}

struct SourceInfoCard: View {
    let lookup: DictionaryLookup
    let onSourceTap: () -> Void
    let onReload: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Text("Wort:")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(lookup.query)
                    .font(.system(.headline, design: .default))
                    .fontWeight(.semibold)
            }

            // Description
            if !lookup.description.isEmpty {
                Text(lookup.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            // Part of Speech
            if let partOfSpeech = lookup.primaryPartOfSpeech {
                ChipView(text: partOfSpeech, color: .blue)
            }

            HStack(spacing: 8) {
                Image(systemName: "link")
                    .font(.caption)
                    .foregroundColor(.blue)

                Button(action: onSourceTap) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Quelle öffnen")
                        Text(lookup.sourceName)
                            .foregroundColor(.secondary)
                    }
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.blue)
                    .lineLimit(1)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // Cache Info + Reload
            HStack(spacing: 12) {
                Text(lookup.fromCache ? "📦 Aus Cache" : "🌐 Aktuell")
                    .font(.caption2)
                    .foregroundColor(.secondary)

                Spacer()

                Button(action: onReload) {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.clockwise")
                            .font(.caption2)
                        Text("Neu laden")
                            .font(.caption2)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color(.systemBlue).opacity(0.1))
                    .foregroundColor(.blue)
                    .cornerRadius(6)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color(.systemBlue).opacity(0.1))
        .cornerRadius(8)
    }
}

struct GroupedHitsSection: View {
    let translations: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("🔤 Gruppierte Treffer")
                .font(.system(.caption, design: .default))
                .fontWeight(.semibold)

            VStack(alignment: .leading, spacing: 8) {
                ForEach(Array(translations.enumerated()), id: \.offset) { index, translation in
                    HStack(alignment: .top, spacing: 10) {
                        ChipView(text: "\(index + 1)", color: .blue)
                        Text(translation)
                            .font(.caption)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(10)
                    .background(Color(.systemBackground))
                    .cornerRadius(8)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

struct EmptyStateCard: View {
    var small: Bool = false

    var body: some View {
        VStack(spacing: small ? 8 : 10) {
            Text("📚")
                .font(.system(size: small ? 30 : 48))
            Text(small ? "Noch kein Treffer geladen" : "Dictionary bereit")
                .font(small ? .caption.bold() : .headline)
            Text(small ? "Neu laden oder ein Wort suchen." : "Suche ein Wort, um Treffer, Quellen und Beispiele zu sehen.")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(small ? 16 : 24)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct SynonymsSection: View {
    let synonyms: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("🔄 Synonyme")
                .font(.system(.caption, design: .default))
                .fontWeight(.semibold)

            VStack(alignment: .leading, spacing: 6) {
                ForEach(synonyms, id: \.self) { synonym in
                    ChipView(text: synonym, color: .purple)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color(.systemOrange).opacity(0.1))
        .cornerRadius(8)
    }
}

struct ExamplesSection: View {
    let examples: [DictionaryExample]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("💡 Beispiele")
                .font(.system(.caption, design: .default))
                .fontWeight(.semibold)

            VStack(alignment: .leading, spacing: 8) {
                ForEach(Array(examples.enumerated()), id: \.offset) { index, example in
                    ExampleCard(example: example, index: index)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct ExampleCard: View {
    let example: DictionaryExample
    let index: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(example.source)
                .font(.caption2)
                .fontWeight(.semibold)
                .foregroundColor(.primary)

            if !example.translation.isEmpty {
                Text("→ \(example.translation)")
                    .font(.caption2)
                    .foregroundColor(.blue)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(8)
        .background(Color(.systemGreen).opacity(0.1))
        .cornerRadius(6)
    }
}

struct ChipView: View {
    let text: String
    let color: Color

    var body: some View {
        Text(text)
            .font(.caption2)
            .fontWeight(.semibold)
            .foregroundColor(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color.opacity(0.1))
            .cornerRadius(12)
    }
}

// MARK: - ViewModel

@MainActor
class DictionaryDetailViewModel: ObservableObject {
    @Published var lookup: DictionaryLookup?
    @Published var isLoading = false
    @Published var error: String?

    private let bamoozService = BamoozDictionaryService()

    func lookupWord(_ query: String) {
        guard !query.trimmingCharacters(in: .whitespaces).isEmpty else {
            self.error = "Wort eingeben erforderlich"
            return
        }

        isLoading = true
        error = nil

        Task {
            do {
                if let result = try await bamoozService.lookup(query) {
                    self.lookup = result
                    self.error = nil
                } else {
                    self.lookup = nil
                    self.error = "Keine Ergebnisse gefunden für \"\(query)\""
                }
            } catch {
                self.lookup = nil
                self.error = "Fehler beim Nachschlag: \(error.localizedDescription)"
            }
            self.isLoading = false
        }
    }

    func reloadLookup() {
        if let query = lookup?.query {
            lookupWord(query)
        }
    }
}

// MARK: - Service

class BamoozDictionaryService {
    private let baseURL = "https://dic.b-amooz.com/en/dictionary"

    func lookup(_ word: String) async throws -> DictionaryLookup? {
        let query = word.trimmingCharacters(in: .whitespaces).lowercased()
        guard !query.isEmpty else { return nil }

        let encodedWord = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query
        let urlString = "\(baseURL)/w?word=\(encodedWord)"

        guard let url = URL(string: urlString) else { return nil }

        let (data, response) = try await URLSession.shared.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            return nil
        }

        let html = String(data: data, encoding: .utf8) ?? ""
        guard !html.isEmpty else { return nil }

        let description = parseMetaDescription(html)
        let translations = parseTranslations(html)
        let synonyms = parseSynonyms(html)
        let examples = parseExamples(html)

        guard !description.isEmpty || !translations.isEmpty || !synonyms.isEmpty || !examples.isEmpty else {
            return nil
        }

        let now = Date()
        return DictionaryLookup(
            query: word,
            normalizedQuery: query,
            sourceName: "b-amooz dictionary",
            sourceURL: urlString,
            description: description,
            translations: translations,
            synonyms: synonyms,
            examples: examples,
            primaryPartOfSpeech: nil,
            cachedAt: now,
            expiresAt: now,
            fromCache: false,
            isStale: false
        )
    }

    private func parseMetaDescription(_ html: String) -> String {
        if let range = html.range(of: #"<meta\s+name="Description"\s+content="([^"]+)"#, options: .regularExpression) {
            let content = String(html[range])
            if let startIndex = content.firstIndex(of: "\""),
               let endIndex = content[content.index(after: startIndex)...].firstIndex(of: "\"") {
                return String(content[content.index(after: startIndex)..<endIndex])
            }
        }
        return ""
    }

    private func parseTranslations(_ html: String) -> [String] {
        var translations: [String] = []

        let pattern = #"<span[^>]*translation-index[^>]*>.*?</span>\s*<strong>(.*?)</strong>"#
        if let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive, .dotMatchesLineSeparators]) {
            let range = NSRange(html.startIndex..<html.endIndex, in: html)
            let matches = regex.matches(in: html, options: [], range: range)

            for match in matches.prefix(5) {
                if let matchRange = Range(match.range(at: 1), in: html) {
                    let translation = String(html[matchRange])
                        .replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
                        .trimmingCharacters(in: .whitespaces)
                    if !translation.isEmpty {
                        translations.append(translation)
                    }
                }
            }
        }

        return Array(Set(translations)).prefix(5).sorted()
    }

    private func parseSynonyms(_ html: String) -> [String] {
        var synonyms: [String] = []

        let pattern = #"badge-pill\s+badge-primary[^>]*>(.*?)</small>"#
        if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
            let range = NSRange(html.startIndex..<html.endIndex, in: html)
            let matches = regex.matches(in: html, options: [], range: range)

            for match in matches.prefix(6) {
                if let matchRange = Range(match.range(at: 1), in: html) {
                    let synonym = String(html[matchRange])
                        .replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
                        .trimmingCharacters(in: .whitespaces)
                    if !synonym.isEmpty {
                        synonyms.append(synonym)
                    }
                }
            }
        }

        return Array(Set(synonyms)).prefix(6).sorted()
    }

    private func parseExamples(_ html: String) -> [DictionaryExample] {
        var examples: [DictionaryExample] = []

        let pattern = #"<div class="col-12 example-box">.*?<span class="m-0">(.*?)</span>.*?<span class="m-0 translation-example-box">(.*?)</span>"#
        if let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive, .dotMatchesLineSeparators]) {
            let range = NSRange(html.startIndex..<html.endIndex, in: html)
            let matches = regex.matches(in: html, options: [], range: range)

            for match in matches.prefix(3) {
                if let sourceRange = Range(match.range(at: 1), in: html),
                   let translationRange = Range(match.range(at: 2), in: html) {
                    let source = String(html[sourceRange])
                        .replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
                        .trimmingCharacters(in: .whitespaces)
                    let translation = String(html[translationRange])
                        .replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
                        .trimmingCharacters(in: .whitespaces)

                    if !source.isEmpty || !translation.isEmpty {
                        examples.append(DictionaryExample(source: source, translation: translation))
                    }
                }
            }
        }

        return Array(examples.prefix(3))
    }
}

#Preview {
    DictionaryDetailView()
}

