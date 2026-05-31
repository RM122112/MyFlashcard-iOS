import SwiftUI
import SwiftData

struct BrowseView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Vocabulary.createdAt, order: .reverse) private var vocabulary: [Vocabulary]
    @StateObject private var speechService = SpeechService.shared
    
    @State private var searchText = ""
    @State private var selectedStatus: WordStatus? = nil
    @State private var showDictionary = false

    private var normalizedVocabulary: [Vocabulary] {
        SRSService.normalizeWordAges(for: vocabulary)
        return vocabulary
    }

    private var statusCounts: [WordStatus: Int] {
        Dictionary(uniqueKeysWithValues: WordStatus.allCases.map { status in
            (status, normalizedVocabulary.filter { LearningStatusHelper.normalizedStatus(for: $0) == status }.count)
        })
    }

    var filteredVocabulary: [Vocabulary] {
        normalizedVocabulary.filter { vocab in
            let matchesSearch = searchText.isEmpty ||
                vocab.englishWord.localizedCaseInsensitiveContains(searchText) ||
                vocab.german.localizedCaseInsensitiveContains(searchText) ||
                vocab.persian.contains(searchText) ||
                vocab.exampleSentence.localizedCaseInsensitiveContains(searchText)
            let matchesStatus = selectedStatus == nil || LearningStatusHelper.normalizedStatus(for: vocab) == selectedStatus
            return matchesSearch && matchesStatus
        }
        .sorted { SRSService.reviewPriority(for: $0) > SRSService.reviewPriority(for: $1) }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        StatusChip(title: "Alle", count: normalizedVocabulary.count, isSelected: selectedStatus == nil) {
                            selectedStatus = nil
                        }
                        ForEach(WordStatus.allCases, id: \.self) { status in
                            StatusChip(title: status.title, count: statusCounts[status] ?? 0, isSelected: selectedStatus == status) {
                                selectedStatus = status
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)
                }

                List {
                    ForEach(filteredVocabulary) { vocab in
                        VocabularyRow(vocab: vocab, speechService: speechService)
                    }
                    .onDelete(perform: deleteItems)
                }
             }
            .navigationTitle("📚 Wortschatz (\(normalizedVocabulary.count))")
            .searchable(text: $searchText, prompt: "Wörter suchen …")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink(
                        destination: DictionaryDetailView(),
                        label: {
                            Image(systemName: "book.fill")
                                .foregroundColor(.blue)
                        }
                    )
                }
            }
            .overlay {
                if normalizedVocabulary.isEmpty {
                    ContentUnavailableView(
                        "Noch keine Wörter vorhanden",
                        systemImage: "book.closed",
                        description: Text("Füge die ersten Wörter hinzu, um mit dem Lernen zu beginnen.")
                    )
                } else if filteredVocabulary.isEmpty {
                    ContentUnavailableView(
                        "Keine passenden Wörter gefunden",
                        systemImage: "line.3.horizontal.decrease.circle",
                        description: Text("Passe Suche oder Filter an, um andere Wörter anzuzeigen.")
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

    private var status: WordStatus { LearningStatusHelper.normalizedStatus(for: vocab) }

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
                
                Label(status.title, systemImage: statusIcon)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(statusColor.opacity(0.12))
                    .foregroundColor(statusColor)
                    .clipShape(Capsule())

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
                Text("🇦🇫 \(vocab.persian)")
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
                        Text("Wiederholt: \(vocab.timesReviewed)x • Richtig: \(vocab.timesCorrect)x")
                            .font(.caption2)
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }

    private var statusIcon: String {
        switch status {
        case .newWord: return "sparkles"
        case .oldWord: return "clock.arrow.circlepath"
        case .knownWord: return "checkmark.seal.fill"
        case .unknownWord: return "exclamationmark.triangle.fill"
        }
    }

    private var statusColor: Color {
        switch status {
        case .newWord: return .blue
        case .oldWord: return .purple
        case .knownWord: return .green
        case .unknownWord: return .red
        }
    }
}

private struct StatusChip: View {
    let title: String
    let count: Int
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text("\(title) (\(count))")
                .font(.caption)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(isSelected ? Color.accentColor.opacity(0.16) : Color.gray.opacity(0.12))
                .foregroundColor(isSelected ? .accentColor : .primary)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}
