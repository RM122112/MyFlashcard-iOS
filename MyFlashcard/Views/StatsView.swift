import SwiftUI
import SwiftData
import Charts

/// Lernstatistiken Dashboard mit Swift Charts
struct StatsView: View {
    @Query private var vocabulary: [Vocabulary]
    @AppStorage("dailyGoal") private var dailyGoal = 10
    @AppStorage("currentStreak") private var currentStreak = 0
    @AppStorage("lastStudyDate") private var lastStudyDateStr = ""
    @AppStorage("todayReviewedCount") private var todayReviewedCount = 0
    @AppStorage("totalXP") private var totalXP = 0

    private var calendar: Calendar { Calendar.current }

    private var weekReviewedCount: Int {
        weeklyData.map(\.count).reduce(0, +)
    }

    // MARK: - Computed Stats
    private var learnedCount: Int { vocabulary.filter { $0.isLearned }.count }
    private var totalCount: Int { vocabulary.count }

    private var dueCount: Int {
        SRSService.dueCards(from: vocabulary).count
    }

    private var statusCounts: [WordStatus: Int] {
        // Normalize word ages without mutation in computed property
        for vocab in vocabulary {
            let normalized = LearningStatusHelper.normalizedStatus(for: vocab)
            if normalized != vocab.wordStatusValue {
                vocab.wordStatusValue = normalized
            }
        }
        return Dictionary(uniqueKeysWithValues: WordStatus.allCases.map { status in
            (status, vocabulary.filter { LearningStatusHelper.normalizedStatus(for: $0) == status }.count)
        })
    }

    private var weakWords: [Vocabulary] {
        vocabulary
            .filter { $0.timesReviewed >= 3 }
            .sorted { ($0.accuracy) < ($1.accuracy) }
            .prefix(10)
            .map { $0 }
    }

    private var weeklyData: [DayStats] {
        (0..<7).map { offset in
            let date = calendar.date(byAdding: .day, value: -6 + offset, to: calendar.startOfDay(for: Date()))!
            let reviewed = vocabulary.filter { vocab in
                guard let last = vocab.lastReviewedAt else { return false }
                return calendar.isDate(last, inSameDayAs: date)
            }.count
            return DayStats(date: date, count: reviewed)
        }
    }

    private var accuracyByCategory: [String: Double] {
        let nouns = vocabulary.filter { $0.tags.contains("noun") }
        let verbs = vocabulary.filter { $0.tags.contains("verb") }
        // Group by CEFR level
        var result: [String: Double] = [:]
        for level in ["A1","A2","B1","B2","C1","C2"] {
            let group = vocabulary.filter { $0.cefrLevel == level && $0.timesReviewed > 0 }
            if !group.isEmpty {
                let avg = Double(group.map { $0.accuracy }.reduce(0, +)) / Double(group.count)
                result[level] = avg
            }
        }
        if result.isEmpty {
            // Fallback: Accuracy buckets
            let _ = nouns; let _ = verbs
            result = [
                "Bekannt": learnedCount > 0 ? 100.0 : 0,
                "In Bearbeitung": Double(vocabulary.filter { $0.timesReviewed > 0 && !$0.isLearned }.count),
                "Neu": Double(vocabulary.filter { $0.timesReviewed == 0 }.count)
            ]
        }
        return result
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Top Overview
                    overviewCards

                    // Streak & Daily Goal
                    streakSection

                    // Weekly Chart
                    weeklyChartSection

                    // XP & Weekly Goal
                    xpSection

                    // Weak Words
                    weakWordsSection

                    // SRS Overview
                    srsOverviewSection

                    // Accuracy Trend
                    accuracyTrendSection

                    // Retention Curve
                    retentionCurveSection

                    // Learning Velocity
                    velocitySection

                    // Word Buckets
                    wordBucketSection
                }
                .padding()
            }
            .navigationTitle("📊 Lernstatistiken")
            .onAppear { syncDailyReviewCounter() }
        }
    }

    // MARK: - Overview Cards
    private var overviewCards: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            statCard(title: "Gesamt", value: "\(totalCount)", icon: "textformat.abc", color: .blue)
            statCard(title: "Bekannt", value: "\(learnedCount)", icon: "checkmark.seal.fill", color: .green)
            statCard(title: "Heute fällig", value: "\(dueCount)", icon: "calendar.badge.clock", color: .orange)
            statCard(title: "XP", value: "\(totalXP)", icon: "star.fill", color: .purple)
        }
    }

    private func statCard(title: String, value: String, icon: String, color: Color) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            Text(value)
                .font(.title).bold()
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(16)
    }

    // MARK: - Streak
    private var streakSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("🔥 Streak & Tagesziel")
                .font(.headline)

            HStack(spacing: 16) {
                VStack(spacing: 4) {
                    Text("\(currentStreak)")
                        .font(.system(size: 48, weight: .bold))
                        .foregroundColor(.orange)
                    Text("Tage in Folge")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)

                Divider().frame(height: 60)

                VStack(spacing: 8) {
                    Text("Tagesziel: \(dailyGoal) Karten")
                        .font(.subheadline)
                    ProgressView(value: Double(min(todayReviewedCount, dailyGoal)), total: Double(dailyGoal))
                        .tint(.green)
                    Text("\(todayReviewedCount) / \(dailyGoal) heute")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Stepper("Ziel: \(dailyGoal)", value: $dailyGoal, in: 5...50, step: 5)
                        .font(.caption)
                }
                .frame(maxWidth: .infinity)
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .cornerRadius(16)
        }
    }

    // MARK: - Weekly Chart
    private var weeklyChartSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("📅 Letzte 7 Tage")
                .font(.headline)

            Chart(weeklyData) { day in
                BarMark(
                    x: .value("Tag", day.dayLabel),
                    y: .value("Karten", day.count)
                )
                .foregroundStyle(day.count >= dailyGoal ? Color.green : Color.blue)
                .annotation(position: .top) {
                    if day.count > 0 {
                        Text("\(day.count)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading)
            }
            .frame(height: 180)
            .padding()
            .background(Color(.secondarySystemBackground))
            .cornerRadius(16)

            HStack {
                Circle().fill(.green).frame(width: 10, height: 10)
                Text("Ziel erreicht")
                Circle().fill(.blue).frame(width: 10, height: 10)
                Text("Unter dem Ziel")
            }
            .font(.caption)
            .foregroundColor(.secondary)
        }
    }

    private var xpSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("⭐ Lernfortschritt")
                .font(.headline)

            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("Heute wiederholt")
                    Spacer()
                    Text("\(todayReviewedCount)")
                        .fontWeight(.semibold)
                }

                HStack {
                    Text("Diese Woche")
                    Spacer()
                    Text("\(weekReviewedCount) Karten")
                        .fontWeight(.semibold)
                }

                let weeklyGoal = dailyGoal * 7
                ProgressView(value: Double(min(weekReviewedCount, weeklyGoal)), total: Double(max(weeklyGoal, 1)))
                    .tint(.purple)

                Text("Wochenziel: \(weekReviewedCount) / \(weeklyGoal)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .cornerRadius(16)
        }
    }

    // MARK: - Weak Words
    private var weakWordsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("⚠️ Schwierige Wörter (Top 10)")
                .font(.headline)

            if weakWords.isEmpty {
                Text("Wiederhole mehr Wörter, um hier deine Lernschwerpunkte zu sehen.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(12)
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(weakWords.enumerated()), id: \.element.id) { idx, vocab in
                        HStack {
                            Text("\(idx + 1).")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .frame(width: 24)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(vocab.englishWord)
                                    .font(.subheadline).bold()
                                Text(vocab.german)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            VStack(alignment: .trailing, spacing: 2) {
                                Text("\(vocab.accuracy)%")
                                    .font(.subheadline).bold()
                                    .foregroundColor(vocab.accuracy < 50 ? .red : .orange)
                                Text("\(vocab.timesCorrect)/\(vocab.timesReviewed)")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                        if idx < weakWords.count - 1 {
                            Divider().padding(.leading, 48)
                        }
                    }
                }
                .background(Color(.secondarySystemBackground))
                .cornerRadius(16)
            }
        }
    }

    // MARK: - SRS Overview
    private var srsOverviewSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("🧠 SRS-Plan")
                .font(.headline)

            let upcoming = upcomingReviewData()

            if upcoming.isEmpty {
                Text("Aktuell sind noch keine weiteren Wiederholungen eingeplant.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(12)
            } else {
                Chart(upcoming) { item in
                    BarMark(
                        x: .value("Day", item.label),
                        y: .value("Cards", item.count)
                    )
                    .foregroundStyle(Color.orange)
                }
                .frame(height: 150)
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(16)
            }
        }
    }

    private var wordBucketSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("🗂️ Wortbereiche")
                .font(.headline)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                statCard(title: "Neue Wörter", value: "\(statusCounts[.newWord] ?? 0)", icon: "sparkles", color: .blue)
                statCard(title: "Alte Wörter", value: "\(statusCounts[.oldWord] ?? 0)", icon: "clock.arrow.circlepath", color: .purple)
                statCard(title: "Bekannte Wörter", value: "\(statusCounts[.knownWord] ?? 0)", icon: "checkmark.circle.fill", color: .green)
                statCard(title: "Unbekannte Wörter", value: "\(statusCounts[.unknownWord] ?? 0)", icon: "exclamationmark.triangle.fill", color: .red)
            }

            Text("Neue Wörter wechseln nach 30 Tagen automatisch in den Bereich ‚Alte Wörter‘. Falsch beantwortete Wörter bleiben stärker im Fokus und werden bei Wiederholungen priorisiert.")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    // MARK: - Helpers
    private func upcomingReviewData() -> [LabeledCount] {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        return (0..<7).compactMap { offset -> LabeledCount? in
            let day = cal.date(byAdding: .day, value: offset, to: today)!
            let count = vocabulary.filter { vocab in
                guard let next = vocab.srsNextReview else { return offset == 0 }
                return cal.startOfDay(for: next) == day
            }.count
            guard count > 0 else { return nil }
            let f = DateFormatter(); f.dateFormat = offset == 0 ? "'Heute'" : "EEE"
            return LabeledCount(label: f.string(from: day), count: count)
        }
    }

    // MARK: - Accuracy Trend
    private var accuracyTrendSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("📈 Genauigkeitstrend (7 Tage)")
                .font(.headline)

            let trend = LearningAnalyticsService.accuracyTrend(for: vocabulary)
            if trend.allSatisfy({ $0.reviewCount == 0 }) {
                Text("Noch keine Daten für den Trend vorhanden.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(12)
            } else {
                Chart(trend) { day in
                    LineMark(
                        x: .value("Tag", day.date, unit: .day),
                        y: .value("Genauigkeit", day.accuracy)
                    )
                    .foregroundStyle(Color.green)
                    .interpolationMethod(.catmullRom)
                    PointMark(
                        x: .value("Tag", day.date, unit: .day),
                        y: .value("Genauigkeit", day.accuracy)
                    )
                    .foregroundStyle(Color.green)
                }
                .chartYScale(domain: 0...100)
                .chartYAxis {
                    AxisMarks(values: [0, 25, 50, 75, 100]) { value in
                        AxisValueLabel { Text("\(value.as(Int.self) ?? 0)%") }
                        AxisGridLine()
                    }
                }
                .frame(height: 160)
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(16)
            }
        }
    }

    // MARK: - Retention Curve
    private var retentionCurveSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("🧠 Vergessenskurve")
                .font(.headline)

            let curve = LearningAnalyticsService.retentionCurve(for: vocabulary)
            Chart(curve) { bucket in
                BarMark(
                    x: .value("Intervall", bucket.label),
                    y: .value("Behalten", bucket.retentionRate)
                )
                .foregroundStyle(bucket.retentionRate >= 80 ? Color.green : bucket.retentionRate >= 50 ? Color.orange : Color.red)
                .annotation(position: .top) {
                    if bucket.retentionRate > 0 {
                        Text("\(Int(bucket.retentionRate))%")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .chartYScale(domain: 0...100)
            .frame(height: 160)
            .padding()
            .background(Color(.secondarySystemBackground))
            .cornerRadius(16)

            Text("Zeigt, wie gut du Wörter nach verschiedenen Zeitintervallen behältst.")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    // MARK: - Learning Velocity
    private var velocitySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("🚀 Lerngeschwindigkeit")
                .font(.headline)

            let vel = LearningAnalyticsService.velocity(for: vocabulary)
            let bestHour = LearningAnalyticsService.bestLearningHour(for: vocabulary)

            VStack(spacing: 12) {
                HStack {
                    VStack(spacing: 4) {
                        Text(String(format: "%.1f", vel.wordsPerDay))
                            .font(.system(size: 36, weight: .bold))
                            .foregroundColor(.blue)
                        Text("Wörter/Tag")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)

                    Divider().frame(height: 50)

                    VStack(spacing: 4) {
                        Text("\(vel.masteredCount)/\(vel.totalCount)")
                            .font(.system(size: 36, weight: .bold))
                            .foregroundColor(.green)
                        Text("Gemeistert")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                }

                if vel.estimatedDaysToMaster > 0 {
                    HStack {
                        Image(systemName: "calendar.badge.clock")
                            .foregroundColor(.orange)
                        Text("Geschätzt ~\(vel.estimatedDaysToMaster) Tage bis alle Wörter gemeistert")
                            .font(.subheadline)
                        Spacer()
                    }
                }

                if let hour = bestHour {
                    HStack {
                        Image(systemName: "clock.fill")
                            .foregroundColor(.purple)
                        Text("Beste Lernzeit: \(hour):00 Uhr")
                            .font(.subheadline)
                        Spacer()
                    }
                }
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .cornerRadius(16)
        }
    }

    private func syncDailyReviewCounter() {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let today = formatter.string(from: calendar.startOfDay(for: Date()))
        if lastStudyDateStr != today {
            todayReviewedCount = 0
        }
    }
}

struct DayStats: Identifiable {
    let id = UUID()
    let date: Date
    let count: Int
    var dayLabel: String {
        let f = DateFormatter(); f.dateFormat = "EEE"
        return f.string(from: date)
    }
}

struct LabeledCount: Identifiable {
    let id = UUID()
    let label: String
    let count: Int
}

