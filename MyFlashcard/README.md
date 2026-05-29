# MyFlashcard iOS

Native SwiftUI flashcard app with AI chat and grammar hub.

## What was added

- AI chat MVVM flow (`AIChatViewModel`) with intent routing and language-aware behavior.
- Translation-first handling for requests like `Wie sagt man ... auf Englisch?`.
- Offline AI fallback for grammar, improve, analyze, and translation flows.
- Grammar topic recommendations shared from AI chat to Grammar Hub.
- Grammar Hub chapters, search, favorites, completion progress, and expandable cards.
- Local persistence for favorites/completion and recommendations using `UserDefaults`.

## Main files

- `Views/TextAnalysisView.swift`
- `Views/GrammarView.swift`
- `Models/Vocabulary.swift`

## Build

```bash
xcodebuild -project /Users/rezamousavi/Downloads/MyFlashcardOS/MyFlashcard.xcodeproj -scheme MyFlashcardR -configuration Debug -destination 'generic/platform=iOS Simulator' build CODE_SIGNING_ALLOWED=NO
```

## Notes

- Build currently succeeds.
- Existing warnings outside this change may still appear (for example in `SpeechService.swift`).

