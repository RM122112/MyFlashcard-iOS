import SwiftUI
import SwiftData

struct SynonymsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Synonym.createdAt, order: .reverse) private var synonyms: [Synonym]
    @StateObject private var speechService = SpeechService.shared
    
    @State private var showAddSheet = false
    @State private var searchText = ""
    
    var filteredSynonyms: [Synonym] {
        if searchText.isEmpty {
            return synonyms
        }
        return synonyms.filter {
            $0.mainWord.localizedCaseInsensitiveContains(searchText) ||
            $0.synonyms.localizedCaseInsensitiveContains(searchText) ||
            $0.german.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(filteredSynonyms) { synonym in
                    SynonymRow(synonym: synonym, speechService: speechService)
                }
                .onDelete(perform: deleteItems)
            }
            .navigationTitle("🔄 Synonyme (\(synonyms.count))")
            .searchable(text: $searchText, prompt: "Synonyme suchen …")
            .toolbar {
                Button(action: { showAddSheet = true }) {
                    Image(systemName: "plus")
                }
            }
            .sheet(isPresented: $showAddSheet) {
                AddSynonymsSheet(isPresented: $showAddSheet)
            }
            .overlay {
                if synonyms.isEmpty {
                    ContentUnavailableView(
                        "Keine Synonyme vorhanden",
                        systemImage: "arrow.triangle.2.circlepath",
                        description: Text("Tippe auf +, um Synonyme hinzuzufügen.")
                    )
                }
            }
        }
    }
    
    private func deleteItems(offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(filteredSynonyms[index])
        }
    }
}

// MARK: - Synonym Row
struct SynonymRow: View {
    let synonym: Synonym
    @ObservedObject var speechService: SpeechService
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header
            HStack {
                VStack(alignment: .leading) {
                    Text(synonym.mainWord)
                        .font(.headline)
                    if !synonym.synonyms.isEmpty {
                        Text("(\(synonym.synonyms))")
                            .font(.subheadline)
                            .foregroundColor(.blue)
                    }
                }
                
                Button {
                    speechService.speak(synonym.mainWord)
                } label: {
                    Image(systemName: "speaker.wave.2.fill")
                        .foregroundColor(.blue)
                }
                .buttonStyle(.borderless)
                
                Spacer()
                
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
                Text("🇩🇪 \(synonym.german)")
                    .font(.subheadline)
                Spacer()
                Text("🇦🇫 \(synonym.persian)")
                    .font(.subheadline)
                    .environment(\.layoutDirection, .rightToLeft)
            }
            
            // Expanded: Example
            if isExpanded && !synonym.exampleSentence.isEmpty {
                Divider()
                HStack {
                    Text("📝 \(synonym.exampleSentence)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Button {
                        speechService.speak(synonym.exampleSentence)
                    } label: {
                        Image(systemName: "speaker.wave.2")
                            .foregroundColor(.blue)
                    }
                    .buttonStyle(.borderless)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Add Synonyms Sheet
struct AddSynonymsSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Binding var isPresented: Bool
    @FocusState private var isTextEditorFocused: Bool
    
    @State private var bulkText = ""
    @State private var parsedEntries: [ParsedSynonymEntry] = []
    @State private var showPreview = false
    @State private var showSuccess = false
    @State private var successMessage = ""
    @State private var showError = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Instructions
                    VStack(alignment: .leading, spacing: 8) {
                        Text("📝 Synonyme hinzufügen")
                            .font(.headline)
                        Text("Format: Wort (Synonym1, Synonym2)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Text("fix (repair, mend)  reparieren  تعمیر کردن  Beispielsatz ...")
                            .font(.caption)
                            .padding(8)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                    
                    // Text Input
                    TextEditor(text: $bulkText)
                        .frame(minHeight: 200)
                        .padding(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )
                        .padding(.horizontal)
                        .focused($isTextEditorFocused)
                    
                    // Keyboard dismiss
                    if isTextEditorFocused {
                        Button(action: { isTextEditorFocused = false }) {
                            Label("Tastatur ausblenden", systemImage: "keyboard.chevron.compact.down")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        .padding(.horizontal)
                    }
                    
                    // Parse Button
                    Button(action: {
                        isTextEditorFocused = false
                        parseText()
                    }) {
                        Label("Vorschau", systemImage: "doc.text.magnifyingglass")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .padding(.horizontal)
                    .disabled(bulkText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    
                    // Preview
                    if showPreview && !parsedEntries.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Vorschau (\(parsedEntries.count) Einträge)")
                                .font(.headline)
                            
                            ForEach(parsedEntries) { entry in
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text("\(entry.mainWord) (\(entry.synonyms))")
                                            .fontWeight(.semibold)
                                        Text("🇩🇪 \(entry.german)")
                                            .font(.caption)
                                        Text("🇦🇫 \(entry.persian)")
                                            .font(.caption)
                                    }
                                    Spacer()
                                    Image(systemName: entry.isValid ? "checkmark.circle.fill" : "xmark.circle.fill")
                                        .foregroundColor(entry.isValid ? .green : .red)
                                }
                                .padding()
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(8)
                            }
                            
                            Button(action: importEntries) {
                                Label("Alle importieren", systemImage: "square.and.arrow.down")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.green)
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle("Synonyme hinzufügen")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") { isPresented = false }
                }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Fertig") { isTextEditorFocused = false }
                }
            }
            .alert("✅ Erfolgreich", isPresented: $showSuccess) {
                Button("OK") {
                    bulkText = ""
                    parsedEntries = []
                    showPreview = false
                    isPresented = false
                }
            } message: {
                Text(successMessage)
            }
            .alert("⚠️ Fehler", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private func parseText() {
        parsedEntries = SynonymParser.parseText(bulkText)
        showPreview = true
    }
    
    private func importEntries() {
        let validEntries = parsedEntries.filter { $0.isValid }
        
        if validEntries.isEmpty {
            errorMessage = "Es wurden keine gültigen Einträge zum Import gefunden."
            showError = true
            return
        }
        
        var count = 0
        for entry in validEntries {
            let synonym = Synonym(
                mainWord: entry.mainWord,
                synonyms: entry.synonyms,
                german: entry.german,
                persian: entry.persian,
                exampleSentence: entry.exampleSentence
            )
            modelContext.insert(synonym)
            count += 1
        }
        
        try? modelContext.save()
        successMessage = "\(count) Synonym-Einträge wurden hinzugefügt."
        showSuccess = true
    }
}

// MARK: - Synonym Parser
class SynonymParser {
    static func parseText(_ text: String) -> [ParsedSynonymEntry] {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return []
        }
        
        var entries: [ParsedSynonymEntry] = []
        let lines = text.components(separatedBy: .newlines)
        
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.isEmpty { continue }
            if trimmed.hasPrefix("#") { continue }
            if trimmed.lowercased().contains("english word") { continue }
            
            if let entry = parseLine(trimmed) {
                entries.append(entry)
            }
        }
        
        return entries
    }
    
    private static func parseLine(_ line: String) -> ParsedSynonymEntry? {
        var workingLine = line
        
        // Remove leading number
        if let range = workingLine.range(of: #"^\d+\.?\s*"#, options: .regularExpression) {
            workingLine = String(workingLine[range.upperBound...])
        }
        
        // Extract main word and synonyms: "fix (repair, mend)"
        var mainWord = ""
        var synonyms = ""
        
        if let parenStart = workingLine.firstIndex(of: "("),
           let parenEnd = workingLine.firstIndex(of: ")") {
            mainWord = String(workingLine[..<parenStart]).trimmingCharacters(in: .whitespaces)
            synonyms = String(workingLine[workingLine.index(after: parenStart)..<parenEnd])
            workingLine = String(workingLine[workingLine.index(after: parenEnd)...]).trimmingCharacters(in: .whitespaces)
        }
        
        // Split remaining by tabs or multiple spaces
        var parts = workingLine.components(separatedBy: "\t").map { 
            $0.trimmingCharacters(in: .whitespaces) 
        }.filter { !$0.isEmpty }
        
        if parts.count < 2 {
            if let regex = try? NSRegularExpression(pattern: #"\s{2,}"#, options: []) {
                let range = NSRange(workingLine.startIndex..., in: workingLine)
                let modified = regex.stringByReplacingMatches(in: workingLine, options: [], range: range, withTemplate: "\t")
                parts = modified.components(separatedBy: "\t").map { 
                    $0.trimmingCharacters(in: .whitespaces) 
                }.filter { !$0.isEmpty }
            }
        }
        
        // If no parentheses found, first part is the word
        if mainWord.isEmpty && !parts.isEmpty {
            mainWord = parts[0]
            parts = Array(parts.dropFirst())
        }
        
        guard !mainWord.isEmpty && parts.count >= 1 else { return nil }
        
        let german = parts[0]
        let persian = parts.count > 1 ? parts[1] : ""
        let example = parts.count > 2 ? parts[2..<parts.count].joined(separator: " ") : ""
        
        return ParsedSynonymEntry(
            mainWord: mainWord,
            synonyms: synonyms,
            german: german,
            persian: persian,
            exampleSentence: example
        )
    }
}
