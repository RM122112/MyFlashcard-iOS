import Foundation
import SwiftData

// MARK: - LearningProgress

/// Persistenter Lernfortschrittseintrag.
///
/// Speichert täglich einen Snapshot des Lernfortschritts:
/// XP, Streak, Anzahl der Reviews und Lernzeit.
///
/// **Warum SwiftData statt UserDefaults?**
/// - UserDefaults ist nicht synchronisierbar (kein iCloud/Backend-Sync).
/// - SwiftData ermöglicht historische Abfragen (Wochenstatistiken etc.).
/// - Alle Lerndaten befinden sich an einem Ort.
/// - Zukünftige Cloud-Synchronisation wird dadurch erheblich vereinfacht.
///
/// **Migration:** Beim ersten Start werden vorhandene UserDefaults-Werte
/// einmalig in dieses Modell importiert.
@Model
final class LearningProgress {

    // MARK: - Stored Properties

    /// Eindeutige ID des Eintrags.
    var id: UUID = UUID()

    /// Datum, auf das sich dieser Eintrag bezieht (normalisiert auf Tagesbeginn).
    var date: Date = Date()

    /// Anzahl heute durchgeführter Reviews.
    var reviewsToday: Int = 0

    /// Tages-XP (nur für diesen Tag gezählt).
    var xpToday: Int = 0

    /// Gesamt-XP über alle Tage.
    var totalXP: Int = 0

    /// Aktueller Streak in Tagen.
    var currentStreak: Int = 0

    /// Längster jemals erreichter Streak.
    var longestStreak: Int = 0

    /// Tägliches Lernziel (Anzahl Reviews).
    var dailyGoal: Int = 10

    /// Lernzeit heute in Sekunden.
    var studyTimeSecondsToday: Int = 0

    /// Gesamte Lernzeit in Sekunden.
    var totalStudyTimeSeconds: Int = 0

    // MARK: - Init

    init(
        date: Date = Calendar.current.startOfDay(for: Date()),
        reviewsToday: Int = 0,
        xpToday: Int = 0,
        totalXP: Int = 0,
        currentStreak: Int = 0,
        longestStreak: Int = 0,
        dailyGoal: Int = 10,
        studyTimeSecondsToday: Int = 0,
        totalStudyTimeSeconds: Int = 0
    ) {
        self.id = UUID()
        self.date = date
        self.reviewsToday = reviewsToday
        self.xpToday = xpToday
        self.totalXP = totalXP
        self.currentStreak = currentStreak
        self.longestStreak = longestStreak
        self.dailyGoal = dailyGoal
        self.studyTimeSecondsToday = studyTimeSecondsToday
        self.totalStudyTimeSeconds = totalStudyTimeSeconds
    }

    // MARK: - Computed

    /// Gibt an, ob das Tagesziel heute bereits erreicht wurde.
    var isDailyGoalReached: Bool {
        reviewsToday >= dailyGoal
    }

    /// Fortschritt zum Tagesziel (0.0 – 1.0).
    var dailyGoalProgress: Double {
        guard dailyGoal > 0 else { return 0 }
        return min(Double(reviewsToday) / Double(dailyGoal), 1.0)
    }
}

// MARK: - LearningProgressService

/// Verwaltung und Persistenz des täglichen Lernfortschritts.
///
/// - Hält immer genau einen Eintrag pro Tag in SwiftData.
/// - Importiert beim ersten Aufruf einmalig legacy UserDefaults-Werte.
@MainActor
final class LearningProgressService {

    static let shared = LearningProgressService()

    // MARK: - UserDefaults Legacy Keys (für einmalige Migration)

    private enum LegacyKeys {
        static let currentStreak      = "currentStreak"
        static let lastStudyDate      = "lastStudyDate"
        static let todayReviewedCount = "todayReviewedCount"
        static let totalXP            = "totalXP"
        static let longestStreak      = "longestStreak"
        static let dailyGoal          = "srs_daily_goal"
    }

    // MARK: - Migration

    /// Migriert einmalig vorhandene UserDefaults-Werte nach SwiftData.
    /// Wird beim App-Start aufgerufen und danach nicht mehr ausgeführt.
    func migrateFromUserDefaultsIfNeeded(modelContext: ModelContext) {
        let defaults = UserDefaults.standard
        let migrationKey = "learningProgress.migrated.v1"
        guard !defaults.bool(forKey: migrationKey) else { return }

        let legacyStreak    = defaults.integer(forKey: LegacyKeys.currentStreak)
        let legacyTotalXP   = defaults.integer(forKey: LegacyKeys.totalXP)
        let legacyGoal      = defaults.integer(forKey: LegacyKeys.dailyGoal)
        let legacyLongest   = defaults.integer(forKey: LegacyKeys.longestStreak)
        let legacyReviews   = defaults.integer(forKey: LegacyKeys.todayReviewedCount)

        let today = Calendar.current.startOfDay(for: Date())
        let progress = LearningProgress(
            date: today,
            reviewsToday: legacyReviews,
            xpToday: 0,
            totalXP: legacyTotalXP,
            currentStreak: legacyStreak,
            longestStreak: max(legacyStreak, legacyLongest),
            dailyGoal: legacyGoal > 0 ? legacyGoal : 10
        )
        modelContext.insert(progress)

        do {
            try modelContext.save()
            defaults.set(true, forKey: migrationKey)
        } catch {
            print("[LearningProgressService] Migration fehlgeschlagen: \(error.localizedDescription)")
        }
    }

    // MARK: - Today's Entry

    /// Gibt den heutigen Fortschrittseintrag zurück oder erstellt ihn neu.
    func todayProgress(modelContext: ModelContext) -> LearningProgress {
        let today = Calendar.current.startOfDay(for: Date())
        var descriptor = FetchDescriptor<LearningProgress>(
            predicate: #Predicate { $0.date == today }
        )
        descriptor.fetchLimit = 1

        if let existing = (try? modelContext.fetch(descriptor))?.first {
            return existing
        }

        // Neuen Tageseintrag erstellen, Streak vom Vortag übernehmen
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: today)!
        var yesterdayDescriptor = FetchDescriptor<LearningProgress>(
            predicate: #Predicate { $0.date == yesterday }
        )
        yesterdayDescriptor.fetchLimit = 1

        let previousStreak  = (try? modelContext.fetch(yesterdayDescriptor))?.first?.currentStreak ?? 0
        let previousLongest = (try? modelContext.fetch(yesterdayDescriptor))?.first?.longestStreak ?? 0
        let previousGoal    = (try? modelContext.fetch(yesterdayDescriptor))?.first?.dailyGoal ?? 10
        let previousTotalXP = (try? modelContext.fetch(yesterdayDescriptor))?.first?.totalXP ?? 0

        // Wenn gestern kein Review gemacht wurde, Streak auf 0 zurücksetzen
        let hadYesterdayActivity = (try? modelContext.fetch(yesterdayDescriptor))?.first?.reviewsToday ?? 0 > 0
        let newStreak = hadYesterdayActivity ? previousStreak : 0

        let newEntry = LearningProgress(
            date: today,
            reviewsToday: 0,
            xpToday: 0,
            totalXP: previousTotalXP,
            currentStreak: newStreak,
            longestStreak: previousLongest,
            dailyGoal: previousGoal
        )
        modelContext.insert(newEntry)
        return newEntry
    }

    // MARK: - Record Review

    /// Zeichnet ein abgeschlossenes Review auf und aktualisiert XP + Streak.
    ///
    /// - Parameters:
    ///   - xpGained: Gewonnene XP für dieses Review (abhängig von Qualität).
    ///   - modelContext: Aktiver SwiftData-Kontext.
    func recordReview(xpGained: Int, modelContext: ModelContext) {
        let progress = todayProgress(modelContext: modelContext)

        progress.reviewsToday      += 1
        progress.xpToday           += xpGained
        progress.totalXP           += xpGained

        // Streak: beim ersten Review des Tages erhöhen
        if progress.reviewsToday == 1 {
            progress.currentStreak += 1
            progress.longestStreak  = max(progress.longestStreak, progress.currentStreak)
        }

        do {
            try modelContext.save()
        } catch {
            print("[LearningProgressService] recordReview fehlgeschlagen: \(error.localizedDescription)")
        }
    }

    // MARK: - Daily Goal

    /// Aktualisiert das tägliche Lernziel im heutigen Fortschrittseintrag.
    func setDailyGoal(_ goal: Int, modelContext: ModelContext) {
        let normalizedGoal = min(max(goal, 1), 200)
        let progress = todayProgress(modelContext: modelContext)
        progress.dailyGoal = normalizedGoal

        do {
            try modelContext.save()
        } catch {
            print("[LearningProgressService] setDailyGoal fehlgeschlagen: \(error.localizedDescription)")
        }
    }

    // MARK: - History

    /// Gibt die letzten `days` Tage als sortierte Liste zurück (neueste zuerst).
    func recentHistory(days: Int = 30, modelContext: ModelContext) -> [LearningProgress] {
        let cutoff = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        var descriptor = FetchDescriptor<LearningProgress>(
            predicate: #Predicate { $0.date >= cutoff },
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        descriptor.fetchLimit = days
        return (try? modelContext.fetch(descriptor)) ?? []
    }
}
