import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct InputView: View {
    @Environment(\.modelContext) private var modelContext
    @FocusState private var isTextEditorFocused: Bool

    @State private var viewModel = InputViewModel()
    @State private var showFileImporter = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("JSON-Vokabelimport")
                        .font(.headline)
                    Text("Importiere eine .json-Datei oder füge JSON-Text ein. Vor dem Speichern wird eine tabellarische Vorschau angezeigt.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Picker("Duplikate", selection: $viewModel.duplicateStrategy) {
                        ForEach(VocabDuplicateStrategy.allCases) { strategy in
                            Text(strategy.rawValue).tag(strategy)
                        }
                    }
                    .pickerStyle(.segmented)

                    HStack(spacing: 10) {
                        Button {
                            showFileImporter = true
                        } label: {
                            Label("JSON-Datei wählen", systemImage: "doc.badge.plus")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)

                        Button {
                            isTextEditorFocused = false
                            viewModel.parseJSONTextForPreview()
                        } label: {
                            Label("JSON prüfen", systemImage: "doc.text.magnifyingglass")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                    }

                    TextEditor(text: $viewModel.jsonText)
                        .font(.system(.footnote, design: .monospaced))
                        .frame(minHeight: 220)
                        .padding(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.gray.opacity(0.28), lineWidth: 1)
                        )
                        .focused($isTextEditorFocused)

                    if isTextEditorFocused {
                        Button("Tastatur ausblenden") {
                            isTextEditorFocused = false
                        }
                        .buttonStyle(.bordered)
                    }

                    if !viewModel.importIssues.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Fehler / Hinweise")
                                .font(.headline)
                            ForEach(viewModel.importIssues) { issue in
                                Text("• \(issue.message)")
                                    .font(.footnote)
                                    .foregroundStyle(.red)
                            }
                        }
                    }

                    if !viewModel.importedEntries.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Vorschau (\(viewModel.importedEntries.count) gültige Einträge)")
                                .font(.headline)
                            ImportedVocabPreviewTable(entries: viewModel.importedEntries)

                            if !viewModel.duplicateWords.isEmpty {
                                Text("Erkannte Duplikate: \(viewModel.duplicateWords.joined(separator: ", "))")
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                            }

                            HStack(spacing: 10) {
                                Button {
                                    viewModel.importPreviewEntries(modelContext: modelContext)
                                } label: {
                                    Label("In SwiftData übernehmen", systemImage: "square.and.arrow.down")
                                        .frame(maxWidth: .infinity)
                                }
                                .buttonStyle(.borderedProminent)
                                .disabled(viewModel.isSaving)

                                Button("Abbrechen") {
                                    viewModel.clearJSONImport()
                                }
                                .buttonStyle(.bordered)
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("➕ Wörter hinzufügen")
            .fileImporter(
                isPresented: $showFileImporter,
                allowedContentTypes: [.json, .plainText],
                allowsMultipleSelection: false
            ) { result in
                handleFileImport(result)
            }
            .alert("Import abgeschlossen", isPresented: $viewModel.showSuccessAlert) {
                Button("OK") {
                    viewModel.clearJSONImport()
                }
            } message: {
                Text(viewModel.successMessage)
            }
            .alert("Fehler", isPresented: Binding(
                get: { viewModel.error != nil },
                set: { if !$0 { viewModel.error = nil } }
            )) {
                Button("OK", role: .cancel) { viewModel.error = nil }
            } message: {
                Text(viewModel.error ?? "")
            }
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Fertig") { isTextEditorFocused = false }
                }
            }
        }
    }

    private func handleFileImport(_ result: Result<[URL], Error>) {
        switch result {
        case let .success(urls):
            guard let url = urls.first else { return }
            let hasAccess = url.startAccessingSecurityScopedResource()
            defer {
                if hasAccess {
                    url.stopAccessingSecurityScopedResource()
                }
            }
            do {
                let data = try Data(contentsOf: url)
                viewModel.jsonText = String(data: data, encoding: .utf8) ?? ""
                viewModel.parseJSONDataForPreview(data)
            } catch {
                viewModel.error = "Datei konnte nicht gelesen werden: \(error.localizedDescription)"
            }
        case let .failure(error):
            viewModel.error = "Dateiauswahl fehlgeschlagen: \(error.localizedDescription)"
        }
    }
}
