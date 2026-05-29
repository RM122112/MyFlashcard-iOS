import SwiftUI
import SwiftData

struct BrowseView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Vocabulary.createdAt, order: .reverse) private var vocabulary: [Vocabulary]
    @StateObject private var speechService = SpeechService.shared
    
    @State private var searchText = ""
    
    var filteredVocabulary: [Vocabulary] {
        if searchText.isEmpty {
            return vocabulary
        }
        return vocabulary.filter {
            $0.englishWord.localizedCaseInsensitiveContains(searchText) ||
            $0.german.localizedCaseInsensitiveContains(searchText) ||
            $0.persian.contains(searchText)
        }
    }
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(filteredVocabulary) { vocab in
                    VocabularyRow(vocab: vocab, speechService: speechService)
                }
                .onDelete(perform: deleteItems)
            }
            .navigationTitle("📚 Vocabulary (\(vocabulary.count))")
            .searchable(text: $searchText, prompt: "Search...")
            .overlay {
                if vocabulary.isEmpty {
                    ContentUnavailableView(
                        "No Vocabulary",
                        systemImage: "book.closed",
                        description: Text("Add some words to get started!")
                    )
                }
            }
        }
    }
    
    private func deleteItems(offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(filteredVocabulary[index])
        }
    }
}

struct VocabularyRow: View {
    let vocab: Vocabulary
    @ObservedObject var speechService: SpeechService
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header with English word and speaker button
            HStack {
                Text(vocab.englishWord)
                    .font(.headline)
                
                // Speaker button - using Button with explicit action
                Button {
                    speechService.speak(vocab.englishWord)
                } label: {
                    Image(systemName: speechService.isSpeaking ? "speaker.wave.3.fill" : "speaker.wave.2.fill")
                        .foregroundColor(.blue)
                        .font(.title3)
                }
                .buttonStyle(.borderless) // Important: prevents row tap interference
                
                Spacer()
                
                // Expand/collapse indicator
                Button {
                    withAnimation { isExpanded.toggle() }
                } label: {
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.borderless)
            }
            
            // Translations
            HStack {
                Text("🇩🇪 \(vocab.german)")
                    .font(.subheadline)
                Spacer()
                Text("🇮🇷 \(vocab.persian)")
                    .font(.subheadline)
                    .environment(\.layoutDirection, .rightToLeft)
            }
            
            // Expanded content
            if isExpanded && !vocab.exampleSentence.isEmpty {
                Divider()
                
                HStack {
                    Text("📝 \(vocab.exampleSentence)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Button {
                        speechService.speak(vocab.exampleSentence)
                    } label: {
                        Image(systemName: "speaker.wave.2")
                            .foregroundColor(.blue)
                    }
                    .buttonStyle(.borderless)
                }
                
                if vocab.timesReviewed > 0 {
                    HStack {
                        Image(systemName: vocab.isLearned ? "checkmark.circle.fill" : "clock")
                            .foregroundColor(vocab.isLearned ? .green : .orange)
                        Text("Reviewed: \(vocab.timesReviewed)x | Correct: \(vocab.timesCorrect)x")
                            .font(.caption2)
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
}
