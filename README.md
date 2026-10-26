# MyFlashcard iOS

> **Offline-first Vokabel-App** für Englisch (mit Deutsch und Persisch) mit Spaced Repetition.

---

## Funktionen (5 Tabs)

| Tab | Beschreibung |
|-----|-------------|
| Wörter | Vokabelliste mit Suche und Statusfilter (neu, alt, bekannt, unbekannt) |
| Hinzufügen | Einzelne Wörter, Bulk-Import (Tab-separiert) und JSON-Import mit Duplikatprüfung |
| Karten | Karteikarten mit SRS-Priorisierung und Aussprache |
| Quiz | Multiple Choice und SRS-Wiederholung (SM-2) |
| Statistik | Streak, XP, Tagesziel, Wochenverlauf, Wortstatus |

Alle Daten bleiben lokal auf dem Gerät (SwiftData). Die App braucht kein Internet.

---

## Architektur

```
MyFlashcard/
├── Models/       # Vocabulary, Synonym, LearningProgress, QuizModels, ImportedVocabEntry
├── Services/     # DataService, SRSService, SpeechService, LearningAnalyticsService, VocabJSONImportService
├── ViewModels/   # Browse-, Input-, Flashcard-, QuizViewModel
└── Views/        # ContentView (Tabs), Browse, Input, Flashcard, QuizHub, Quiz, SRSReview, Stats
```

---

## Voraussetzungen

- Xcode 15.0+
- iOS 17.0+

---

## Einrichtung

```zsh
git clone https://github.com/RM122112/MyFlashcard-iOS.git
cd MyFlashcard-iOS
open MyFlashcard/MyFlashcard.xcodeproj
```

In Xcode: Scheme `MyFlashcardR` → iOS Simulator → `Cmd + R`

### Build per CLI

```zsh
cd MyFlashcard
xcodebuild \
  -project MyFlashcard.xcodeproj \
  -scheme MyFlashcardR \
  -configuration Debug \
  -destination 'generic/platform=iOS Simulator' \
  build \
  CODE_SIGNING_ALLOWED=NO
```

---

## Datenbank

SwiftData (SQLite) mit diesen Modellen:

| Modell | Beschreibung |
|--------|-------------|
| `Vocabulary` | Vokabeleintrag mit SRS-Feldern, Tags, CEFR-Level |
| `Synonym` | Bleibt im Schema, damit vorhandene Nutzerdaten erhalten bleiben (keine UI mehr) |
| `LearningProgress` | Täglicher Lernfortschritt (XP, Streak, Reviews) |

---

## Mitwirkende

- [@RM122112](https://github.com/RM122112) – Projektinhaber
- GitHub Copilot – AI-Assistent

---

## Lizenz

Dieses Projekt ist Open Source. Die Lizenzdatei folgt.
