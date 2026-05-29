import SwiftUI
import SwiftData

/// Main Content View with Tab Navigation (7 Tabs)
struct ContentView: View {
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        TabView {
            BrowseView()
                .tabItem {
                    Label("Browse", systemImage: "list.bullet")
                }

            InputView()
                .tabItem {
                    Label("Add", systemImage: "plus.circle")
                }

            FlashcardView()
                .tabItem {
                    Label("Cards", systemImage: "rectangle.stack")
                }

            QuizHubView()
                .tabItem {
                    Label("Quiz", systemImage: "questionmark.circle")
                }

            AIChatView()
                .tabItem {
                    Label("AI Chat", systemImage: "sparkles")
                }

            GrammarView()
                .tabItem {
                    Label("Grammar", systemImage: "book")
                }

            StatsView()
                .tabItem {
                    Label("Stats", systemImage: "chart.bar.fill")
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
