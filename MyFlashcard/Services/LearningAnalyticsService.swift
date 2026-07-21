import Foundation

/// Erweiterte Lernfortschritt-Analyse auf Basis vorhandener SRS-Daten
struct LearningAnalyticsService {

    // MARK: - Accuracy Trend (letzte 7 Tage)

    struct DailyAccuracy: Identifiable {
        let id = UUID()
        let date: Date
        let accuracy: Double   // 0…100
        let reviewCount: Int
    }

    static func accuracyTrend(for vocabulary: [Vocabulary], days: Int = 7) -> [DailyAccuracy] {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        return (0..<days).map { offset in
            let day = cal.date(byAdding: .day, value: -days + 1 + offset, to: today)!
            let reviewed = vocabulary.filter { v in
                guard let last = v.lastReviewedAt else { return false }
                return cal.isDate(last, inSameDayAs: day)
            }
            let total = reviewed.reduce(0) { $0 + $1.timesReviewed }
            let correct = reviewed.reduce(0) { $0 + $1.timesCorrect }
            let acc = total > 0 ? Double(correct) / Double(total) * 100.0 : 0
            return DailyAccuracy(date: day, accuracy: acc, reviewCount: reviewed.count)
        }
    }

    // MARK: - Vergessenskurve

    struct RetentionBucket: Identifiable {
        let id = UUID()
        let label: String
        let intervalDays: Int
        let retentionRate: Double // 0…100
    }

    static func retentionCurve(for vocabulary: [Vocabulary]) -> [RetentionBucket] {
        let buckets: [(String, ClosedRange<Int>)] = [
            ("1d", 0...1), ("2-3d", 2...3), ("4-7d", 4...7),
            ("8-14d", 8...14), ("15-30d", 15...30), ("30d+", 31...365)
        ]
        return buckets.map { label, range in
            let group = vocabulary.filter { range.contains($0.srsInterval) && $0.timesReviewed > 0 }
            let rate = group.isEmpty ? 0.0 : Double(group.filter { $0.lastQuizCorrect == true }.count) / Double(group.count) * 100
            return RetentionBucket(label: label, intervalDays: range.lowerBound, retentionRate: rate)
        }
    }

    // MARK: - Lerngeschwindigkeit

    struct LearningVelocity {
        let wordsPerDay: Double
        let estimatedDaysToMaster: Int
        let masteredCount: Int
        let totalCount: Int
    }

    static func velocity(for vocabulary: [Vocabulary]) -> LearningVelocity {
        let mastered = vocabulary.filter { $0.isLearned }
        let cal = Calendar.current
        let dates = vocabulary.compactMap { $0.lastReviewedAt }.sorted()
        guard let first = dates.first else {
            return LearningVelocity(wordsPerDay: 0, estimatedDaysToMaster: 0, masteredCount: 0, totalCount: vocabulary.count)
        }
        let activeDays = max(1, cal.dateComponents([.day], from: first, to: Date()).day ?? 1)
        let perDay = Double(mastered.count) / Double(activeDays)
        let remaining = vocabulary.count - mastered.count
        let eta = perDay > 0 ? Int(Double(remaining) / perDay) : 0
        return LearningVelocity(wordsPerDay: perDay, estimatedDaysToMaster: eta, masteredCount: mastered.count, totalCount: vocabulary.count)
    }

    // MARK: - Schwächste Kategorien nach Tags

    struct TagWeakness: Identifiable {
        let id = UUID()
        let tag: String
        let accuracy: Int
        let count: Int
    }

    static func weakestTags(for vocabulary: [Vocabulary], limit: Int = 5) -> [TagWeakness] {
        var tagGroups: [String: [Vocabulary]] = [:]
        for v in vocabulary {
            for tag in v.tagList {
                tagGroups[tag, default: []].append(v)
            }
        }
        return tagGroups
            .filter { $0.value.contains(where: { $0.timesReviewed > 0 }) }
            .map { tag, words in
                let reviewed = words.filter { $0.timesReviewed > 0 }
                let avg = reviewed.isEmpty ? 0 : reviewed.map { $0.accuracy }.reduce(0, +) / reviewed.count
                return TagWeakness(tag: tag, accuracy: avg, count: reviewed.count)
            }
            .sorted { $0.accuracy < $1.accuracy }
            .prefix(limit)
            .map { $0 }
    }

    // MARK: - Optimale Lernzeit

    struct HourActivity: Identifiable {
        let id = UUID()
        let hour: Int
        let reviewCount: Int
        let accuracy: Double
    }

    static func activityByHour(for vocabulary: [Vocabulary]) -> [HourActivity] {
        let cal = Calendar.current
        var hourBuckets: [Int: (reviews: Int, correct: Int, total: Int)] = [:]
        for v in vocabulary {
            guard let date = v.lastReviewedAt else { continue }
            let hour = cal.component(.hour, from: date)
            var bucket = hourBuckets[hour, default: (0, 0, 0)]
            bucket.reviews += 1
            bucket.correct += v.timesCorrect
            bucket.total += v.timesReviewed
            hourBuckets[hour] = bucket
        }
        return hourBuckets
            .map { hour, data in
                let acc = data.total > 0 ? Double(data.correct) / Double(data.total) * 100 : 0
                return HourActivity(hour: hour, reviewCount: data.reviews, accuracy: acc)
            }
            .sorted { $0.hour < $1.hour }
    }

    static func bestLearningHour(for vocabulary: [Vocabulary]) -> Int? {
        activityByHour(for: vocabulary)
            .filter { $0.reviewCount >= 3 }
            .max(by: { $0.accuracy < $1.accuracy })?
            .hour
    }
}

