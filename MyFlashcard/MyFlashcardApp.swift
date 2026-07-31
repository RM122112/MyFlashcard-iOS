import SwiftUI
import SwiftData

@main
struct MyFlashcardApp: App {

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Vocabulary.self,
            Synonym.self,
            LearningProgress.self      // Phase 1: XP/Streak persistent in SwiftData
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            // Fallback auf In-Memory verhindert App-Absturz bei einem schwerwiegenden Schemafehler.
            // Der Nutzer verliert keine dauerhaften Daten – sein Store auf Disk ist noch vorhanden.
            // TODO: Im nächsten Release einen Fehlerdialog mit "Daten zurücksetzen?" anzeigen.
            print("[MyFlashcardApp] Persistenter Store nicht ladbar: \(error)")
            let fallback = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
            do {
                return try ModelContainer(for: schema, configurations: [fallback])
            } catch {
                fatalError("ModelContainer konnte weder persistent noch in-memory erstellt werden: \(error)")
            }
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .task {
                    // Einmalige Migration von UserDefaults → SwiftData beim ersten Start
                    await MainActor.run {
                        LearningProgressService.shared.migrateFromUserDefaultsIfNeeded(
                            modelContext: sharedModelContainer.mainContext
                        )
                    }
                }
        }
        .modelContainer(sharedModelContainer)
    }
}
