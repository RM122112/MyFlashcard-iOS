import Foundation
import NaturalLanguage
#if canImport(UIKit)
import UIKit
#endif

/// Text Analysis Service - Offline text analysis using Apple's NaturalLanguage framework
class TextAnalysisService {
    static let shared = TextAnalysisService()

    private let tagger = NLTagger(tagSchemes: [.lexicalClass, .lemma, .language])
    #if canImport(UIKit)
    private let spellChecker = UITextChecker()
    #endif

    /// Analyze text and return detailed results
    func analyzeText(_ text: String) -> TextAnalysisResult {
        tagger.string = text

        var analyzedWords: [AnalyzedWord] = []
        var grammarIssues: [GrammarIssue] = []

        // Detect language
        let detectedLanguage = detectLanguage(text)

        // Tokenize and analyze each word
        let range = text.startIndex..<text.endIndex
        tagger.enumerateTags(in: range, unit: .word, scheme: .lexicalClass, options: [.omitWhitespace, .omitPunctuation]) { tag, tokenRange in
            let word = String(text[tokenRange])
            let pos = mapTagToPartOfSpeech(tag)
            let lemma = getLemma(for: tokenRange, in: text)

            analyzedWords.append(AnalyzedWord(
                word: word,
                partOfSpeech: pos,
                lemma: lemma,
                language: detectedLanguage
            ))

            return true
        }

        // Run all checks
        grammarIssues.append(contentsOf: checkSpelling(text, language: detectedLanguage))
        grammarIssues.append(contentsOf: checkGrammarIssues(text))
        grammarIssues.append(contentsOf: checkSentenceStructure(text))
        grammarIssues.append(contentsOf: checkImprovementSuggestions(text, words: analyzedWords))

        // Count sentences
        let sentences = countSentences(text)
        let cefrEstimate = estimateCEFRLevel(text: text, words: analyzedWords, issues: grammarIssues)
        let weaknessAreas = detectWeaknessAreas(issues: grammarIssues)
        let recommendedExercises = buildExerciseRecommendations(for: weaknessAreas)

        return TextAnalysisResult(
            originalText: text,
            words: analyzedWords,
            sentences: sentences,
            wordCount: analyzedWords.count,
            characterCount: text.count,
            detectedLanguage: detectedLanguage,
            grammarIssues: grammarIssues,
            cefrEstimate: cefrEstimate,
            weaknessAreas: weaknessAreas,
            recommendedExercises: recommendedExercises
        )
    }

    /// Detect the language of the text
    func detectLanguage(_ text: String) -> String {
        let recognizer = NLLanguageRecognizer()
        recognizer.processString(text)

        if let language = recognizer.dominantLanguage {
            switch language {
            case .english: return "English"
            case .german: return "German"
            case .persian: return "Persian"
            default: return language.rawValue
            }
        }
        return "Unknown"
    }

    /// Get lemma (base form) of a word
    private func getLemma(for range: Range<String.Index>, in text: String) -> String {
        tagger.string = text
        if let tag = tagger.tag(at: range.lowerBound, unit: .word, scheme: .lemma).0 {
            return tag.rawValue
        }
        return String(text[range])
    }

    /// Map NLTag to PartOfSpeech
    private func mapTagToPartOfSpeech(_ tag: NLTag?) -> PartOfSpeech {
        guard let tag = tag else { return .unknown }

        switch tag {
        case .noun: return .noun
        case .verb: return .verb
        case .adjective: return .adjective
        case .adverb: return .adverb
        case .pronoun: return .pronoun
        case .preposition: return .preposition
        case .conjunction: return .conjunction
        case .determiner: return .determiner
        case .interjection: return .interjection
        default: return .unknown
        }
    }

    /// Count sentences in text
    private func countSentences(_ text: String) -> Int {
        let tokenizer = NLTokenizer(unit: .sentence)
        tokenizer.string = text
        var count = 0
        tokenizer.enumerateTokens(in: text.startIndex..<text.endIndex) { _, _ in
            count += 1
            return true
        }
        return max(count, 1)
    }

    // MARK: - Spelling Check

    /// Check spelling using UITextChecker
    private func checkSpelling(_ text: String, language: String) -> [GrammarIssue] {
        var issues: [GrammarIssue] = []

        #if canImport(UIKit)
        let langCode: String
        switch language {
        case "English": langCode = "en_US"
        case "German": langCode = "de_DE"
        default: langCode = "en_US"
        }

        let nsText = text as NSString
        let fullRange = NSRange(location: 0, length: nsText.length)
        var searchRange = fullRange

        while searchRange.location < nsText.length {
            let misspelledRange = spellChecker.rangeOfMisspelledWord(
                in: text,
                range: searchRange,
                startingAt: searchRange.location,
                wrap: false,
                language: langCode
            )

            if misspelledRange.location == NSNotFound { break }

            let misspelledWord = nsText.substring(with: misspelledRange)
            let guesses = spellChecker.guesses(forWordRange: misspelledRange, in: text, language: langCode) ?? []
            let suggestion = guesses.first ?? misspelledWord

            issues.append(GrammarIssue(
                word: misspelledWord,
                issue: "Possible spelling mistake",
                suggestion: suggestion,
                position: misspelledRange.location,
                type: .spelling
            ))

            let nextLocation = misspelledRange.location + misspelledRange.length
            searchRange = NSRange(location: nextLocation, length: nsText.length - nextLocation)
        }
        #endif

        return issues
    }

    // MARK: - Grammar Check

    /// Check for common grammar issues
    private func checkGrammarIssues(_ text: String) -> [GrammarIssue] {
        var issues: [GrammarIssue] = []
        let words = text.lowercased().components(separatedBy: .whitespaces).filter { !$0.isEmpty }

        // Check "a" vs "an"
        for (index, word) in words.enumerated() {
            let cleanWord = word.trimmingCharacters(in: .punctuationCharacters)

            if cleanWord == "a" && index + 1 < words.count {
                let nextWord = words[index + 1].trimmingCharacters(in: .punctuationCharacters)
                let vowels: Set<Character> = ["a", "e", "i", "o", "u"]
                if let firstChar = nextWord.first, vowels.contains(firstChar),
                   !["university", "user", "useful", "european", "one", "uniform"].contains(nextWord) {
                    issues.append(GrammarIssue(
                        word: "a \(nextWord)",
                        issue: "Use 'an' before words starting with a vowel sound",
                        suggestion: "an \(nextWord)",
                        position: index,
                        type: .grammar
                    ))
                }
            }

            if cleanWord == "an" && index + 1 < words.count {
                let nextWord = words[index + 1].trimmingCharacters(in: .punctuationCharacters)
                let vowels: Set<Character> = ["a", "e", "i", "o", "u"]
                if let firstChar = nextWord.first, !vowels.contains(firstChar),
                   firstChar != "h" {
                    issues.append(GrammarIssue(
                        word: "an \(nextWord)",
                        issue: "Use 'a' before words starting with a consonant sound",
                        suggestion: "a \(nextWord)",
                        position: index,
                        type: .grammar
                    ))
                }
            }

            // Check double words
            if index > 0 {
                let prevWord = words[index - 1].trimmingCharacters(in: .punctuationCharacters)
                if cleanWord == prevWord && !cleanWord.isEmpty &&
                   !["very", "had", "that", "no"].contains(cleanWord) {
                    issues.append(GrammarIssue(
                        word: "\(cleanWord) \(cleanWord)",
                        issue: "Possible repeated word",
                        suggestion: cleanWord,
                        position: index,
                        type: .grammar
                    ))
                }
            }
        }

        // Check common mistakes
        let commonMistakes: [(wrong: String, correct: String, issue: String)] = [
            ("your welcome", "you're welcome", "Use 'you're' (you are), not 'your' (possessive)"),
            ("could of", "could have", "Use 'could have', not 'could of'"),
            ("should of", "should have", "Use 'should have', not 'should of'"),
            ("would of", "would have", "Use 'would have', not 'would of'"),
            ("must of", "must have", "Use 'must have', not 'must of'"),
            ("alot", "a lot", "'A lot' is two words"),
            ("dont", "don't", "Missing apostrophe in 'don't'"),
            ("wont", "won't", "Missing apostrophe in 'won't'"),
            ("cant ", "can't ", "Missing apostrophe in 'can't'"),
            ("doesnt", "doesn't", "Missing apostrophe in 'doesn't'"),
            ("isnt", "isn't", "Missing apostrophe in 'isn't'"),
            ("arent", "aren't", "Missing apostrophe in 'aren't'"),
            ("wasnt", "wasn't", "Missing apostrophe in 'wasn't'"),
            ("werent", "weren't", "Missing apostrophe in 'weren't'"),
            ("hasnt", "hasn't", "Missing apostrophe in 'hasn't'"),
            ("havent", "haven't", "Missing apostrophe in 'haven't'"),
            ("hadnt", "hadn't", "Missing apostrophe in 'hadn't'"),
            ("shouldnt", "shouldn't", "Missing apostrophe in 'shouldn't'"),
            ("wouldnt", "wouldn't", "Missing apostrophe in 'wouldn't'"),
            ("couldnt", "couldn't", "Missing apostrophe in 'couldn't'"),
            ("its a", "it's a", "Use 'it's' (it is) when meaning 'it is'"),
            ("their is", "there is", "Use 'there is' for existence, not 'their is'"),
            ("their are", "there are", "Use 'there are' for existence, not 'their are'"),
            ("more better", "better", "Don't use 'more' with comparative -er forms"),
            ("more worse", "worse", "Don't use 'more' with comparative -er forms"),
            ("most best", "best", "Don't use 'most' with superlative forms"),
            ("very unique", "unique", "'Unique' is absolute - cannot be modified by 'very'"),
            ("i ", "I ", "Capitalize the pronoun 'I'"),
            ("im ", "I'm ", "Capitalize 'I' and add apostrophe")
        ]

        let lowerText = " " + text.lowercased() + " "
        for mistake in commonMistakes {
            if lowerText.contains(" \(mistake.wrong)") || lowerText.contains("\(mistake.wrong) ") {
                issues.append(GrammarIssue(
                    word: mistake.wrong.trimmingCharacters(in: .whitespaces),
                    issue: mistake.issue,
                    suggestion: mistake.correct.trimmingCharacters(in: .whitespaces),
                    position: 0,
                    type: .grammar
                ))
            }
        }

        return issues
    }

    // MARK: - Sentence Structure Check

    /// Check sentence structure problems
    private func checkSentenceStructure(_ text: String) -> [GrammarIssue] {
        var issues: [GrammarIssue] = []
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return issues }

        // Tokenize into sentences
        let tokenizer = NLTokenizer(unit: .sentence)
        tokenizer.string = text
        var sentenceIndex = 0

        tokenizer.enumerateTokens(in: text.startIndex..<text.endIndex) { range, _ in
            let sentence = String(text[range]).trimmingCharacters(in: .whitespacesAndNewlines)
            guard !sentence.isEmpty else { return true }

            // Check: first letter capitalized
            if let firstChar = sentence.first, firstChar.isLetter, !firstChar.isUppercase {
                let preview = String(sentence.prefix(20))
                issues.append(GrammarIssue(
                    word: preview,
                    issue: "Sentence should start with a capital letter",
                    suggestion: "Capitalize the first letter",
                    position: sentenceIndex,
                    type: .structure
                ))
            }

            // Check: ends with punctuation
            if let lastChar = sentence.last, !".!?".contains(lastChar) {
                let preview = String(sentence.suffix(20))
                issues.append(GrammarIssue(
                    word: preview,
                    issue: "Sentence should end with punctuation (. ! ?)",
                    suggestion: "\(preview).",
                    position: sentenceIndex,
                    type: .structure
                ))
            }

            // Check: sentence too long (> 35 words)
            let wordCount = sentence.split(separator: " ").count
            if wordCount > 35 {
                issues.append(GrammarIssue(
                    word: "Long sentence (\(wordCount) words)",
                    issue: "Very long sentence - consider splitting into shorter ones",
                    suggestion: "Split this sentence",
                    position: sentenceIndex,
                    type: .structure
                ))
            }

            sentenceIndex += 1
            return true
        }

        // Check: multiple spaces
        if text.contains("  ") {
            issues.append(GrammarIssue(
                word: "Multiple spaces",
                issue: "Found multiple consecutive spaces",
                suggestion: "Use a single space",
                position: 0,
                type: .structure
            ))
        }

        // Check: space before punctuation
        let beforePunctuation = [" ,", " .", " !", " ?", " ;", " :"]
        for pattern in beforePunctuation {
            if text.contains(pattern) {
                issues.append(GrammarIssue(
                    word: pattern,
                    issue: "No space before punctuation",
                    suggestion: pattern.trimmingCharacters(in: .whitespaces),
                    position: 0,
                    type: .structure
                ))
                break
            }
        }

        return issues
    }

    // MARK: - Improvement Suggestions

    /// Check for stylistic improvements (returns blue suggestions)
    private func checkImprovementSuggestions(_ text: String, words: [AnalyzedWord]) -> [GrammarIssue] {
        var issues: [GrammarIssue] = []
        let lowerText = text.lowercased()

        // Suggest alternatives for overused words
        let stylisticAlternatives: [(word: String, alternatives: String, reason: String)] = [
            ("very good", "excellent / outstanding / superb", "Use a stronger word instead of 'very good'"),
            ("very bad", "terrible / awful / dreadful", "Use a stronger word instead of 'very bad'"),
            ("very big", "huge / enormous / massive", "Use a more precise word"),
            ("very small", "tiny / minuscule", "Use a more precise word"),
            ("very tired", "exhausted / drained", "Use a stronger word"),
            ("very happy", "delighted / thrilled / ecstatic", "Use a stronger word"),
            ("very sad", "miserable / devastated", "Use a stronger word"),
            ("very hungry", "starving / famished", "Use a stronger word"),
            ("very angry", "furious / enraged", "Use a stronger word"),
            ("very fast", "rapid / swift", "Use a more precise word"),
            ("very slow", "sluggish", "Use a more precise word"),
            ("a lot of", "many / numerous / plenty of", "Try a more formal alternative"),
            ("kind of", "somewhat / rather", "More formal alternative"),
            ("sort of", "somewhat / rather", "More formal alternative"),
            ("things", "items / objects / aspects", "Use a more specific noun"),
            ("stuff", "items / belongings / materials", "Use a more specific noun"),
            ("nice", "pleasant / enjoyable / lovely", "Try a more descriptive adjective"),
            ("good", "excellent / great / wonderful", "Try a more descriptive adjective"),
            ("bad", "poor / inadequate / awful", "Try a more descriptive adjective"),
            ("get", "obtain / receive / acquire", "Try a more formal verb"),
            ("got", "received / obtained / acquired", "Try a more formal verb"),
            ("really", "truly / genuinely", "More formal alternative"),
            ("in order to", "to", "Simpler alternative"),
            ("due to the fact that", "because", "Simpler alternative"),
            ("at this point in time", "now", "Simpler alternative"),
            ("in the event that", "if", "Simpler alternative")
        ]

        for item in stylisticAlternatives {
            if lowerText.contains(item.word) {
                issues.append(GrammarIssue(
                    word: item.word,
                    issue: item.reason,
                    suggestion: item.alternatives,
                    position: 0,
                    type: .suggestion
                ))
            }
        }

        // Suggest avoiding passive voice overuse (very basic check)
        let passiveIndicators = [" is being ", " was being ", " has been ", " have been ", " had been "]
        var passiveCount = 0
        for indicator in passiveIndicators {
            passiveCount += lowerText.components(separatedBy: indicator).count - 1
        }
        if passiveCount >= 3 {
            issues.append(GrammarIssue(
                word: "Frequent passive voice",
                issue: "Text contains many passive forms - active voice is often clearer",
                suggestion: "Consider using active voice",
                position: 0,
                type: .suggestion
            ))
        }

        // Suggest variety if same sentence starter is used repeatedly
        let tokenizer = NLTokenizer(unit: .sentence)
        tokenizer.string = text
        var sentenceStarters: [String] = []
        tokenizer.enumerateTokens(in: text.startIndex..<text.endIndex) { range, _ in
            let sentence = String(text[range]).trimmingCharacters(in: .whitespacesAndNewlines)
            if let firstWord = sentence.split(separator: " ").first {
                sentenceStarters.append(String(firstWord).lowercased())
            }
            return true
        }
        let starterCounts = Dictionary(grouping: sentenceStarters, by: { $0 }).mapValues { $0.count }
        for (starter, count) in starterCounts where count >= 3 && starter.count > 1 {
            issues.append(GrammarIssue(
                word: "Repeated sentence starter: '\(starter)'",
                issue: "The word '\(starter)' starts \(count) sentences - vary your sentence openings",
                suggestion: "Try different sentence beginnings",
                position: 0,
                type: .suggestion
            ))
        }

        return issues
    }

    // MARK: - Learning Focus

    private func estimateCEFRLevel(text: String, words: [AnalyzedWord], issues: [GrammarIssue]) -> String {
        let tokenCount = max(words.count, 1)
        let uniqueCount = Set(words.map { $0.lemma.lowercased() }).count
        let lexicalVariety = Double(uniqueCount) / Double(tokenCount)
        let avgSentenceLength = Double(tokenCount) / Double(max(countSentences(text), 1))
        let grammarPenalty = Double(issues.filter { $0.type == .grammar || $0.type == .structure }.count)

        var score = 0.0
        score += lexicalVariety * 50
        score += min(avgSentenceLength, 28) * 1.2
        score -= grammarPenalty * 1.8

        switch score {
        case ..<14: return "A1"
        case 14..<19: return "A2"
        case 19..<24: return "B1"
        case 24..<30: return "B2"
        case 30..<36: return "C1"
        default: return "C2"
        }
    }

    private func detectWeaknessAreas(issues: [GrammarIssue]) -> [String] {
        var buckets: [String: Int] = [:]
        for issue in issues {
            switch issue.type {
            case .spelling:
                buckets["Rechtschreibung", default: 0] += 1
            case .grammar:
                buckets["Grammatikregeln", default: 0] += 1
            case .structure:
                buckets["Satzstruktur", default: 0] += 1
            case .suggestion:
                buckets["Wortschatz & Stil", default: 0] += 1
            }
        }

        return buckets
            .sorted { lhs, rhs in
                if lhs.value == rhs.value { return lhs.key < rhs.key }
                return lhs.value > rhs.value
            }
            .map { "\($0.key) (\($0.value))" }
            .prefix(3)
            .map { $0 }
    }

    private func buildExerciseRecommendations(for weaknessAreas: [String]) -> [String] {
        guard !weaknessAreas.isEmpty else {
            return ["Kurzen freien Text (5-6 Saetze) schreiben und auf Konsistenz pruefen."]
        }

        var recommendations: [String] = []
        for area in weaknessAreas {
            if area.contains("Grammatik") {
                recommendations.append("10 Min. gezielte Grammatikuebung (Zeitformen + Artikel) mit eigenen Beispielen.")
            } else if area.contains("Satzstruktur") {
                recommendations.append("Schreibe 5 kurze Saetze mit klarer Subjekt-Verb-Struktur und korrekter Interpunktion.")
            } else if area.contains("Rechtschreibung") {
                recommendations.append("Diktat mit 8-10 Woertern und anschliessendem Selbstkorrektur-Check.")
            } else if area.contains("Wortschatz") {
                recommendations.append("Ersetze 5 allgemeine Woerter durch praezisere Synonyme in eigenen Saetzen.")
            }
        }
        return Array(NSOrderedSet(array: recommendations)) as? [String] ?? recommendations
    }
}
