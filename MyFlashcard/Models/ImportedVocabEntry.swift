import Foundation

enum ImportedVocabEntryDecodingError: LocalizedError, Equatable {
    case missingField(entry: String, field: String)
    case emptyField(entry: String, field: String)

    var errorDescription: String? {
        switch self {
        case let .missingField(entry, field):
            return "Eintrag '\(entry)': Feld '\(field)' fehlt"
        case let .emptyField(entry, field):
            return "Eintrag '\(entry)': Feld '\(field)' ist leer"
        }
    }
}

struct ImportedVocabEntry: Codable, Identifiable, Equatable {
    let english_word: String
    let feature: String
    let german: String
    let persian: String
    let example_sentence: String
    let persian_translation: String

    var id: String { english_word.lowercased() }

    enum CodingKeys: String, CodingKey {
        case english_word = "english_word"
        case feature = "feature"
        case german = "german"
        case persian = "persian"
        case example_sentence = "example_sentence"
        case persian_translation = "persian_translation"
    }

    init(
        english_word: String,
        feature: String,
        german: String,
        persian: String,
        example_sentence: String,
        persian_translation: String
    ) {
        self.english_word = english_word.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedFeature = feature.trimmingCharacters(in: .whitespacesAndNewlines)
        self.feature = normalizedFeature.isEmpty ? "_" : normalizedFeature
        self.german = german.trimmingCharacters(in: .whitespacesAndNewlines)
        self.persian = persian.trimmingCharacters(in: .whitespacesAndNewlines)
        self.example_sentence = example_sentence.trimmingCharacters(in: .whitespacesAndNewlines)
        self.persian_translation = persian_translation.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        guard let rawEnglish = try container.decodeIfPresent(String.self, forKey: .english_word) else {
            throw ImportedVocabEntryDecodingError.missingField(entry: "<unknown>", field: CodingKeys.english_word.rawValue)
        }
        let english = rawEnglish.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !english.isEmpty else {
            throw ImportedVocabEntryDecodingError.emptyField(entry: "<unknown>", field: CodingKeys.english_word.rawValue)
        }

        guard let rawGerman = try container.decodeIfPresent(String.self, forKey: .german) else {
            throw ImportedVocabEntryDecodingError.missingField(entry: english, field: CodingKeys.german.rawValue)
        }
        let german = rawGerman.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !german.isEmpty else {
            throw ImportedVocabEntryDecodingError.emptyField(entry: english, field: CodingKeys.german.rawValue)
        }

        guard let rawPersian = try container.decodeIfPresent(String.self, forKey: .persian) else {
            throw ImportedVocabEntryDecodingError.missingField(entry: english, field: CodingKeys.persian.rawValue)
        }
        let persian = rawPersian.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !persian.isEmpty else {
            throw ImportedVocabEntryDecodingError.emptyField(entry: english, field: CodingKeys.persian.rawValue)
        }

        guard let rawExample = try container.decodeIfPresent(String.self, forKey: .example_sentence) else {
            throw ImportedVocabEntryDecodingError.missingField(entry: english, field: CodingKeys.example_sentence.rawValue)
        }
        let example = rawExample.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !example.isEmpty else {
            throw ImportedVocabEntryDecodingError.emptyField(entry: english, field: CodingKeys.example_sentence.rawValue)
        }

        guard let rawPersianTranslation = try container.decodeIfPresent(String.self, forKey: .persian_translation) else {
            throw ImportedVocabEntryDecodingError.missingField(entry: english, field: CodingKeys.persian_translation.rawValue)
        }
        let persianTranslation = rawPersianTranslation.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !persianTranslation.isEmpty else {
            throw ImportedVocabEntryDecodingError.emptyField(entry: english, field: CodingKeys.persian_translation.rawValue)
        }

        let rawFeature = try container.decodeIfPresent(String.self, forKey: .feature)?.trimmingCharacters(in: .whitespacesAndNewlines)
        self.init(
            english_word: english,
            feature: rawFeature ?? "_",
            german: german,
            persian: persian,
            example_sentence: example,
            persian_translation: persianTranslation
        )
    }
}
