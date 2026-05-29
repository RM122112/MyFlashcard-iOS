import SwiftUI

/// Quiz Hub – wähle Quiz-Modus
struct QuizHubView: View {
    @State private var selectedMode: QuizMode? = nil

    enum QuizMode: String, CaseIterable, Identifiable {
        case multipleChoice = "Multiple Choice"
        case cloze = "Cloze / Fill-in"
        case dictation = "Dictation"
        case srs = "SRS Review"

        var id: String { rawValue }

        var icon: String {
            switch self {
            case .multipleChoice: return "list.bullet.clipboard"
            case .cloze: return "text.badge.checkmark"
            case .dictation: return "waveform.circle"
            case .srs: return "brain.head.profile"
            }
        }

        var description: String {
            switch self {
            case .multipleChoice: return "Choose the correct translation"
            case .cloze: return "Fill in the missing word"
            case .dictation: return "Hear the word and type it"
            case .srs: return "Smart review based on SM-2 algorithm"
            }
        }

        var color: Color {
            switch self {
            case .multipleChoice: return .blue
            case .cloze: return .purple
            case .dictation: return .green
            case .srs: return .orange
            }
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    Text("Choose your learning mode")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding(.top)

                    ForEach(QuizMode.allCases) { mode in
                        NavigationLink(destination: destinationView(for: mode)) {
                            HStack(spacing: 16) {
                                Image(systemName: mode.icon)
                                    .font(.title2)
                                    .foregroundColor(.white)
                                    .frame(width: 50, height: 50)
                                    .background(mode.color)
                                    .cornerRadius(12)
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(mode.rawValue)
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                    Text(mode.description)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                            .background(mode.color.opacity(0.08))
                            .cornerRadius(16)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("📝 Quiz")
        }
    }

    @ViewBuilder
    private func destinationView(for mode: QuizMode) -> some View {
        switch mode {
        case .multipleChoice:
            QuizView()
                .navigationBarTitleDisplayMode(.inline)
        case .cloze:
            ClozeQuizView()
                .navigationTitle("Cloze Quiz")
                .navigationBarTitleDisplayMode(.inline)
        case .dictation:
            DictationView()
                .navigationTitle("Dictation")
                .navigationBarTitleDisplayMode(.inline)
        case .srs:
            SRSReviewView()
                .navigationBarTitleDisplayMode(.inline)
        }
    }
}

