# MyFlashcard (iOS)

Offline-first Lernapp fuer intelligentes Englischlernen mit Fokus auf:

`Vokabel -> Erklaerung -> Synonyme -> Beispiele -> Audio -> Flashcard -> Quiz -> Wiederholung`

## Kernfunktionen

- SwiftUI + SwiftData, MVVM-orientierte Struktur
- Spaced Repetition (SM-2) mit Priorisierung schwieriger Woerter
- Quiz-Modi: Multiple Choice, Lueckentext (NLP-basiert), Diktat, SRS-Review
- KI-gestuetzte Textanalyse (offline-first), Grammatik- und Stilhilfen
- **Proxy-API-Anbindung** (OpenAI-kompatibel, optional, Fallback auf lokale Engine)
- **Semantische Suche** mit NLEmbedding (Cosine-Similarity)
- **Erweiterte Lernfortschritt-Analyse** (Vergessenskurve, Accuracy-Trend, Lerngeschwindigkeit)
- **On-Device LLM Infrastruktur** (Core ML-ready, Template-Fallback)
- Dictionary-Lookup mit Cache und Quelle
- Lernfortschritt: Tagesziel, Streak, XP, Wochenuebersicht

## KI-Features

| Feature | Status | Beschreibung |
|---------|--------|-------------|
| Proxy-API | ✅ Aktiv | OpenAI-kompatible API-Anbindung fuer Chat, Grammatik, Uebersetzung |
| Lernanalyse | ✅ Aktiv | Vergessenskurve, Accuracy-Trend, beste Lernzeit, Lerngeschwindigkeit |
| Cloze-NLP | ✅ Aktiv | NLP-basierte Wortauswahl (NLTagger), Smart Hints, Fuzzy Matching |
| Semantische Suche | ✅ Aktiv | NLEmbedding fuer aehnliche Woerter, Multi-Match-Typen |
| On-Device LLM | 🔧 Infrastruktur | Protokoll + Core ML Platzhalter, bereit fuer Phi-3-mini o.ae. |

## Architektur (kompakt)

- `Models/`: Datenmodelle (`Vocabulary`, `Synonym`, Analysemodelle)
- `Services/`: SRS, Sprache (TTS), Textanalyse, Datenimport, **LearningAnalytics**, **SemanticSearch**, **LocalLLM**
- `ViewModels/`: Screen-Logik fuer Browse, Input, Quiz, Flashcards
- `Views/`: SwiftUI-Screens und Lern-Workflows

## Projekt starten

1. In Xcode `MyFlashcard.xcodeproj` oeffnen
2. Scheme `MyFlashcardR` waehlen
3. iOS Simulator auswaehlen
4. Run (`Cmd + R`)

### API-Key konfigurieren (optional)

Fuer die Proxy-API-Anbindung:
- `AI_PROXY_SECRET` als Environment-Variable oder in Info.plist setzen
- Der Key wird sicher im iOS Keychain gespeichert
- Ohne Key funktioniert die App vollstaendig offline

## Build per CLI

```zsh
cd /Users/rezamousavi/StudioProjects/MyFlashcard-iOS/MyFlashcard
xcodebuild -project MyFlashcard.xcodeproj -scheme MyFlashcardR -configuration Debug -destination 'generic/platform=iOS Simulator' build CODE_SIGNING_ALLOWED=NO
```

## Screenshots

Empfohlen fuer GitHub:

- `docs/screenshots/flashcards.png`
- `docs/screenshots/quiz.png`
- `docs/screenshots/stats.png`
- `docs/screenshots/ai-chat.png`
- `docs/screenshots/semantic-search.png`

Wenn der Ordner noch nicht existiert, bitte anlegen und echte App-Screenshots einfuegen.

## Hinweise

- Offline-first bleibt fuer Kernfunktionen erhalten.
- Externe KI/Proxy-Anbindung bleibt optional und als Fallback gedacht.
- Semantische Suche nutzt Apple NLEmbedding (kein Netzwerk noetig).
- On-Device LLM wird aktiviert sobald ein Core ML Modell im Bundle liegt.
