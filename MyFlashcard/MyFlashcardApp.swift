import SwiftUI
import SwiftData

@main
struct MyFlashcardApp: App {
    init() {
        let fallbackSecret = (Bundle.main.object(forInfoDictionaryKey: "AI_PROXY_SECRET") as? String)
            ?? ProcessInfo.processInfo.environment["AI_PROXY_SECRET"]
        KeychainService.shared.bootstrapIfNeeded(key: .proxyAI, fallbackSecret: fallbackSecret)
    }

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Vocabulary.self,
            Synonym.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            // Fallback avoids startup crash when a local store can't be migrated.
            // User can still use the app and data layer in-memory.
            print("SwiftData persistent load failed: \(error)")
            let fallbackConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
            do {
                return try ModelContainer(for: schema, configurations: [fallbackConfiguration])
            } catch {
                fatalError("Could not create fallback ModelContainer: \(error)")
            }
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
