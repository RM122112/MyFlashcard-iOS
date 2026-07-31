import Foundation
import OSLog
import PDFKit
import UIKit

enum PDFSortOption: String, CaseIterable, Identifiable {
    case recentlyOpened = "Zuletzt geöffnet"
    case recentlyAdded = "Zuletzt importiert"
    case title = "Titel (A-Z)"

    var id: String { rawValue }
}

enum PDFAnnotationType: String, Codable, CaseIterable {
    case highlight
    case underline
    case strikethrough
    case note
}

struct PDFAnnotationRecord: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var pageIndex: Int
    var type: PDFAnnotationType
    var colorHex: String
    var selectedText: String
    var note: String?
    var createdAt: Date = Date()
}

struct PDFBookmarkRecord: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var pageIndex: Int
    var title: String
    var createdAt: Date = Date()
}

struct PDFLibraryItem: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var title: String
    var fileName: String
    var pageCount: Int = 0
    var fileSizeBytes: Int64 = 0
    var thumbnailFileName: String? = nil
    var createdAt: Date = Date()
    var updatedAt: Date = Date()
    var lastOpenedAt: Date?
    var lastReadPage: Int = 0
    var isFavorite: Bool = false
    var bookmarks: [PDFBookmarkRecord] = []
    var annotations: [PDFAnnotationRecord] = []

    private enum CodingKeys: String, CodingKey {
        case id
        case title
        case fileName
        case pageCount
        case fileSizeBytes
        case thumbnailFileName
        case createdAt
        case updatedAt
        case lastOpenedAt
        case lastReadPage
        case isFavorite
        case bookmarks
        case annotations
    }

    init(
        id: UUID = UUID(),
        title: String,
        fileName: String,
        pageCount: Int = 0,
        fileSizeBytes: Int64 = 0,
        thumbnailFileName: String? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        lastOpenedAt: Date? = nil,
        lastReadPage: Int = 0,
        isFavorite: Bool = false,
        bookmarks: [PDFBookmarkRecord] = [],
        annotations: [PDFAnnotationRecord] = []
    ) {
        self.id = id
        self.title = title
        self.fileName = fileName
        self.pageCount = pageCount
        self.fileSizeBytes = fileSizeBytes
        self.thumbnailFileName = thumbnailFileName
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.lastOpenedAt = lastOpenedAt
        self.lastReadPage = lastReadPage
        self.isFavorite = isFavorite
        self.bookmarks = bookmarks
        self.annotations = annotations
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        title = try container.decode(String.self, forKey: .title)
        fileName = try container.decode(String.self, forKey: .fileName)
        pageCount = try container.decodeIfPresent(Int.self, forKey: .pageCount) ?? 0
        fileSizeBytes = try container.decodeIfPresent(Int64.self, forKey: .fileSizeBytes) ?? 0
        thumbnailFileName = try container.decodeIfPresent(String.self, forKey: .thumbnailFileName)
        createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt) ?? Date()
        updatedAt = try container.decodeIfPresent(Date.self, forKey: .updatedAt) ?? Date()
        lastOpenedAt = try container.decodeIfPresent(Date.self, forKey: .lastOpenedAt)
        lastReadPage = try container.decodeIfPresent(Int.self, forKey: .lastReadPage) ?? 0
        isFavorite = try container.decodeIfPresent(Bool.self, forKey: .isFavorite) ?? false
        bookmarks = try container.decodeIfPresent([PDFBookmarkRecord].self, forKey: .bookmarks) ?? []
        annotations = try container.decodeIfPresent([PDFAnnotationRecord].self, forKey: .annotations) ?? []
    }
}

private struct PDFLibraryState: Codable {
    var items: [PDFLibraryItem]
}

@MainActor
final class PDFLibraryService: ObservableObject {
    static let shared = PDFLibraryService()

    @Published private(set) var items: [PDFLibraryItem] = []

    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "MyFlashcard", category: "PDFLibrary")
    private let fileManager = FileManager.default
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    private let stateFileName = "library-state.json"
    private let libraryDirectoryName = "PDFLibrary"
    private let thumbnailDirectoryName = "PDFThumbnails"

    private init() {
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        loadState()
    }

    func sortedItems(by option: PDFSortOption) -> [PDFLibraryItem] {
        switch option {
        case .recentlyOpened:
            return items.sorted { lhs, rhs in
                let left = lhs.lastOpenedAt ?? Date.distantPast
                let right = rhs.lastOpenedAt ?? Date.distantPast
                if left == right { return lhs.createdAt > rhs.createdAt }
                return left > right
            }
        case .recentlyAdded:
            return items.sorted { $0.createdAt > $1.createdAt }
        case .title:
            return items.sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
        }
    }

    func item(with id: UUID) -> PDFLibraryItem? {
        items.first { $0.id == id }
    }

    func fileURL(for item: PDFLibraryItem) -> URL {
        libraryDirectoryURL.appendingPathComponent(item.fileName, conformingTo: .pdf)
    }

    func thumbnailURL(for item: PDFLibraryItem) -> URL? {
        guard let fileName = item.thumbnailFileName else { return nil }
        let url = thumbnailDirectoryURL.appendingPathComponent(fileName)
        return fileManager.fileExists(atPath: url.path) ? url : nil
    }

    func documentShareURL(documentID: UUID) -> URL? {
        guard let item = items.first(where: { $0.id == documentID }) else { return nil }
        let url = fileURL(for: item)
        return fileManager.fileExists(atPath: url.path) ? url : nil
    }

    @discardableResult
    func importPDF(from sourceURL: URL) throws -> PDFLibraryItem {
        let hadScopedAccess = sourceURL.startAccessingSecurityScopedResource()
        defer {
            if hadScopedAccess {
                sourceURL.stopAccessingSecurityScopedResource()
            }
        }

        try ensureDirectories()

        let preferredName = sourceURL.deletingPathExtension().lastPathComponent
        let safeBaseName = sanitizeFileName(preferredName.isEmpty ? "Dokument" : preferredName)
        let destinationFileName = uniqueFileName(base: safeBaseName, ext: "pdf")
        let destinationURL = libraryDirectoryURL.appendingPathComponent(destinationFileName)

        do {
            try fileManager.copyItem(at: sourceURL, to: destinationURL)
        } catch {
            logger.error("pdf_import_copy_failed source=\(sourceURL.absoluteString, privacy: .public) error=\(error.localizedDescription, privacy: .public)")
            throw error
        }

        let itemID = UUID()
        let pageCount = PDFDocument(url: destinationURL)?.pageCount ?? 0
        let fileSize = (try? destinationURL.resourceValues(forKeys: [.fileSizeKey]).fileSize).map(Int64.init) ?? 0
        let thumbnailName = generateThumbnail(for: destinationURL, itemID: itemID)

        let item = PDFLibraryItem(
            id: itemID,
            title: safeBaseName,
            fileName: destinationFileName,
            pageCount: pageCount,
            fileSizeBytes: fileSize,
            thumbnailFileName: thumbnailName,
            createdAt: Date(),
            updatedAt: Date(),
            lastOpenedAt: Date()
        )
        items.append(item)
        saveState()
        return item
    }

    func renameDocument(documentID: UUID, newTitle: String) {
        let trimmed = newTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        guard let index = items.firstIndex(where: { $0.id == documentID }) else { return }

        items[index].title = trimmed
        items[index].updatedAt = Date()
        saveState()
    }

    func deleteDocument(documentID: UUID) {
        guard let index = items.firstIndex(where: { $0.id == documentID }) else { return }
        let item = items[index]

        do {
            try fileManager.removeItem(at: fileURL(for: item))
        } catch {
            logger.error("pdf_delete_failed file=\(item.fileName, privacy: .public) error=\(error.localizedDescription, privacy: .public)")
        }
        if let thumbnailName = item.thumbnailFileName {
            let thumbnailURL = thumbnailDirectoryURL.appendingPathComponent(thumbnailName)
            try? fileManager.removeItem(at: thumbnailURL)
        }

        items.remove(at: index)
        saveState()
    }

    func toggleFavorite(documentID: UUID) {
        guard let index = items.firstIndex(where: { $0.id == documentID }) else { return }
        items[index].isFavorite.toggle()
        items[index].updatedAt = Date()
        saveState()
    }

    func updateLastOpenedPage(documentID: UUID, pageIndex: Int) {
        guard let index = items.firstIndex(where: { $0.id == documentID }) else { return }
        guard pageIndex >= 0 else { return }

        items[index].lastReadPage = pageIndex
        items[index].lastOpenedAt = Date()
        items[index].updatedAt = Date()
        saveState()
    }

    func addBookmark(documentID: UUID, pageIndex: Int, title: String? = nil) {
        guard let index = items.firstIndex(where: { $0.id == documentID }) else { return }
        guard pageIndex >= 0 else { return }

        if items[index].bookmarks.contains(where: { $0.pageIndex == pageIndex }) {
            return
        }

        let bookmark = PDFBookmarkRecord(
            pageIndex: pageIndex,
            title: title?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
                ? title!
                : "Seite \(pageIndex + 1)"
        )
        items[index].bookmarks.append(bookmark)
        items[index].bookmarks.sort { $0.pageIndex < $1.pageIndex }
        items[index].updatedAt = Date()
        saveState()
    }

    func removeBookmark(documentID: UUID, bookmarkID: UUID) {
        guard let index = items.firstIndex(where: { $0.id == documentID }) else { return }
        items[index].bookmarks.removeAll { $0.id == bookmarkID }
        items[index].updatedAt = Date()
        saveState()
    }

    func addAnnotation(documentID: UUID, annotation: PDFAnnotationRecord) {
        guard let index = items.firstIndex(where: { $0.id == documentID }) else { return }
        items[index].annotations.append(annotation)
        items[index].updatedAt = Date()
        saveState()
    }

    func updateAnnotationNote(documentID: UUID, annotationID: UUID, note: String) {
        guard let docIndex = items.firstIndex(where: { $0.id == documentID }) else { return }
        guard let annotationIndex = items[docIndex].annotations.firstIndex(where: { $0.id == annotationID }) else { return }
        items[docIndex].annotations[annotationIndex].note = note
        items[docIndex].updatedAt = Date()
        saveState()
    }

    func removeAnnotation(documentID: UUID, annotationID: UUID) {
        guard let index = items.firstIndex(where: { $0.id == documentID }) else { return }
        items[index].annotations.removeAll { $0.id == annotationID }
        items[index].updatedAt = Date()
        saveState()
    }

    func exportAnnotationsText(documentID: UUID) -> String {
        guard let item = item(with: documentID) else { return "Kein Dokument gefunden." }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short

        var lines: [String] = []
        lines.append("Dokument: \(item.title)")
        lines.append("Exportiert: \(formatter.string(from: Date()))")
        lines.append("")

        if item.annotations.isEmpty {
            lines.append("Keine Annotationen vorhanden.")
            return lines.joined(separator: "\n")
        }

        for annotation in item.annotations.sorted(by: { $0.createdAt < $1.createdAt }) {
            lines.append("• Seite \(annotation.pageIndex + 1) – \(annotation.type.rawValue.capitalized)")
            if !annotation.selectedText.isEmpty {
                lines.append("  Text: \(annotation.selectedText)")
            }
            if let note = annotation.note, !note.isEmpty {
                lines.append("  Notiz: \(note)")
            }
            lines.append("  Farbe: \(annotation.colorHex)")
            lines.append("")
        }
        return lines.joined(separator: "\n")
    }

    // MARK: - Private

    private var appSupportDirectoryURL: URL {
        let base = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        return base.appendingPathComponent("MyFlashcard", isDirectory: true)
    }

    private var libraryDirectoryURL: URL {
        appSupportDirectoryURL.appendingPathComponent(libraryDirectoryName, isDirectory: true)
    }

    private var thumbnailDirectoryURL: URL {
        appSupportDirectoryURL.appendingPathComponent(thumbnailDirectoryName, isDirectory: true)
    }

    private var stateFileURL: URL {
        appSupportDirectoryURL.appendingPathComponent(stateFileName)
    }

    private func ensureDirectories() throws {
        if !fileManager.fileExists(atPath: appSupportDirectoryURL.path) {
            try fileManager.createDirectory(at: appSupportDirectoryURL, withIntermediateDirectories: true)
        }
        if !fileManager.fileExists(atPath: libraryDirectoryURL.path) {
            try fileManager.createDirectory(at: libraryDirectoryURL, withIntermediateDirectories: true)
        }
        if !fileManager.fileExists(atPath: thumbnailDirectoryURL.path) {
            try fileManager.createDirectory(at: thumbnailDirectoryURL, withIntermediateDirectories: true)
        }
    }

    private func saveState() {
        do {
            try ensureDirectories()
            let state = PDFLibraryState(items: items)
            let data = try encoder.encode(state)
            try data.write(to: stateFileURL, options: [.atomic])
        } catch {
            logger.error("pdf_state_save_failed error=\(error.localizedDescription, privacy: .public)")
        }
    }

    private func loadState() {
        do {
            try ensureDirectories()
            guard fileManager.fileExists(atPath: stateFileURL.path) else {
                items = []
                return
            }
            let data = try Data(contentsOf: stateFileURL)
            let state = try decoder.decode(PDFLibraryState.self, from: data)
            let migrated = migrateItems(state.items)
            items = migrated
            if migrated != state.items {
                saveState()
            }
        } catch {
            logger.error("pdf_state_load_failed error=\(error.localizedDescription, privacy: .public)")
            items = []
        }
    }

    private func sanitizeFileName(_ name: String) -> String {
        let invalid = CharacterSet(charactersIn: "/\\?%*|\"<>:")
        return name
            .components(separatedBy: invalid)
            .joined(separator: "_")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func uniqueFileName(base: String, ext: String) -> String {
        var candidate = "\(base).\(ext)"
        var counter = 1

        while fileManager.fileExists(atPath: libraryDirectoryURL.appendingPathComponent(candidate).path) {
            candidate = "\(base)-\(counter).\(ext)"
            counter += 1
        }
        return candidate
    }

    private func generateThumbnail(for fileURL: URL, itemID: UUID) -> String? {
        guard let document = PDFDocument(url: fileURL), let firstPage = document.page(at: 0) else {
            return nil
        }
        let image = firstPage.thumbnail(of: CGSize(width: 280, height: 360), for: .mediaBox)
        guard let imageData = image.jpegData(compressionQuality: 0.82) else {
            return nil
        }
        let fileName = "\(itemID.uuidString).jpg"
        let targetURL = thumbnailDirectoryURL.appendingPathComponent(fileName)
        do {
            try imageData.write(to: targetURL, options: [.atomic])
            return fileName
        } catch {
            logger.error("pdf_thumbnail_write_failed file=\(fileURL.lastPathComponent, privacy: .public) error=\(error.localizedDescription, privacy: .public)")
            return nil
        }
    }

    private func migrateItems(_ source: [PDFLibraryItem]) -> [PDFLibraryItem] {
        var changed = false
        let migrated = source.map { item -> PDFLibraryItem in
            let documentURL = fileURL(for: item)
            guard fileManager.fileExists(atPath: documentURL.path) else {
                return item
            }
            let pageCount = item.pageCount > 0 ? item.pageCount : (PDFDocument(url: documentURL)?.pageCount ?? 0)
            let fileSizeBytes = item.fileSizeBytes > 0
                ? item.fileSizeBytes
                : (try? documentURL.resourceValues(forKeys: [.fileSizeKey]).fileSize).map(Int64.init) ?? 0
            let thumbnailName = item.thumbnailFileName ?? generateThumbnail(for: documentURL, itemID: item.id)

            if pageCount != item.pageCount || fileSizeBytes != item.fileSizeBytes || thumbnailName != item.thumbnailFileName {
                changed = true
                return PDFLibraryItem(
                    id: item.id,
                    title: item.title,
                    fileName: item.fileName,
                    pageCount: pageCount,
                    fileSizeBytes: fileSizeBytes,
                    thumbnailFileName: thumbnailName,
                    createdAt: item.createdAt,
                    updatedAt: item.updatedAt,
                    lastOpenedAt: item.lastOpenedAt,
                    lastReadPage: item.lastReadPage,
                    isFavorite: item.isFavorite,
                    bookmarks: item.bookmarks,
                    annotations: item.annotations
                )
            }
            return item
        }
        return changed ? migrated : source
    }
}
