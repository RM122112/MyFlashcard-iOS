import SwiftUI
import SwiftData

struct AppPreviewFile: View {
    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                Text("MyFlashcard Vorschau")
                    .font(.title3.weight(.semibold))
                Text("PDF-Bibliothek, Reader und Lernmodus in einer kompakten Preview.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                HStack(spacing: 8) {
                    previewTag("PDF")
                    previewTag("Quiz")
                    previewTag("SRS")
                }
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Preview")
        }
    }

    private func previewTag(_ title: String) -> some View {
        Text(title)
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color.accentColor.opacity(0.2))
            .clipShape(Capsule())
    }
}

#Preview("App Preview Card") {
    AppPreviewFile()
}

#Preview("ContentView Preview") {
    ContentView()
        .modelContainer(for: [Vocabulary.self, Synonym.self, LearningProgress.self], inMemory: true)
}
