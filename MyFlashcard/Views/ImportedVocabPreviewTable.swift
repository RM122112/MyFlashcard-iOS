import SwiftUI

struct ImportedVocabPreviewRow: Identifiable, Equatable {
    let englishWord: String
    let feature: String
    let german: String
    let persian: String
    let exampleSentence: String
    let persianTranslation: String

    var id: String { englishWord.lowercased() + "|" + feature + "|" + german }

    init(entry: ImportedVocabEntry) {
        englishWord = entry.english_word
        feature = entry.feature
        german = entry.german
        persian = entry.persian
        exampleSentence = entry.example_sentence
        persianTranslation = entry.persian_translation
    }
}

struct ImportedVocabPreviewTable: View {
    let entries: [ImportedVocabEntry]

    private let englishWidth: CGFloat = 140
    private let featureWidth: CGFloat = 120
    private let germanWidth: CGFloat = 140
    private let persianWidth: CGFloat = 170
    private let exampleWidth: CGFloat = 280
    private let persianTranslationWidth: CGFloat = 300

    private var rows: [ImportedVocabPreviewRow] {
        entries.map(ImportedVocabPreviewRow.init(entry:))
    }

    var body: some View {
        ScrollView([.horizontal, .vertical]) {
            VStack(spacing: 0) {
                headerRow
                Divider()
                ForEach(rows) { row in
                    dataRow(row)
                    Divider()
                }
            }
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .frame(maxHeight: 340)
    }

    private var headerRow: some View {
        HStack(spacing: 0) {
            headerCell("English Word", width: englishWidth)
            headerCell("Feature", width: featureWidth)
            headerCell("German", width: germanWidth)
            headerCell("🇦🇫 Persian (Farsi)", width: persianWidth)
            headerCell("Example Sentence", width: exampleWidth)
            headerCell("🇦🇫 Persian Translation", width: persianTranslationWidth)
        }
        .background(Color(.tertiarySystemBackground))
    }

    private func dataRow(_ row: ImportedVocabPreviewRow) -> some View {
        HStack(spacing: 0) {
            valueCell(row.englishWord, width: englishWidth)
            valueCell(row.feature, width: featureWidth)
            valueCell(row.german, width: germanWidth)
            valueCell(row.persian, width: persianWidth, rtl: true)
            valueCell(row.exampleSentence, width: exampleWidth)
            valueCell(row.persianTranslation, width: persianTranslationWidth, rtl: true)
        }
    }

    private func headerCell(_ value: String, width: CGFloat) -> some View {
        Text(value)
            .font(.caption.weight(.semibold))
            .foregroundStyle(.secondary)
            .frame(width: width, alignment: .leading)
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
    }

    private func valueCell(_ value: String, width: CGFloat, rtl: Bool = false) -> some View {
        Text(value)
            .font(.footnote)
            .multilineTextAlignment(rtl ? .trailing : .leading)
            .environment(\.layoutDirection, rtl ? .rightToLeft : .leftToRight)
            .frame(width: width, alignment: rtl ? .trailing : .leading)
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
    }
}
