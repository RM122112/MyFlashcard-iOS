import SwiftUI
import PDFKit
import UniformTypeIdentifiers
import UIKit
import Vision

struct PDFLibraryView: View {
    @StateObject private var library = PDFLibraryService.shared
    @State private var selectedSort: PDFSortOption = .recentlyOpened
    @State private var isImporterPresented = false
    @State private var activeRenameItem: PDFLibraryItem?
    @State private var pendingDeleteItem: PDFLibraryItem?
    @State private var renameDraft = ""
    @State private var shareItems: [Any] = []
    @State private var showShareSheet = false
    @State private var errorMessage = ""
    @State private var showErrorAlert = false

    private var sortedItems: [PDFLibraryItem] {
        library.sortedItems(by: selectedSort)
    }

    var body: some View {
        NavigationStack {
            Group {
                if sortedItems.isEmpty {
                    ContentUnavailableView(
                        "Keine PDFs importiert",
                        systemImage: "doc.text.magnifyingglass",
                        description: Text("Importiere eine PDF-Datei, um deine Lernbibliothek aufzubauen.")
                    )
                } else {
                    List {
                        ForEach(sortedItems) { item in
                            PDFLibraryCard(
                                item: item,
                                thumbnailURL: library.thumbnailURL(for: item),
                                onRename: {
                                    activeRenameItem = item
                                    renameDraft = item.title
                                },
                                onToggleFavorite: {
                                    withAnimation(.snappy(duration: 0.2)) {
                                        library.toggleFavorite(documentID: item.id)
                                    }
                                },
                                onShare: {
                                    guard let url = library.documentShareURL(documentID: item.id) else {
                                        errorMessage = "PDF konnte nicht zum Teilen vorbereitet werden."
                                        showErrorAlert = true
                                        return
                                    }
                                    shareItems = [url]
                                    showShareSheet = true
                                },
                                onDelete: {
                                    pendingDeleteItem = item
                                }
                            )
                            .listRowInsets(EdgeInsets(top: 8, leading: 10, bottom: 8, trailing: 10))
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                            .swipeActions(edge: .leading, allowsFullSwipe: true) {
                                Button {
                                    withAnimation(.snappy(duration: 0.2)) {
                                        library.toggleFavorite(documentID: item.id)
                                    }
                                } label: {
                                    Label(
                                        item.isFavorite ? "Favorit entfernen" : "Favorit",
                                        systemImage: item.isFavorite ? "star.slash" : "star"
                                    )
                                }
                                .tint(.yellow)
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button("Umbenennen") {
                                    activeRenameItem = item
                                    renameDraft = item.title
                                }
                                .tint(.blue)

                                Button("Löschen", role: .destructive) {
                                    pendingDeleteItem = item
                                }
                            }
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }
            }
            .navigationTitle("PDF-Bibliothek")
            .background(Color(.systemGroupedBackground))
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Menu {
                        Picker("Sortieren", selection: $selectedSort) {
                            ForEach(PDFSortOption.allCases) { option in
                                Text(option.rawValue).tag(option)
                            }
                        }
                    } label: {
                        Image(systemName: "arrow.up.arrow.down.circle")
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        isImporterPresented = true
                    } label: {
                        Label("Importieren", systemImage: "square.and.arrow.down")
                    }
                }
            }
            .fileImporter(
                isPresented: $isImporterPresented,
                allowedContentTypes: [.pdf],
                allowsMultipleSelection: true
            ) { result in
                switch result {
                case .success(let urls):
                    importPDFs(from: urls)
                case .failure(let error):
                    errorMessage = "Dateiauswahl fehlgeschlagen: \(error.localizedDescription)"
                    showErrorAlert = true
                }
            }
            .dropDestination(for: URL.self) { urls, _ in
                importPDFs(from: urls)
                return true
            }
            .onOpenURL { url in
                importPDFs(from: [url])
            }
            .alert("PDF umbenennen", isPresented: Binding(
                get: { activeRenameItem != nil },
                set: { isPresented in
                    if !isPresented { activeRenameItem = nil }
                }
            )) {
                TextField("Titel", text: $renameDraft)
                Button("Abbrechen", role: .cancel) {
                    activeRenameItem = nil
                }
                Button("Speichern") {
                    guard let item = activeRenameItem else { return }
                    library.renameDocument(documentID: item.id, newTitle: renameDraft)
                    activeRenameItem = nil
                }
            }
            .alert("PDF wirklich löschen?", isPresented: Binding(
                get: { pendingDeleteItem != nil },
                set: { isPresented in
                    if !isPresented {
                        pendingDeleteItem = nil
                    }
                }
            )) {
                Button("Abbrechen", role: .cancel) {
                    pendingDeleteItem = nil
                }
                Button("Löschen", role: .destructive) {
                    guard let item = pendingDeleteItem else { return }
                    withAnimation(.snappy(duration: 0.25)) {
                        library.deleteDocument(documentID: item.id)
                    }
                    pendingDeleteItem = nil
                }
            } message: {
                Text("„\(pendingDeleteItem?.title ?? "Diese PDF")“ wird dauerhaft gelöscht.")
            }
            .sheet(isPresented: $showShareSheet) {
                ActivityView(activityItems: shareItems)
            }
            .alert("Fehler", isPresented: $showErrorAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
        }
    }

    private func importPDFs(from urls: [URL]) {
        guard !urls.isEmpty else { return }
        for url in urls {
            do {
                _ = try library.importPDF(from: url)
            } catch {
                errorMessage = "PDF-Import fehlgeschlagen: \(error.localizedDescription)"
                showErrorAlert = true
            }
        }
    }
}

private struct PDFLibraryCard: View {
    let item: PDFLibraryItem
    let thumbnailURL: URL?
    let onRename: () -> Void
    let onToggleFavorite: () -> Void
    let onShare: () -> Void
    let onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Group {
                    if let thumbnailURL, let image = UIImage(contentsOfFile: thumbnailURL.path) {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                    } else {
                        ZStack {
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(Color.accentColor.opacity(0.15))
                            Image(systemName: "doc.richtext")
                                .font(.title3)
                                .foregroundStyle(.accent)
                        }
                    }
                }
                .frame(width: 66, height: 84)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

                VStack(alignment: .leading, spacing: 5) {
                    Text(item.title)
                        .font(.headline)
                        .lineLimit(2)
                    Text("\(item.pageCount) Seiten · \(formattedFileSize)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("Import: \(formattedDate)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text("Lesezeichen \(item.bookmarks.count) · Annotationen \(item.annotations.count)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                Spacer(minLength: 0)
                if item.isFavorite {
                    Image(systemName: "star.fill")
                        .foregroundStyle(.yellow)
                }
            }
            HStack(spacing: 8) {
                NavigationLink {
                    PDFReaderView(documentID: item.id)
                } label: {
                    Label("Öffnen", systemImage: "book")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)

                Button(action: onShare) {
                    Image(systemName: "square.and.arrow.up")
                }
                .buttonStyle(.bordered)

                Button(action: onToggleFavorite) {
                    Image(systemName: item.isFavorite ? "star.slash" : "star")
                }
                .buttonStyle(.bordered)

                Button(action: onRename) {
                    Image(systemName: "pencil")
                }
                .buttonStyle(.bordered)

                Button(role: .destructive, action: onDelete) {
                    Image(systemName: "trash")
                }
                .buttonStyle(.bordered)
            }
        }
        .padding(12)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var formattedDate: String {
        item.createdAt.formatted(date: .abbreviated, time: .omitted)
    }

    private var formattedFileSize: String {
        ByteCountFormatter.string(fromByteCount: item.fileSizeBytes, countStyle: .file)
    }
}

private struct PDFColorOption: Identifiable, Hashable {
    let label: String
    let hex: String

    var id: String { hex.lowercased() }
    var color: Color { Color(uiColor: uiColor) }
    var uiColor: UIColor { UIColor(hex: hex) ?? .systemYellow }
}

private let defaultPDFColors: [PDFColorOption] = [
    PDFColorOption(label: "Schwarz", hex: "#111827"),
    PDFColorOption(label: "Dunkelgrau", hex: "#374151"),
    PDFColorOption(label: "Hellgrau", hex: "#9CA3AF"),
    PDFColorOption(label: "Grün", hex: "#10B981"),
    PDFColorOption(label: "Türkis", hex: "#14B8A6"),
    PDFColorOption(label: "Gelb", hex: "#F59E0B"),
    PDFColorOption(label: "Blau", hex: "#2563EB"),
    PDFColorOption(label: "Rot", hex: "#DC2626")
]

private extension PDFAnnotationType {
    var displayName: String {
        switch self {
        case .highlight: return "Markierung"
        case .underline: return "Unterstreichung"
        case .strikethrough: return "Durchstreichung"
        case .note: return "Notiz"
        }
    }
}

private enum PDFReaderTool: String, CaseIterable, Identifiable {
    case pen = "Stift"
    case fountain = "Füller"
    case marker = "Marker"
    case eraser = "Radierer"
    case lasso = "Lasso"
    case shapes = "Formen"
    case text = "Textwerkzeug"
    case comment = "Kommentar"
    case selection = "Auswahl"
    case ruler = "Lineal"
    case laser = "Laser"
    case undo = "Rückgängig"
    case redo = "Wiederholen"

    var id: String { rawValue }
}

private enum PDFEraserMode: String, CaseIterable, Identifiable {
    case stroke = "Strich"
    case all = "Alles"

    var id: String { rawValue }
}

private struct DeletedAnnotationSnapshot {
    let record: PDFAnnotationRecord
    let bounds: CGRect
    let color: UIColor?
    let contents: String?
}

private enum PDFReaderPrefsKeys {
    static let selectedTool = "pdf.reader.selectedTool"
    static let selectedColorHex = "pdf.reader.selectedColorHex"
    static let selectedOpacity = "pdf.reader.selectedOpacity"
    static let selectedStrokeWidth = "pdf.reader.selectedStrokeWidth"
    static let eraserMode = "pdf.reader.eraserMode"
    static let toolbarVisible = "pdf.reader.toolbarVisible"
    static let recentColorHexes = "pdf.reader.recentColorHexes"
}

struct PDFReaderView: View {
    @StateObject private var library = PDFLibraryService.shared
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.dismiss) private var dismiss

    let documentID: UUID

    @State private var pdfDocument: PDFDocument?
    @State private var pdfViewRef: PDFView?
    @State private var currentSelection: PDFSelection?
    @State private var currentPage = 0
    @State private var totalPageCount = 0
    @State private var displayDirection: PDFDisplayDirection = .vertical
    @State private var useTwoUpMode = false
    @State private var selectedTool: PDFReaderTool = .marker
    @State private var selectedColorHex = "#F59E0B"
    @State private var selectedOpacity = 0.62
    @State private var selectedStrokeWidth = 3.2
    @State private var eraserMode: PDFEraserMode = .stroke
    @State private var recentColorHexes: [String] = []
    @State private var customColor = Color.yellow
    @State private var isToolbarVisible = true
    @State private var noteDraft = ""
    @State private var pendingNoteSelection: PDFSelection?
    @State private var showNotePrompt = false
    @State private var showBookmarks = false
    @State private var showAnnotations = false
    @State private var showReaderSettings = false
    @State private var showSearchPrompt = false
    @State private var searchDraft = ""
    @State private var showPageJumpPrompt = false
    @State private var pageJumpDraft = ""
    @State private var showExportSheet = false
    @State private var showSelectionShareSheet = false
    @State private var showDocumentShareSheet = false
    @State private var exportedText = ""
    @State private var selectionShareText = ""
    @State private var documentShareItems: [Any] = []
    @State private var redoAnnotations: [DeletedAnnotationSnapshot] = []
    @State private var activeEditAnnotation: PDFAnnotationRecord?
    @State private var editNoteDraft = ""
    @State private var showErrorAlert = false
    @State private var errorMessage = ""
    @State private var showDeleteDocumentAlert = false

    private var documentItem: PDFLibraryItem? {
        library.item(with: documentID)
    }

    private var selectedUIColor: UIColor {
        UIColor(hex: selectedColorHex) ?? .systemYellow
    }

    private var normalizedSelectedColorHex: String {
        selectedColorHex.uppercased()
    }

    private var isEditNotePresented: Binding<Bool> {
        Binding(
            get: { activeEditAnnotation != nil },
            set: { isPresented in
                if !isPresented {
                    activeEditAnnotation = nil
                }
            }
        )
    }

    var body: some View {
        Group {
            if let document = pdfDocument, let item = documentItem {
                VStack(spacing: 0) {
                    PDFKitReaderView(
                        document: document,
                        initialPageIndex: item.lastReadPage,
                        displayDirection: displayDirection,
                        useTwoUpMode: useTwoUpMode,
                        onPageChanged: { page in
                            if currentPage != page {
                                currentPage = page
                                library.updateLastOpenedPage(documentID: documentID, pageIndex: page)
                            }
                        },
                        onSelectionChanged: { selection in
                            currentSelection = selection
                        },
                        onViewCreated: { view in
                            pdfViewRef = view
                        }
                    )
                    .background(Color(.systemBackground))

                    if isToolbarVisible {
                        readerToolBar
                            .transition(.move(edge: .top).combined(with: .opacity))
                    }
                }
                .animation(.snappy(duration: 0.22), value: isToolbarVisible)
                .navigationTitle(item.title)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItemGroup(placement: .topBarTrailing) {
                        Button {
                            isToolbarVisible.toggle()
                            persistToolbarPreferences()
                        } label: {
                            Image(systemName: isToolbarVisible ? "eye.slash" : "eye")
                        }

                        Menu {
                            Button(displayDirection == .vertical ? "Horizontal blättern" : "Vertikal scrollen") {
                                toggleDisplayDirection()
                            }
                            Button(useTwoUpMode ? "Doppelseite aus" : "Doppelseite an") {
                                useTwoUpMode.toggle()
                            }
                            Button("Lesezeichen hinzufügen") { addBookmarkForCurrentPage() }
                            Button("Lesezeichen anzeigen") { showBookmarks = true }
                            Button("Annotationen anzeigen") { showAnnotations = true }
                            Button("Annotationen exportieren") {
                                exportedText = library.exportAnnotationsText(documentID: documentID)
                                showExportSheet = true
                            }
                            Button("PDF teilen") {
                                shareCurrentDocument()
                            }
                            Button("Reader-Einstellungen") {
                                showReaderSettings = true
                            }
                            Button("PDF löschen", role: .destructive) {
                                showDeleteDocumentAlert = true
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                        }
                    }
                }
                .sheet(isPresented: $showBookmarks) {
                    bookmarksSheet
                }
                .sheet(isPresented: $showAnnotations) {
                    annotationsSheet
                }
                .sheet(isPresented: $showExportSheet) {
                    ActivityView(activityItems: [exportedText])
                }
                .sheet(isPresented: $showSelectionShareSheet) {
                    ActivityView(activityItems: [selectionShareText])
                }
                .sheet(isPresented: $showDocumentShareSheet) {
                    ActivityView(activityItems: documentShareItems)
                }
                .sheet(isPresented: $showReaderSettings) {
                    readerSettingsSheet
                }
                .alert("PDF löschen?", isPresented: $showDeleteDocumentAlert) {
                    Button("Abbrechen", role: .cancel) { }
                    Button("Löschen", role: .destructive) {
                        deleteCurrentDocument()
                    }
                } message: {
                    Text("Diese PDF wird dauerhaft aus deiner Bibliothek gelöscht.")
                }
                .alert("Im Web suchen", isPresented: $showSearchPrompt) {
                    TextField("Suchbegriff", text: $searchDraft)
                    Button("Abbrechen", role: .cancel) { }
                    Button("Suchen") {
                        guard !searchDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
                        openSelectionURL(base: "https://www.google.com/search?q=", emptyMessage: "Kein Text zum Suchen gefunden.", fallbackText: searchDraft)
                    }
                }
                .alert("Zur Seite springen", isPresented: $showPageJumpPrompt) {
                    TextField("Seite", text: $pageJumpDraft)
                        .keyboardType(.numberPad)
                    Button("Abbrechen", role: .cancel) { }
                    Button("Öffnen") {
                        guard let page = Int(pageJumpDraft), page > 0 else {
                            showSelectionError("Ungültige Seitenzahl.")
                            return
                        }
                        goToPage(page - 1)
                    }
                } message: {
                    Text(totalPageCount > 0 ? "1 bis \(totalPageCount)" : "Seitenzahl eingeben")
                }
                .alert("Notiz hinzufügen", isPresented: $showNotePrompt) {
                    TextField("Notiz", text: $noteDraft, axis: .vertical)
                    Button("Abbrechen", role: .cancel) {
                        noteDraft = ""
                        pendingNoteSelection = nil
                    }
                    Button("Speichern") {
                        applyNoteToPendingSelection(note: noteDraft)
                        noteDraft = ""
                        pendingNoteSelection = nil
                    }
                } message: {
                    Text("Die Notiz wird der aktuellen Textmarkierung zugeordnet.")
                }
                .alert("Notiz bearbeiten", isPresented: isEditNotePresented) {
                    TextField("Notiz", text: $editNoteDraft, axis: .vertical)
                    Button("Abbrechen", role: .cancel) {
                        activeEditAnnotation = nil
                    }
                    Button("Speichern") {
                        guard let annotation = activeEditAnnotation else { return }
                        updateAnnotationNote(annotation, note: editNoteDraft)
                        activeEditAnnotation = nil
                    }
                }
                .onAppear {
                    loadToolbarPreferences()
                    loadDocument()
                }
                .onChange(of: documentID) { _, _ in
                    loadDocument()
                }
                .alert("PDF-Fehler", isPresented: $showErrorAlert) {
                    Button("OK", role: .cancel) { }
                } message: {
                    Text(errorMessage)
                }
            } else {
                ContentUnavailableView(
                    "PDF nicht gefunden",
                    systemImage: "exclamationmark.triangle",
                    description: Text("Das Dokument konnte nicht geladen werden.")
                )
                .onAppear {
                    loadDocument()
                }
            }
        }
    }

    private var readerToolBar: some View {
        VStack(spacing: 10) {
            Text(totalPageCount > 0 ? "Seite \(currentPage + 1) / \(totalPageCount)" : "Seite \(currentPage + 1)")
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(PDFReaderTool.allCases) { tool in
                        Button {
                            selectedTool = tool
                            persistToolbarPreferences()
                        } label: {
                            toolChip(tool: tool)
                        }
                        .buttonStyle(.plain)
                        .opacity(tool == .redo && redoAnnotations.isEmpty ? 0.5 : 1.0)
                    }
                }
            }

            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Werkzeugeigenschaften")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                    switch selectedTool {
                    case .pen, .fountain, .marker:
                        HStack {
                            Text("Strich \(String(format: "%.1f", selectedStrokeWidth))")
                            Spacer()
                        }
                        .font(.caption2)
                        Slider(
                            value: Binding(
                                get: { selectedStrokeWidth },
                                set: { value in
                                    selectedStrokeWidth = value
                                    persistToolbarPreferences()
                                }
                            ),
                            in: 1...16,
                            step: 0.5
                        )
                        HStack {
                            Text("Deckkraft")
                            Spacer()
                            Text("\(Int(selectedOpacity * 100))%")
                        }
                        .font(.caption2)
                        Slider(
                            value: Binding(
                                get: { selectedOpacity },
                                set: { value in
                                    selectedOpacity = value
                                    persistToolbarPreferences()
                                }
                            ),
                            in: 0.2...1
                        )
                    case .eraser:
                        HStack(spacing: 6) {
                            ForEach(PDFEraserMode.allCases) { mode in
                                Button(mode.rawValue) {
                                    eraserMode = mode
                                    persistToolbarPreferences()
                                }
                                .buttonStyle(.borderedProminent)
                                .tint(eraserMode == mode ? .accentColor : .secondary.opacity(0.2))
                            }
                        }
                    default:
                        Text("Werkzeug bereit. Mit „Werkzeug anwenden“ ausführen.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                VStack(alignment: .leading, spacing: 6) {
                    Text("Farbpalette")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(defaultPDFColors) { colorOption in
                                colorSwatch(hex: colorOption.hex)
                            }
                            ForEach(recentColorHexes, id: \.self) { hex in
                                if !defaultPDFColors.contains(where: { $0.hex.caseInsensitiveCompare(hex) == .orderedSame }) {
                                    colorSwatch(hex: hex)
                                }
                            }
                            ColorPicker("", selection: Binding(
                                get: { customColor },
                                set: { value in
                                    customColor = value
                                    selectColor(hex: UIColor(value).hexString)
                                }
                            ), supportsOpacity: false)
                            .labelsHidden()
                            .frame(width: 26, height: 26)
                        }
                    }
                }
                .frame(width: horizontalSizeClass == .regular ? 260 : 210, alignment: .leading)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 2) {
                        quickActionButton(systemImage: "arrow.uturn.backward", label: "Rückgängig") {
                            undoLastAnnotation()
                        }
                        quickActionButton(systemImage: "arrow.uturn.forward", label: "Wiederholen", disabled: redoAnnotations.isEmpty) {
                            redoLastAnnotation()
                        }
                        quickActionButton(systemImage: "magnifyingglass", label: "Suche") {
                            searchDraft = selectedText
                            showSearchPrompt = true
                        }
                        quickActionButton(systemImage: "list.number", label: "Seiten") {
                            pageJumpDraft = "\(currentPage + 1)"
                            showPageJumpPrompt = true
                        }
                        quickActionButton(systemImage: "bookmark.badge.plus", label: "Lesezeichen") {
                            addBookmarkForCurrentPage()
                        }
                        quickActionButton(systemImage: "square.and.arrow.up", label: "Teilen") {
                            shareCurrentDocument()
                        }
                        quickActionButton(systemImage: "gearshape", label: "Einstellungen") {
                            showReaderSettings = true
                        }
                        Menu {
                            Button("Lesezeichen anzeigen") { showBookmarks = true }
                            Button("Annotationen anzeigen") { showAnnotations = true }
                            Button("Annotationen exportieren") {
                                exportedText = library.exportAnnotationsText(documentID: documentID)
                                showExportSheet = true
                            }
                            Button("PDF löschen", role: .destructive) {
                                showDeleteDocumentAlert = true
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                                .font(.body)
                                .padding(8)
                        }
                        .buttonStyle(.bordered)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
            }

            HStack {
                Spacer()
                Button("Werkzeug anwenden") {
                    applySelectedTool()
                }
                .buttonStyle(.borderedProminent)
            }

            if currentSelection != nil {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        actionButton(title: "Markieren", systemImage: "highlighter") {
                            applyCurrentAnnotation(type: .highlight, note: nil)
                        }
                        actionButton(title: "Unterstreichen", systemImage: "underline") {
                            applyCurrentAnnotation(type: .underline, note: nil)
                        }
                        actionButton(title: "Durchstreichen", systemImage: "strikethrough") {
                            applyCurrentAnnotation(type: .strikethrough, note: nil)
                        }
                        actionButton(title: "Kopieren", systemImage: "doc.on.doc") {
                            copySelectedText()
                        }
                        actionButton(title: "Übersetzen", systemImage: "character.bubble") {
                            translateSelectedText()
                        }
                        actionButton(title: "Suchen", systemImage: "magnifyingglass") {
                            searchSelectedText()
                        }
                        actionButton(title: "Definieren", systemImage: "text.book.closed") {
                            defineSelectedText()
                        }
                        actionButton(title: "Notiz", systemImage: "note.text.badge.plus") {
                            pendingNoteSelection = currentSelection
                            showNotePrompt = true
                        }
                        actionButton(title: "Teilen", systemImage: "square.and.arrow.up") {
                            shareSelectedText()
                        }
                    }
                }
            } else {
                Text("Text auswählen, um Aktionen wie Markieren, Übersetzen oder Notizen zu verwenden.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(12)
        .background(.ultraThinMaterial)
    }

    private func toolChip(tool: PDFReaderTool) -> some View {
        Text(tool.rawValue)
            .font(.caption)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(selectedTool == tool ? Color.accentColor.opacity(0.24) : Color.secondary.opacity(0.14))
            .clipShape(Capsule())
    }

    private func colorSwatch(hex: String) -> some View {
        Circle()
            .fill(Color(uiColor: UIColor(hex: hex) ?? .systemYellow))
            .frame(width: 22, height: 22)
            .overlay {
                if normalizedSelectedColorHex == hex.uppercased() {
                    Circle().stroke(Color.primary, lineWidth: 2)
                }
            }
            .onTapGesture {
                selectColor(hex: hex)
            }
    }

    private func quickActionButton(systemImage: String, label: String, disabled: Bool = false, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.body)
                .padding(8)
        }
        .buttonStyle(.bordered)
        .disabled(disabled)
        .accessibilityLabel(label)
    }

    private var readerSettingsSheet: some View {
        NavigationStack {
            Form {
                Section("Anzeige") {
                    Picker("Lesemodus", selection: $displayDirection) {
                        Text("Vertikal").tag(PDFDisplayDirection.vertical)
                        Text("Horizontal").tag(PDFDisplayDirection.horizontal)
                    }
                    .pickerStyle(.segmented)
                    Toggle("Doppelseitenmodus", isOn: $useTwoUpMode)
                }

                Section("Toolbar") {
                    Toggle(
                        "Toolbar sichtbar",
                        isOn: Binding(
                            get: { isToolbarVisible },
                            set: { value in
                                isToolbarVisible = value
                                persistToolbarPreferences()
                            }
                        )
                    )
                    HStack {
                        Text("Standard Strich")
                        Spacer()
                        Text(String(format: "%.1f", selectedStrokeWidth))
                            .foregroundStyle(.secondary)
                    }
                    Slider(
                        value: Binding(
                            get: { selectedStrokeWidth },
                            set: { value in
                                selectedStrokeWidth = value
                                persistToolbarPreferences()
                            }
                        ),
                        in: 1...16,
                        step: 0.5
                    )
                }
            }
            .navigationTitle("Reader-Einstellungen")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Schließen") { showReaderSettings = false }
                }
            }
        }
    }

    private func shareCurrentDocument() {
        guard let url = library.documentShareURL(documentID: documentID) else {
            showSelectionError("PDF konnte nicht zum Teilen vorbereitet werden.")
            return
        }
        documentShareItems = [url]
        showDocumentShareSheet = true
    }

    private func selectColor(hex: String) {
        let normalized = UIColor(hex: hex)?.hexString ?? "#F59E0B"
        selectedColorHex = normalized
        customColor = Color(uiColor: UIColor(hex: normalized) ?? .systemYellow)

        var updated = recentColorHexes.filter { $0.caseInsensitiveCompare(normalized) != .orderedSame }
        updated.insert(normalized, at: 0)
        recentColorHexes = Array(updated.prefix(6))
        persistToolbarPreferences()
    }

    private func loadToolbarPreferences() {
        let defaults = UserDefaults.standard
        if let rawTool = defaults.string(forKey: PDFReaderPrefsKeys.selectedTool),
           let tool = PDFReaderTool(rawValue: rawTool) {
            selectedTool = tool
        }
        if let storedColor = defaults.string(forKey: PDFReaderPrefsKeys.selectedColorHex) {
            selectedColorHex = storedColor
            customColor = Color(uiColor: UIColor(hex: storedColor) ?? .systemYellow)
        } else {
            selectColor(hex: selectedColorHex)
        }
        let storedOpacity = defaults.double(forKey: PDFReaderPrefsKeys.selectedOpacity)
        if storedOpacity > 0 {
            selectedOpacity = storedOpacity
        }
        let storedStroke = defaults.double(forKey: PDFReaderPrefsKeys.selectedStrokeWidth)
        if storedStroke > 0 {
            selectedStrokeWidth = storedStroke
        }
        if let rawEraserMode = defaults.string(forKey: PDFReaderPrefsKeys.eraserMode),
           let mode = PDFEraserMode(rawValue: rawEraserMode) {
            eraserMode = mode
        }
        if defaults.object(forKey: PDFReaderPrefsKeys.toolbarVisible) != nil {
            isToolbarVisible = defaults.bool(forKey: PDFReaderPrefsKeys.toolbarVisible)
        }
        if let recent = defaults.array(forKey: PDFReaderPrefsKeys.recentColorHexes) as? [String] {
            recentColorHexes = Array(recent.prefix(6))
        }
    }

    private func persistToolbarPreferences() {
        let defaults = UserDefaults.standard
        defaults.set(selectedTool.rawValue, forKey: PDFReaderPrefsKeys.selectedTool)
        defaults.set(normalizedSelectedColorHex, forKey: PDFReaderPrefsKeys.selectedColorHex)
        defaults.set(selectedOpacity, forKey: PDFReaderPrefsKeys.selectedOpacity)
        defaults.set(selectedStrokeWidth, forKey: PDFReaderPrefsKeys.selectedStrokeWidth)
        defaults.set(eraserMode.rawValue, forKey: PDFReaderPrefsKeys.eraserMode)
        defaults.set(isToolbarVisible, forKey: PDFReaderPrefsKeys.toolbarVisible)
        defaults.set(recentColorHexes, forKey: PDFReaderPrefsKeys.recentColorHexes)
    }

    private func actionButton(title: String, systemImage: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .font(.caption)
        }
        .buttonStyle(.bordered)
    }

    private var selectedText: String {
        currentSelection?.string?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    }

    private func copySelectedText() {
        resolveActionText(emptyMessage: "Kein Text zum Kopieren gefunden.") { text in
            UIPasteboard.general.string = text
        }
    }

    private func shareSelectedText() {
        resolveActionText(emptyMessage: "Kein Text zum Teilen gefunden.") { text in
            selectionShareText = text
            showSelectionShareSheet = true
        }
    }

    private func searchSelectedText() {
        openSelectionURL(
            base: "https://www.google.com/search?q=",
            emptyMessage: "Kein Text zum Suchen gefunden.",
            fallbackText: nil
        )
    }

    private func defineSelectedText() {
        openSelectionURL(
            base: "https://www.dictionary.com/browse/",
            emptyMessage: "Kein Text zum Definieren gefunden.",
            fallbackText: nil
        )
    }

    private func translateSelectedText() {
        resolveActionText(emptyMessage: "Kein Text zum Übersetzen gefunden.") { text in
            guard let encoded = text.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
                showSelectionError("Übersetzung konnte nicht geöffnet werden.")
                return
            }
            let urlString = "https://translate.google.com/?sl=auto&tl=de&text=\(encoded)&op=translate"
            openExternalURL(urlString, failureMessage: "Übersetzung konnte nicht geöffnet werden.")
        }
    }

    private func openSelectionURL(base: String, emptyMessage: String, fallbackText: String? = nil) {
        resolveActionText(emptyMessage: emptyMessage, fallbackText: fallbackText) { text in
            guard let encoded = text.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
                showSelectionError("Aktion konnte nicht geöffnet werden.")
                return
            }
            openExternalURL("\(base)\(encoded)", failureMessage: "Aktion konnte nicht geöffnet werden.")
        }
    }

    private func resolveActionText(
        emptyMessage: String,
        fallbackText: String? = nil,
        action: @escaping (String) -> Void
    ) {
        if let fallbackText, !fallbackText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            action(fallbackText)
            return
        }
        Task {
            let text = await preferredActionText()
            guard !text.isEmpty else {
                await MainActor.run {
                    showSelectionError(emptyMessage)
                }
                return
            }
            await MainActor.run {
                action(text)
            }
        }
    }

    private func preferredActionText() async -> String {
        if !selectedText.isEmpty {
            return selectedText
        }
        return await ocrTextFromCurrentPage() ?? ""
    }

    private func ocrTextFromCurrentPage() async -> String? {
        guard let page = pdfViewRef?.currentPage ?? pdfDocument?.page(at: currentPage) else {
            return nil
        }
        let pageBounds = page.bounds(for: .mediaBox)
        let targetWidth: CGFloat = 1600
        let ratio = pageBounds.height / max(pageBounds.width, 1)
        let targetSize = CGSize(width: targetWidth, height: max(700, targetWidth * ratio))
        let image = page.thumbnail(of: targetSize, for: .mediaBox)
        guard let cgImage = image.cgImage else {
            return nil
        }

        return await Task.detached(priority: .userInitiated) {
            let request = VNRecognizeTextRequest()
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true
            request.recognitionLanguages = ["en-US"]
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            do {
                try handler.perform([request])
                let observations = request.results ?? []
                let text = observations
                    .compactMap { $0.topCandidates(1).first?.string }
                    .joined(separator: " ")
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                return text.isEmpty ? nil : text
            } catch {
                return nil
            }
        }.value
    }

    private func openExternalURL(_ urlString: String, failureMessage: String) {
        guard let url = URL(string: urlString) else {
            showSelectionError(failureMessage)
            return
        }
        UIApplication.shared.open(url)
    }

    private func showSelectionError(_ message: String) {
        errorMessage = message
        showErrorAlert = true
    }

    private func applySelectedTool() {
        switch selectedTool {
        case .pen:
            applyCurrentAnnotation(type: .underline, note: nil)
        case .fountain:
            applyCurrentAnnotation(type: .strikethrough, note: nil)
        case .marker:
            applyCurrentAnnotation(type: .highlight, note: nil)
        case .text, .comment:
            guard currentSelection != nil else {
                showSelectionError("Bitte zuerst Text auswählen.")
                return
            }
            pendingNoteSelection = currentSelection
            showNotePrompt = true
        case .eraser:
            if eraserMode == .all {
                clearAllAnnotations()
            } else {
                undoLastAnnotation()
            }
        case .undo:
            undoLastAnnotation()
        case .redo:
            redoLastAnnotation()
        case .selection:
            // Native selection via long press is already active.
            break
        case .lasso:
            showAnnotations = true
        case .ruler, .shapes:
            showSelectionError("Dieses Werkzeug wird im nächsten Schritt erweitert.")
        case .laser:
            showSelectionError("Laserpointer ist vorbereitet und folgt im nächsten Schritt.")
        }
    }

    private func undoLastAnnotation() {
        guard let item = documentItem else { return }
        guard let last = item.annotations.max(by: { $0.createdAt < $1.createdAt }) else {
            showSelectionError("Keine Annotation zum Rückgängig machen vorhanden.")
            return
        }
        if let snapshot = deleteAnnotation(last, captureForRedo: true) {
            redoAnnotations.append(snapshot)
        }
    }

    private func redoLastAnnotation() {
        guard let snapshot = redoAnnotations.popLast() else {
            showSelectionError("Keine Aktion zum Wiederholen vorhanden.")
            return
        }
        restoreAnnotation(snapshot)
    }

    private func clearAllAnnotations() {
        guard let item = documentItem, !item.annotations.isEmpty else {
            showSelectionError("Keine Annotationen zum Löschen vorhanden.")
            return
        }
        var snapshots: [DeletedAnnotationSnapshot] = []
        for record in item.annotations.sorted(by: { $0.createdAt > $1.createdAt }) {
            if let snapshot = deleteAnnotation(record, captureForRedo: true) {
                snapshots.append(snapshot)
            }
        }
        if snapshots.isEmpty {
            showSelectionError("Keine Annotationen zum Löschen gefunden.")
            return
        }
        redoAnnotations.append(contentsOf: snapshots)
    }

    private var bookmarksSheet: some View {
        NavigationStack {
            List {
                if let item = documentItem, !item.bookmarks.isEmpty {
                    ForEach(item.bookmarks.sorted(by: { $0.pageIndex < $1.pageIndex })) { bookmark in
                        Button {
                            goToPage(bookmark.pageIndex)
                            showBookmarks = false
                        } label: {
                            HStack {
                                Text(bookmark.title)
                                Spacer()
                                Text("Seite \(bookmark.pageIndex + 1)")
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .swipeActions {
                            Button("Löschen", role: .destructive) {
                                library.removeBookmark(documentID: documentID, bookmarkID: bookmark.id)
                            }
                        }
                    }
                } else {
                    ContentUnavailableView("Keine Lesezeichen", systemImage: "bookmark.slash")
                        .frame(maxWidth: .infinity, alignment: .center)
                }
            }
            .navigationTitle("Lesezeichen")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Schließen") { showBookmarks = false }
                }
            }
        }
    }

    private var annotationsSheet: some View {
        NavigationStack {
            List {
                if let item = documentItem, !item.annotations.isEmpty {
                    ForEach(item.annotations.sorted(by: { $0.createdAt > $1.createdAt })) { annotation in
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text("Seite \(annotation.pageIndex + 1)")
                                    .font(.subheadline).bold()
                                Spacer()
                                Text(annotation.type.displayName)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            if !annotation.selectedText.isEmpty {
                                Text(annotation.selectedText)
                                    .font(.caption)
                                    .lineLimit(2)
                            }
                            if let note = annotation.note, !note.isEmpty {
                                Text(note)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            if let note = annotation.note {
                                activeEditAnnotation = annotation
                                editNoteDraft = note
                            }
                        }
                        .swipeActions {
                            Button("Löschen", role: .destructive) {
                                deleteAnnotation(annotation)
                            }
                        }
                    }
                } else {
                    ContentUnavailableView("Keine Annotationen", systemImage: "highlighter")
                        .frame(maxWidth: .infinity, alignment: .center)
                }
            }
            .navigationTitle("Annotationen")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Schließen") { showAnnotations = false }
                }
            }
        }
    }

    private func toggleDisplayDirection() {
        displayDirection = (displayDirection == .vertical) ? .horizontal : .vertical
    }

    private func loadDocument() {
        guard let item = documentItem else {
            pdfDocument = nil
            totalPageCount = 0
            return
        }

        let url = library.fileURL(for: item)
        guard let document = PDFDocument(url: url) else {
            pdfDocument = nil
            totalPageCount = 0
            errorMessage = "Die PDF-Datei konnte nicht geöffnet werden."
            showErrorAlert = true
            return
        }
        guard document.pageCount > 0 else {
            pdfDocument = nil
            totalPageCount = 0
            errorMessage = "Die PDF enthält keine darstellbaren Seiten."
            showErrorAlert = true
            return
        }
        pdfDocument = document
        totalPageCount = document.pageCount
        currentPage = item.lastReadPage
        redoAnnotations.removeAll()
    }

    private func addBookmarkForCurrentPage() {
        library.addBookmark(documentID: documentID, pageIndex: currentPage, title: "Seite \(currentPage + 1)")
    }

    private func goToPage(_ pageIndex: Int) {
        guard pageIndex >= 0, pageIndex < totalPageCount else {
            showSelectionError("Ungültige Seitenzahl.")
            return
        }
        guard let page = pdfDocument?.page(at: pageIndex) else { return }
        pdfViewRef?.go(to: page)
    }

    private func applyCurrentAnnotation(type: PDFAnnotationType, note: String?) {
        guard let selection = currentSelection else {
            showSelectionError("Bitte zuerst Text auswählen.")
            return
        }
        applyAnnotation(selection: selection, type: type, note: note)
    }

    private func applyNoteToPendingSelection(note: String?) {
        guard let selection = pendingNoteSelection ?? currentSelection else { return }
        applyAnnotation(selection: selection, type: .note, note: note)
    }

    private func applyAnnotation(selection: PDFSelection, type: PDFAnnotationType, note: String?) {
        guard let document = pdfDocument, let item = documentItem else { return }

        let segments = selection.selectionsByLine()
        let selections = segments.isEmpty ? [selection] : segments

        var insertedRecords: [PDFAnnotationRecord] = []

        for segment in selections {
            guard let page = segment.pages.first else { continue }
            var bounds = segment.bounds(for: page)
            guard bounds.width > 0, bounds.height > 0 else { continue }

            switch type {
            case .underline:
                let underlineHeight = max(CGFloat(selectedStrokeWidth), bounds.height * 0.18)
                bounds.origin.y = bounds.maxY - underlineHeight
                bounds.size.height = underlineHeight
            case .strikethrough:
                let strokeHeight = max(CGFloat(selectedStrokeWidth), bounds.height * 0.14)
                let middleY = bounds.midY - (strokeHeight / 2)
                bounds.origin.y = middleY
                bounds.size.height = strokeHeight
            case .highlight, .note:
                break
            }

            let subtype: PDFAnnotationSubtype = {
                switch type {
                case .highlight, .note: return .highlight
                case .underline: return .underline
                case .strikethrough: return .strikeOut
                }
            }()

            let alpha: CGFloat = {
                switch type {
                case .highlight, .note:
                    return CGFloat(selectedOpacity)
                case .underline, .strikethrough:
                    return 1.0
                }
            }()

            let selectedText = segment.string?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            let record = PDFAnnotationRecord(
                pageIndex: document.index(for: page),
                type: type,
                colorHex: selectedColorHex,
                selectedText: selectedText,
                note: note
            )

            let annotation = PDFAnnotation(bounds: bounds, forType: subtype, withProperties: nil)
            annotation.color = selectedUIColor.withAlphaComponent(alpha)
            annotation.userName = record.id.uuidString
            if let note, !note.isEmpty {
                annotation.contents = note
            }
            page.addAnnotation(annotation)
            insertedRecords.append(record)
        }

        guard !insertedRecords.isEmpty else { return }
        for record in insertedRecords {
            library.addAnnotation(documentID: item.id, annotation: record)
        }
        redoAnnotations.removeAll()
        saveDocumentChanges()
        pdfViewRef?.clearSelection()
        currentSelection = nil
    }

    @discardableResult
    private func deleteAnnotation(_ record: PDFAnnotationRecord, captureForRedo: Bool = false) -> DeletedAnnotationSnapshot? {
        guard let document = pdfDocument else { return nil }
        let annotationID = record.id.uuidString
        var snapshot: DeletedAnnotationSnapshot?

        for pageIndex in 0..<document.pageCount {
            guard let page = document.page(at: pageIndex) else { continue }
            let toDelete = page.annotations.filter { $0.userName == annotationID }
            if captureForRedo, snapshot == nil, let first = toDelete.first {
                snapshot = DeletedAnnotationSnapshot(
                    record: record,
                    bounds: first.bounds,
                    color: first.color,
                    contents: first.contents
                )
            }
            for annotation in toDelete {
                page.removeAnnotation(annotation)
            }
        }

        library.removeAnnotation(documentID: documentID, annotationID: record.id)
        saveDocumentChanges()
        return snapshot
    }

    private func restoreAnnotation(_ snapshot: DeletedAnnotationSnapshot) {
        guard let document = pdfDocument, let page = document.page(at: snapshot.record.pageIndex) else { return }
        if page.annotations.contains(where: { $0.userName == snapshot.record.id.uuidString }) {
            return
        }

        let alpha: CGFloat = (snapshot.record.type == .underline || snapshot.record.type == .strikethrough) ? 1.0 : 0.35
        let subtype: PDFAnnotationSubtype = {
            switch snapshot.record.type {
            case .highlight, .note: return .highlight
            case .underline: return .underline
            case .strikethrough: return .strikeOut
            }
        }()
        let annotation = PDFAnnotation(bounds: snapshot.bounds, forType: subtype, withProperties: nil)
        annotation.userName = snapshot.record.id.uuidString
        annotation.color = (snapshot.color ?? UIColor(hex: snapshot.record.colorHex) ?? selectedUIColor).withAlphaComponent(alpha)
        if let note = snapshot.contents ?? snapshot.record.note, !note.isEmpty {
            annotation.contents = note
        }
        page.addAnnotation(annotation)
        library.addAnnotation(documentID: documentID, annotation: snapshot.record)
        saveDocumentChanges()
    }

    private func updateAnnotationNote(_ record: PDFAnnotationRecord, note: String) {
        guard let document = pdfDocument else { return }
        let annotationID = record.id.uuidString

        for pageIndex in 0..<document.pageCount {
            guard let page = document.page(at: pageIndex) else { continue }
            for annotation in page.annotations where annotation.userName == annotationID {
                annotation.contents = note
            }
        }

        library.updateAnnotationNote(documentID: documentID, annotationID: record.id, note: note)
        saveDocumentChanges()
    }

    private func saveDocumentChanges() {
        guard let document = pdfDocument, let item = documentItem else { return }
        let url = library.fileURL(for: item)
        if !document.write(to: url) {
            errorMessage = "Die PDF-Änderungen konnten nicht gespeichert werden."
            showErrorAlert = true
        }
    }

    private func deleteCurrentDocument() {
        pdfDocument = nil
        pdfViewRef?.document = nil
        library.deleteDocument(documentID: documentID)
        dismiss()
    }
}

private struct PDFKitReaderView: UIViewRepresentable {
    let document: PDFDocument
    let initialPageIndex: Int
    let displayDirection: PDFDisplayDirection
    let useTwoUpMode: Bool
    let onPageChanged: (Int) -> Void
    let onSelectionChanged: (PDFSelection?) -> Void
    let onViewCreated: (PDFView) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onPageChanged: onPageChanged, onSelectionChanged: onSelectionChanged)
    }

    func makeUIView(context: Context) -> PDFView {
        let view = PDFView()
        configure(view, initialPage: initialPageIndex)
        context.coordinator.attach(to: view)
        onViewCreated(view)
        return view
    }

    func updateUIView(_ uiView: PDFView, context: Context) {
        if uiView.document !== document {
            configure(uiView, initialPage: initialPageIndex)
        } else {
            uiView.displayDirection = displayDirection
            uiView.displayMode = useTwoUpMode ? .twoUpContinuous : .singlePageContinuous
        }
        onViewCreated(uiView)
    }

    static func dismantleUIView(_ uiView: PDFView, coordinator: Coordinator) {
        coordinator.detach()
    }

    private func configure(_ view: PDFView, initialPage: Int) {
        view.document = document
        view.autoScales = true
        view.displayDirection = displayDirection
        view.displayMode = useTwoUpMode ? .twoUpContinuous : .singlePageContinuous
        view.displaysAsBook = useTwoUpMode
        view.displaysPageBreaks = true
        view.backgroundColor = .systemBackground
        view.maxScaleFactor = 8
        view.displayBox = .mediaBox
        if let page = document.page(at: initialPage) {
            view.go(to: page)
        }
    }

    final class Coordinator {
        private let onPageChanged: (Int) -> Void
        private let onSelectionChanged: (PDFSelection?) -> Void
        private weak var pdfView: PDFView?
        private var pageObserver: NSObjectProtocol?
        private var selectionObserver: NSObjectProtocol?

        init(
            onPageChanged: @escaping (Int) -> Void,
            onSelectionChanged: @escaping (PDFSelection?) -> Void
        ) {
            self.onPageChanged = onPageChanged
            self.onSelectionChanged = onSelectionChanged
        }

        func attach(to view: PDFView) {
            detach()
            pdfView = view

            pageObserver = NotificationCenter.default.addObserver(
                forName: Notification.Name.PDFViewPageChanged,
                object: view,
                queue: .main
            ) { [weak self] _ in
                guard let self, let doc = view.document, let page = view.currentPage else { return }
                self.onPageChanged(doc.index(for: page))
            }

            selectionObserver = NotificationCenter.default.addObserver(
                forName: Notification.Name.PDFViewSelectionChanged,
                object: view,
                queue: .main
            ) { [weak self] _ in
                self?.onSelectionChanged(view.currentSelection)
            }
        }

        func detach() {
            if let pageObserver {
                NotificationCenter.default.removeObserver(pageObserver)
            }
            if let selectionObserver {
                NotificationCenter.default.removeObserver(selectionObserver)
            }
            pageObserver = nil
            selectionObserver = nil
            pdfView = nil
        }
    }
}

private extension UIColor {
    convenience init?(hex: String) {
        let cleaned = hex.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: "#", with: "")
        guard cleaned.count == 6, let value = Int(cleaned, radix: 16) else { return nil }
        let red = CGFloat((value >> 16) & 0xFF) / 255.0
        let green = CGFloat((value >> 8) & 0xFF) / 255.0
        let blue = CGFloat(value & 0xFF) / 255.0
        self.init(red: red, green: green, blue: blue, alpha: 1.0)
    }

    var hexString: String {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        let rgb = (Int(round(red * 255)) << 16) | (Int(round(green * 255)) << 8) | Int(round(blue * 255))
        return String(format: "#%06X", rgb)
    }
}

private struct ActivityView: UIViewControllerRepresentable {
    let activityItems: [Any]
    let applicationActivities: [UIActivity]? = nil

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: applicationActivities)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
