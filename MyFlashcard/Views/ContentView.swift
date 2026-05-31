import SwiftUI
import SwiftData

/// Main Content View with Tab Navigation (7 Tabs)
struct ContentView: View {
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        TabView {
            BrowseView()
                .tabItem {
                    Label("Wörter", systemImage: "list.bullet")
                }

            InputView()
                .tabItem {
                    Label("Hinzufügen", systemImage: "plus.circle")
                }

            FlashcardView()
                .tabItem {
                    Label("Karten", systemImage: "rectangle.stack")
                }

            QuizHubView()
                .tabItem {
                    Label("Quiz", systemImage: "questionmark.circle")
                }

            AIChatView()
                .tabItem {
                    Label("KI-Chat", systemImage: "sparkles")
                }

            GrammarView()
                .tabItem {
                    Label("Grammatik", systemImage: "book")
                }

            StatsView()
                .tabItem {
                    Label("Statistik", systemImage: "chart.bar.fill")
                }
        }
        .onAppear {
            DataService.shared.initializeSampleDataIfNeeded(modelContext: modelContext)
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Vocabulary.self, Synonym.self], inMemory: true)
}
