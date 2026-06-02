# MyFlashcard (iOS)

Offline-first Lernapp fuer intelligentes Englischlernen mit Fokus auf:

`Vokabel -> Erklaerung -> Synonyme -> Beispiele -> Audio -> Flashcard -> Quiz -> Wiederholung`

## Kernfunktionen

- SwiftUI + SwiftData, MVVM-orientierte Struktur
- Spaced Repetition (SM-2) mit Priorisierung schwieriger Woerter
- Quiz-Modi: Multiple Choice, Lueckentext, Diktat, SRS-Review
- KI-gestuetzte Textanalyse (offline-first), Grammatik- und Stilhilfen
- Dictionary-Lookup mit Cache und Quelle
- Lernfortschritt: Tagesziel, Streak, XP, Wochenuebersicht

## Architektur (kompakt)

- `Models/`: Datenmodelle (`Vocabulary`, `Synonym`, Analysemodelle)
- `Services/`: SRS, Sprache (TTS), Textanalyse, Datenimport
- `ViewModels/`: Screen-Logik fuer Browse, Input, Quiz, Flashcards
- `Views/`: SwiftUI-Screens und Lern-Workflows

## Projekt starten

1. In Xcode `MyFlashcard.xcodeproj` oeffnen
2. Scheme `MyFlashcardR` waehlen
3. iOS Simulator auswaehlen
4. Run (`Cmd + R`)

## Build per CLI

```zsh
cd /Users/rezamousavi/Downloads/learning
xcodebuild -project MyFlashcard.xcodeproj -scheme MyFlashcardR -configuration Debug -destination 'generic/platform=iOS Simulator' build CODE_SIGNING_ALLOWED=NO
```

## Screenshots

Empfohlen fuer GitHub:

- `docs/screenshots/flashcards.png`
- `docs/screenshots/quiz.png`
- `docs/screenshots/stats.png`
- `docs/screenshots/ai-chat.png`

Wenn der Ordner noch nicht existiert, bitte anlegen und echte App-Screenshots einfuegen.

## Hinweise

- Offline-first bleibt fuer Kernfunktionen erhalten.
- Externe KI/Proxy-Anbindung bleibt optional und als Fallback gedacht.

