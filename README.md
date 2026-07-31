# MyFlashcard iOS

> **Offline-first Lernplattform** für intelligentes Englischlernen mit Spaced Repetition, KI-Unterstützung und Gamification.
>
> Ziel: Eine professionelle Open-Source-Lernapp, die schrittweise zur vollständigen Lernplattform (PDF-Bibliothek, Annotationen, Cross-Platform-Sync) erweitert wird.

---

## Funktionen

| Feature | Status | Beschreibung |
|---------|--------|-------------|
| Flashcards | ✅ | Karten mit SRS-Priorisierung, Flip-Animation |
| Quiz (Multiple Choice) | ✅ | 3 Fragerichtungen, 10 Fragen pro Runde |
| SRS-Review | ✅ | SM-2-Algorithmus (Easy / Good / Hard / Again) |
| Cloze Quiz | ✅ | NLP-basierter Lückentext |
| Dictation | ✅ | Text-to-Speech + Eingabe |
| Grammar | ✅ | 15 Kategorien mit Regeln, Formeln, Beispielen |
| Synonyms | ✅ | Synonyme mit Übersetzungen |
| Text Analysis | ✅ | Wortarten, CEFR-Level, Grammatikprüfung |
| Dictionary Lookup | ✅ | Mehrere Quellen mit Cache |
| AI Chat | ✅ | Mehrere Provider (OpenRouter, Deepseek, Gemini, etc.) |
| Statistiken | ✅ | Streak, XP, Wortstatusverteilung |
| Lernfortschritt in SwiftData | ✅ **NEU** | XP, Streak, Reviews persistent gespeichert |
| Bulk-Import | ✅ | Tab-separierte Eingabe mit Duplikatprüfung |
| Dark Mode | ✅ | System-abhängig |
| Offline First | ✅ | Alle Kernfunktionen ohne Internet |
| PDF-Bibliothek | 🗺️ Phase 4 | Geplant |
| Gamification (vollständig) | 🗺️ Phase 3 | Geplant |
| Tablet-Layout (iPad) | 🗺️ Phase 3 | Geplant |
| Cloud-Synchronisation | 🗺️ Phase 5 | Geplant |

---

## Architektur

```
MyFlashcard/
├── Models/
│   ├── Vocabulary.swift              # Vokabel-Modell, WordStatus, LearningStatusHelper
│   ├── GrammarModels.swift           # GrammarCategory, GrammarRule, GrammarExample
│   ├── QuizModels.swift              # QuestionType, QuizQuestion
│   ├── TextAnalysisModels.swift      # PartOfSpeech, AnalyzedWord, GrammarIssue
│   ├── GrammarRecommendationStore.swift # KI→Grammatik-Empfehlungen (ObservableObject)
│   └── LearningProgress.swift        # ✅ NEU: XP/Streak/Reviews in SwiftData
├── Services/
│   ├── SRSService.swift              # SM-2-Algorithmus (applyReview, dueCards)
│   ├── DataService.swift             # Persistenz, Duplikatprüfung (O(log n))
│   ├── LearningProgressService.swift # ✅ NEU: in LearningProgress.swift
│   ├── SpeechService.swift           # Text-to-Speech (AVFoundation)
│   ├── TextAnalysisService.swift     # NLP (NLTagger, CEFR)
│   ├── GrammarDatabase.swift         # Statische Grammatikregeln
│   ├── LearningAnalyticsService.swift # Vergessenskurve, Accuracy-Trend
│   ├── SemanticSearchService.swift   # NLEmbedding (Cosine-Similarity)
│   ├── AIProviderManager.swift       # KI-Provider-Auswahl
│   ├── AIProviderConfiguration.swift # API-Key-Bootstrap (Keychain)
│   └── KeychainService.swift         # Sicherer Schlüsselspeicher
├── ViewModels/
│   ├── BrowseViewModel.swift         # ✅ NEU (aus ViewModels.swift extrahiert)
│   ├── InputViewModel.swift          # ✅ NEU (aus ViewModels.swift extrahiert)
│   ├── FlashcardViewModel.swift      # ✅ NEU (aus ViewModels.swift extrahiert)
│   └── QuizViewModel.swift           # ✅ NEU (aus ViewModels.swift extrahiert)
├── Views/
│   ├── ContentView.swift             # Tab-Navigation
│   ├── BrowseView.swift              # Vokabelliste + Suche
│   ├── InputView.swift               # Hinzufügen + Bulk-Import
│   ├── FlashcardView.swift           # Karteikarten
│   ├── QuizView.swift                # Multiple Choice
│   ├── SRSReviewView.swift           # SRS-Wiederholung
│   ├── QuizHubView.swift             # Quiz-Auswahl
│   ├── ClozeQuizView.swift           # Lückentext
│   ├── DictationView.swift           # Diktat
│   ├── GrammarView.swift             # Grammatik
│   ├── SynonymsView.swift            # Synonyme
│   ├── TextAnalysisView.swift        # Textanalyse
│   ├── StatsView.swift               # Statistiken
│   └── DictionaryDetailView.swift    # Wörterbuch
└── Config/
    ├── AIProviders.xcconfig          # Build-Settings für AI-Keys
    └── APIKeys.local.xcconfig.example # Template für lokale Keys
```

### Schichten

```
┌─────────────────────────────────────────┐
│  Views (SwiftUI)                        │
│  @Query, @Environment, @Bindable        │
└──────────────┬──────────────────────────┘
               │
┌──────────────▼──────────────────────────┐
│  ViewModels (@Observable)               │
│  Filterlogik, Zustandsverwaltung        │
└──────────────┬──────────────────────────┘
               │
┌──────────────▼──────────────────────────┐
│  Services (Pure Swift)                  │
│  SRS, DataService, Analytics, AI        │
└──────────────┬──────────────────────────┘
               │
┌──────────────▼──────────────────────────┐
│  SwiftData (@Model)                     │
│  Vocabulary, Synonym, LearningProgress  │
└─────────────────────────────────────────┘
```

---

## Technologien

| Bereich | Technologie |
|---------|-------------|
| UI | SwiftUI (iOS 17+) |
| Datenhaltung | SwiftData |
| State Management | @Observable, @Query, @Environment |
| SRS | SM-2 Algorithmus (eigene Implementierung) |
| NLP | NaturalLanguage.framework (Apple) |
| Audio | AVFoundation (Text-to-Speech) |
| Security | Keychain via Security.framework |
| AI | REST-Clients (OpenRouter, Deepseek, Gemini, Groq, Cerebras) |
| Logging | OSLog (structured logging) |

---

## Voraussetzungen

- **Xcode** 15.0+
- **iOS** 17.0+
- **macOS** 14.0+ (für Xcode)
- Swift 5.9+

---

## Installation & Einrichtung

### 1. Repository klonen

```zsh
git clone https://github.com/RM122112/MyFlashcard-iOS.git
cd MyFlashcard-iOS
```

### 2. Projekt öffnen

```zsh
open MyFlashcard/MyFlashcard.xcodeproj
```

### 3. Scheme wählen

In Xcode: `MyFlashcardR` → iOS Simulator → `Cmd + R`

### 4. API-Keys einrichten (optional – nur für KI-Features)

```zsh
cp MyFlashcard/Config/APIKeys.local.xcconfig.example \
   MyFlashcard/Config/APIKeys.local.xcconfig
```

Dann `APIKeys.local.xcconfig` öffnen und eigene Keys eintragen.

> **Hinweis:** `APIKeys.local.xcconfig` ist in `.gitignore` – wird nie ins Repository gepusht.

---

## Build per CLI

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

**SwiftData (SQLite)** mit folgenden Modellen:

| Modell | Beschreibung |
|--------|-------------|
| `Vocabulary` | Vokabeleintrag mit SRS-Feldern, Tags, CEFR-Level |
| `Synonym` | Synonym-Eintrag mit Übersetzungen |
| `LearningProgress` | Täglicher Lernfortschritt (XP, Streak, Reviews) |

---

## Sicherheit

- API-Keys werden ausschließlich im **Keychain** gespeichert (nie in UserDefaults oder Dateien).
- `APIKeys.local.xcconfig` ist `.gitignore`-geschützt.
- Keine sensiblen Daten in der Datenbank unverschlüsselt (SQLite-Encryption in Phase 2 geplant).

---

## Roadmap

| Phase | Inhalt | Status |
|-------|--------|--------|
| Phase 1 | Architektur-Grundlage, Bug-Fixes, Code-Aufteilung | ✅ Abgeschlossen |
| Phase 2 | Domain Layer (Use Cases), Repository Pattern, Fehlerbehandlung | 🔄 Geplant |
| Phase 3 | Vollständige Gamification, Achievements, Tablet-Layout | 🗺️ Geplant |
| Phase 4 | PDF-Bibliothek, Reader, Annotationen, Flashcards aus PDF | 🗺️ Geplant |
| Phase 5 | Backend (Raspberry Pi), REST API, Sync (Android↔iOS) | 🗺️ Geplant |
| Phase 6 | KI-Integration (Ollama, OpenAI, Gemini) | 🗺️ Geplant |

---

## Bekannte Einschränkungen

- ViewModels.swift ist deprecated (wird in nächstem Cleanup entfernt).
- Keine vollständige UI-Testabdeckung (in Phase 2 geplant).
- iPad-Layout noch nicht optimiert.
- SQLite-Datenbank ist nicht verschlüsselt.

---

## Mitwirkende

- [@RM122112](https://github.com/RM122112) – Projektinhaber
- GitHub Copilot – AI-Assistent

---

## Lizenz

Dieses Projekt ist Open Source. Lizenz-Datei folgt in Phase 1 (Abschluss).
