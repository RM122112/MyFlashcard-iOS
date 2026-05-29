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

    private var calendar: Calendar { Calendar.current }

    // MARK: - Computed Stats
    private var learnedCount: Int { vocabulary.filter { $0.isLearned }.count }
    private var totalCount: Int { vocabulary.count }

    private var dueCount: Int {
        SRSService.dueCards(from: vocabulary).count
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
                "Learned": learnedCount > 0 ? 100.0 : 0,
                "In Progress": Double(vocabulary.filter { $0.timesReviewed > 0 && !$0.isLearned }.count),
                "New": Double(vocabulary.filter { $0.timesReviewed == 0 }.count)
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

                    // Weak Words
                    weakWordsSection

                    // SRS Overview
                    srsOverviewSection
                }
                .padding()
            }
            .navigationTitle("📊 Statistics")
        }
    }

    // MARK: - Overview Cards
    private var overviewCards: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            statCard(title: "Total Words", value: "\(totalCount)", icon: "textformat.abc", color: .blue)
            statCard(title: "Learned", value: "\(learnedCount)", icon: "checkmark.seal.fill", color: .green)
            statCard(title: "Due Today", value: "\(dueCount)", icon: "calendar.badge.clock", color: .orange)
            statCard(title: "Today Reviewed", value: "\(todayReviewedCount)", icon: "brain.head.profile", color: .purple)
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
            Text("🔥 Streak & Goals")
                .font(.headline)

            HStack(spacing: 16) {
                VStack(spacing: 4) {
                    Text("\(currentStreak)")
                        .font(.system(size: 48, weight: .bold))
                        .foregroundColor(.orange)
                    Text("Day Streak")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)

                Divider().frame(height: 60)

                VStack(spacing: 8) {
                    Text("Daily Goal: \(dailyGoal) cards")
                        .font(.subheadline)
                    ProgressView(value: Double(min(todayReviewedCount, dailyGoal)), total: Double(dailyGoal))
                        .tint(.green)
                    Text("\(todayReviewedCount) / \(dailyGoal) today")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Stepper("Goal: \(dailyGoal)", value: $dailyGoal, in: 5...50, step: 5)
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
            Text("📅 Last 7 Days")
                .font(.headline)

            Chart(weeklyData) { day in
                BarMark(
                    x: .value("Day", day.dayLabel),
                    y: .value("Cards", day.count)
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
                Text("Goal reached")
                Circle().fill(.blue).frame(width: 10, height: 10)
                Text("Below goal")
            }
            .font(.caption)
            .foregroundColor(.secondary)
        }
    }

    // MARK: - Weak Words
    private var weakWordsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("⚠️ Problematic Words (Top 10)")
                .font(.headline)

            if weakWords.isEmpty {
                Text("Review more words to see your weak spots!")
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
            Text("🧠 SRS Schedule")
                .font(.headline)

            let upcoming = upcomingReviewData()

            if upcoming.isEmpty {
                Text("No upcoming reviews scheduled yet.")
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
            let f = DateFormatter(); f.dateFormat = offset == 0 ? "'Today'" : "EEE"
            return LabeledCount(label: f.string(from: day), count: count)
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

