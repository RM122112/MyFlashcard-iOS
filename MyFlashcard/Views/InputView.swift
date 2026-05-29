import SwiftUI
import SwiftData

struct InputView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var speechService = SpeechService.shared
    @FocusState private var isTextEditorFocused: Bool
    
    @State private var bulkText = ""
    @State private var parsedEntries: [ParsedEntry] = []
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
                        Text("📝 Bulk Import")
                            .font(.headline)
                        Text("Paste vocabulary table with format:")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Text("English  German  Persian  Example")
                            .font(.caption)
                            .fontWeight(.medium)
                            .padding(8)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                    
                    // Text Input with keyboard dismissal
                    TextEditor(text: $bulkText)
                        .frame(minHeight: 200)
                        .padding(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )
                        .padding(.horizontal)
                        .focused($isTextEditorFocused)
                    
                    // Dismiss Keyboard Button
                    if isTextEditorFocused {
                        Button(action: {
                            isTextEditorFocused = false
                        }) {
                            Label("Hide Keyboard", systemImage: "keyboard.chevron.compact.down")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        .padding(.horizontal)
                    }
                    
                    // Parse Button
                    Button(action: {
                        isTextEditorFocused = false // Dismiss keyboard
                        parseText()
                    }) {
                        Label("Preview Import", systemImage: "doc.text.magnifyingglass")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .padding(.horizontal)
                    .disabled(bulkText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    
                    // Preview
                    if showPreview && !parsedEntries.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Preview (\(parsedEntries.count) entries)")
                                .font(.headline)
                            
                            ForEach(parsedEntries) { entry in
                                HStack {
                                    VStack(alignment: .leading) {
                                        HStack {
                                            Text(entry.englishWord)
                                                .fontWeight(.semibold)
                                            Button(action: {
                                                speechService.speak(entry.englishWord)
                                            }) {
                                                Image(systemName: "speaker.wave.2.fill")
                                                    .foregroundColor(.blue)
                                            }
                                            .buttonStyle(.borderless)
                                        }
                                        Text("🇩🇪 \(entry.german)")
                                            .font(.caption)
                                        Text("🇮🇷 \(entry.persian)")
                                            .font(.caption)
                                            .environment(\.layoutDirection, .rightToLeft)
                                    }
                                    Spacer()
                                    if entry.isValid {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.green)
                                    } else {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundColor(.red)
                                    }
                                }
                                .padding()
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(8)
                            }
                            
                            Button(action: importEntries) {
                                Label("Import All", systemImage: "square.and.arrow.down")
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
            .scrollDismissesKeyboard(.interactively) // Dismiss keyboard on scroll
            .navigationTitle("➕ Add Vocabulary")
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") {
                        isTextEditorFocused = false
                    }
                }
            }
            .alert("✅ Success", isPresented: $showSuccess) {
                Button("OK") { 
                    bulkText = ""
                    parsedEntries = []
                    showPreview = false
                }
            } message: {
                Text(successMessage)
            }
            .alert("⚠️ Duplicates Found", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private func parseText() {
        parsedEntries = TextParser.parseText(bulkText)
        showPreview = true
    }
    
    private func importEntries() {
        let validEntries = parsedEntries.filter { $0.isValid }
        
        // Check if all are duplicates
        if validEntries.isEmpty {
            errorMessage = "No valid entries to import"
            showError = true
            return
        }
        
        let result = DataService.shared.bulkImportWithDuplicateCheck(
            entries: validEntries,
            context: modelContext
        )
        
        // Show results
        if result.successCount > 0 {
            successMessage = "Added \(result.successCount) vocabulary entries!"
            if result.hasDuplicates {
                successMessage += "\n\nSkipped \(result.duplicates.count) duplicates."
            }
            showSuccess = true
        } else if result.hasDuplicates {
            // All were duplicates - show error only
            errorMessage = "All entries are duplicates:\n\(result.duplicates.joined(separator: ", "))"
            showError = true
        }
    }
}
