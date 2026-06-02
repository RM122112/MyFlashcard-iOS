import Foundation

/// SM-2 Spaced Repetition Algorithm
/// Based on: https://www.supermemo.com/en/archives1990-2015/english/ol/sm2
struct SRSService {

    private enum ProgressKeys {
        static let currentStreak = "currentStreak"
        static let lastStudyDate = "lastStudyDate"
        static let todayReviewedCount = "todayReviewedCount"
        static let totalXP = "totalXP"
    }

    /// Quality of recall (0-5)
    /// 5 = perfect, 4 = correct with hesitation, 3 = correct with difficulty
    /// 2 = incorrect, easy to recall, 1 = incorrect, hard, 0 = blackout
    enum Quality: Int, CaseIterable {
        case blackout = 0
        case incorrect_hard = 1
        case incorrect_easy = 2
        case correct_difficult = 3
        case correct_hesitation = 4
        case perfect = 5

        var label: String {
            switch self {
            case .blackout: return "😵 Blackout"
            case .incorrect_hard: return "😓 Very Hard"
            case .incorrect_easy: return "🤔 Hard"
            case .correct_difficult: return "😅 Difficult"
            case .correct_hesitation: return "🙂 Good"
            case .perfect: return "🎯 Perfect"
            }
        }

        var color: String {
            switch self {
            case .blackout, .incorrect_hard: return "red"
            case .incorrect_easy: return "orange"
            case .correct_difficult: return "yellow"
            case .correct_hesitation: return "blue"
            case .perfect: return "green"
            }
        }

        /// Simple mapping from correct/incorrect for quiz
        static func fromQuizResult(isCorrect: Bool, wasEasy: Bool = false) -> Quality {
            if isCorrect {
                return wasEasy ? .perfect : .correct_hesitation
            } else {
                return .incorrect_easy
            }
        }
    }

    /// Calculate next review date using SM-2
    /// Returns (nextInterval in days, new easeFactor, new repetition count)
    static func calculateNextReview(
        quality: Quality,
        currentInterval: Int,    // days since last review
        currentEaseFactor: Double,
        repetitionCount: Int
    ) -> (nextInterval: Int, easeFactor: Double, repetitions: Int) {

        let q = quality.rawValue
        var newEF = currentEaseFactor + (0.1 - Double(5 - q) * (0.08 + Double(5 - q) * 0.02))
        newEF = max(1.3, newEF) // minimum ease factor

        let newReps: Int
        let newInterval: Int

        if q < 3 {
            // Incorrect → reset
            newReps = 0
            newInterval = 1
        } else {
            newReps = repetitionCount + 1
            switch repetitionCount {
            case 0:
                newInterval = 1
            case 1:
                newInterval = 6
            default:
                newInterval = Int(Double(currentInterval) * newEF)
            }
        }

        return (max(1, newInterval), newEF, newReps)
    }

    /// Apply SRS update to a Vocabulary object
    static func applyReview(to vocab: Vocabulary, quality: Quality) {
        normalizeWordAges(for: [vocab])
        let now = Date()
        let currentInterval = vocab.srsInterval
        let currentEF = vocab.srsEaseFactor
        let currentReps = vocab.srsRepetitions

        let (nextInterval, newEF, newReps) = calculateNextReview(
            quality: quality,
            currentInterval: currentInterval,
            currentEaseFactor: currentEF,
            repetitionCount: currentReps
        )

        vocab.srsInterval = nextInterval
        vocab.srsEaseFactor = newEF
        vocab.srsRepetitions = newReps
        vocab.srsNextReview = Calendar.current.date(byAdding: .day, value: nextInterval, to: now) ?? now
        vocab.lastReviewedAt = now
        vocab.timesReviewed += 1

        if quality.rawValue >= 3 {
            vocab.timesCorrect += 1
            vocab.consecutiveFailures = 0
        } else {
            vocab.failedReviewCount += 1
            vocab.consecutiveFailures += 1
            vocab.lastFailedAt = now
            recordFailureDate(for: vocab, now: now)
        }

        // Mark as learned after 5 successful repetitions
        vocab.isLearned = newReps >= 5
        vocab.lastQuizCorrect = quality.rawValue >= 3
        vocab.wordStatusValue = LearningStatusHelper.statusAfterReview(
            for: vocab,
            isCorrect: quality.rawValue >= 3,
            quality: quality.rawValue,
            now: now
        )
        vocab.lastStatusChangedAt = now
        updateLearningProgress(quality: quality, now: now)
    }

    /// Cards due for review today
    static func dueCards(from vocabulary: [Vocabulary]) -> [Vocabulary] {
        normalizeWordAges(for: vocabulary)
        let now = Date()
        return vocabulary.filter { vocab in
            guard let nextReview = vocab.srsNextReview else { return true }
            return nextReview <= now
        }.sorted { a, b in
            reviewPriority(for: a, now: now) > reviewPriority(for: b, now: now)
        }
    }

    static func normalizeWordAges(for vocabulary: [Vocabulary], now: Date = Date()) {
        for vocab in vocabulary {
            let normalized = LearningStatusHelper.normalizedStatus(for: vocab, now: now)
            if normalized != vocab.wordStatusValue {
                vocab.wordStatusValue = normalized
                vocab.lastStatusChangedAt = now
            }
        }
    }

    static func reviewPriority(for vocabulary: Vocabulary, now: Date = Date()) -> Int {
        LearningStatusHelper.reviewPriority(for: vocabulary, now: now)
    }

    /// Difficulty label based on ease factor
    static func difficultyLabel(easeFactor: Double) -> String {
        switch easeFactor {
        case ..<1.5: return "🔴 Very Hard"
        case 1.5..<2.0: return "🟠 Hard"
        case 2.0..<2.5: return "🟡 Medium"
        case 2.5..<3.0: return "🟢 Easy"
        default: return "⭐ Very Easy"
        }
    }

    private static func recordFailureDate(for vocab: Vocabulary, now: Date) {
        let formatter = ISO8601DateFormatter()
        var entries = vocab.recentFailureDates
            .split(separator: ",")
            .map(String.init)
            .filter { !$0.isEmpty }

        entries.append(formatter.string(from: now))
        if entries.count > 10 {
            entries = Array(entries.suffix(10))
        }
        vocab.recentFailureDates = entries.joined(separator: ",")
    }

    private static func updateLearningProgress(quality: Quality, now: Date) {
        let defaults = UserDefaults.standard
        let calendar = Calendar.current
        let todayStart = calendar.startOfDay(for: now)

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let todayKey = formatter.string(from: todayStart)
        let previousDay = formatter.string(from: calendar.date(byAdding: .day, value: -1, to: todayStart) ?? todayStart)

        let lastStudyDate = defaults.string(forKey: ProgressKeys.lastStudyDate) ?? ""
        var streak = defaults.integer(forKey: ProgressKeys.currentStreak)
        var todayReviewedCount = defaults.integer(forKey: ProgressKeys.todayReviewedCount)
        var totalXP = defaults.integer(forKey: ProgressKeys.totalXP)

        if lastStudyDate != todayKey {
            todayReviewedCount = 0
            if lastStudyDate == previousDay {
                streak = max(streak, 1) + 1
            } else {
                streak = 1
            }
        }

        todayReviewedCount += 1
        totalXP += quality.rawValue >= 3 ? 10 : 4

        defaults.set(todayReviewedCount, forKey: ProgressKeys.todayReviewedCount)
        defaults.set(todayKey, forKey: ProgressKeys.lastStudyDate)
        defaults.set(streak, forKey: ProgressKeys.currentStreak)
        defaults.set(totalXP, forKey: ProgressKeys.totalXP)
    }
}

