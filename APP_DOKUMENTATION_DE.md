# MyFlashcard – Technische Dokumentation (iOS)

Stand: 2026-06-14  
Plattform: iOS (SwiftUI + SwiftData, Offline-first mit optionaler KI-API)

---

## 1) App-Ueberblick

`MyFlashcard` ist eine Offline-Lernapp fuer Vokabeln, Grammatik und Textanalyse mit Fokus auf:

- Vokabeltraining (Karten, Quiz, Synonyme)
- Lernpsychologie (SRS / spaced repetition)
- Sprachunterstuetzung (EN/DE/FA, inklusive RTL fuer Persisch)
- Aussprache (TTS mit US-Englisch)
- Lokale Analyse ohne Cloud

### Hauptbereiche (Tabs)

1. `Wörter` – Alle Vokabeln durchsuchen, semantische Suche, loeschen
2. `Hinzufügen` – Einzel- und Bulk-Import
3. `Karten` – Karteikarten/Flip-Lernen
4. `Quiz` – Quiz-Hub (Multiple Choice, Cloze mit NLP, Diktat, SRS)
5. `KI-Chat` – KI-gestuetzter Chat (Grammatik, Uebersetzung, Analyse, Wortschatz)
6. `Grammatik` – Offline-Grammatikdatenbank
7. `Statistik` – Lernstatistiken, Streak, Vergessenskurve, Lerngeschwindigkeit

---

## 2) Architektur

### UI-Layer

- SwiftUI Views unter `MyFlashcard/Views/`
- `ContentView` verwaltet Tab-Navigation
- Teilweise helper/private Funktionen direkt in den Views

### Domain/Data-Layer

- SwiftData-Modelle in `MyFlashcard/Models/`
- Services in `MyFlashcard/Services/`
- klassische ViewModels in `MyFlashcard/ViewModels/ViewModels.swift`
- KI-Chat ViewModel direkt in `TextAnalysisView.swift` (AIChatViewModel)

### Persistenz

- SwiftData mit `Vocabulary` + `Synonym`
- App-Start in `MyFlashcardApp.swift`
- Fallback auf In-Memory-Container bei Persistenz-Ladefehlern
- Dictionary-Cache in UserDefaults (TTL 7 Tage)
- API-Key in iOS Keychain (KeychainService)

---

## 3) Datenmodelle

## `Vocabulary` (`Models/Vocabulary.swift`)

Speichert Kerninfos pro Vokabel:

- Sprachfelder: `englishWord`, `german`, `persian`, `exampleSentence`
- Lerntracking: `timesReviewed`, `timesCorrect`, `lastReviewedAt`, `isLearned`
- SRS: `srsInterval`, `srsEaseFactor`, `srsRepetitions`, `srsNextReview`
- Struktur/Metadaten: `tags`, `cefrLevel`, `contextSentences`, `createdAt`

Hilfs-Properties:

- `accuracy`: Trefferquote in Prozent
- `tagList`: CSV -> Array
- `contextSentenceList`: Semikolon-Liste -> Array

## `Synonym` (`Models/Vocabulary.swift`)

- `mainWord`, `synonyms`, Uebersetzungen, Beispielsatz
- `displayWord`: kombiniertes Anzeigeformat, z. B. `fix (repair, mend)`

## Weitere Structs/Enums (`Models/Vocabulary.swift`)

- Import: `ParsedEntry`, `ParsedSynonymEntry`
- Quiz: `QuestionType`, `QuizQuestion`
- Grammar: `GrammarCategory`, `GrammarRule`, `GrammarExample`
- Analyse: `AnalyzedWord`, `PartOfSpeech`, `TextAnalysisResult`, `GrammarIssue`, `IssueType`

---

## 4) Services und Funktionen

## `DataService` (`Services/DataService.swift`)

Zentrale Datenoperationen fuer Seed, Insert und Dublettenkontrolle.

- `initializeSampleDataIfNeeded(modelContext:)`  
  Legt Beispielvokabeln an, wenn Datenbank leer ist.

- `wordExists(_:in:)`  
  Prueft, ob ein englisches Wort schon existiert (case-insensitive, getrimmt).

- `insertWithDuplicateCheck(...)`  
  Fuegt Eintrag ein oder liefert Dublettenstatus (`InsertResult`).

- `bulkImportWithDuplicateCheck(entries:context:)`  
  Importiert mehrere Eintraege, zaehlt Erfolge und Dubletten (`BulkImportResult`).

### `TextParser` (im selben File)

- `parseText(_:)`  
  Zerlegt Bulk-Text in `ParsedEntry`-Objekte.

- `parseLine(_:)` (private)  
  Unterstuetzt mehrere Formate (Tabs, Mehrfachspaces, persische Unicode-Muster, nummerierte Listen).

## `SpeechService` (`Services/SpeechService.swift`)

Offline TTS mit `AVSpeechSynthesizer`.

- `configureAudioSession()` (private)  
  Konfiguriert AudioSession fuer Sprachwiedergabe.

- `speak(_:rate:)`  
  Spricht Text mit US-Voice (`en-US`).

- `speakSlow(_:)`  
  Komfortfunktion fuer langsamere Aussprache.

- `stop()`  
  Stoppt laufende Ausgabe.

- Delegate-Callbacks (`didStart`, `didFinish`, `didCancel`)  
  Aktualisieren `isSpeaking` fuer UI-Status.

## `SRSService` (`Services/SRSService.swift`)

Implementiert SM-2 Spaced Repetition.

- `Quality.fromQuizResult(isCorrect:wasEasy:)`  
  Mappt Quizergebnis auf SRS-Qualitaet.

- `calculateNextReview(...)`  
  Berechnet naechstes Intervall, Ease-Factor, Wiederholungszahl.

- `applyReview(to:quality:)`  
  Schreibt SRS-Ergebnis in `Vocabulary` (inkl. `timesReviewed`/`timesCorrect`).

- `dueCards(from:)`  
  Filtert heute/faellige Karten, sortiert nach Dringlichkeit.

- `difficultyLabel(easeFactor:)`  
  Liefert UI-Label zur Schwierigkeit.

## `TextAnalysisService` (`Services/TextAnalysisService.swift`)

Lokale NLP-Analyse via `NaturalLanguage` + (iOS) `UITextChecker`.

- `analyzeText(_:)`  
  Hauptpipeline: Tokenisierung, POS, Lemmata, Checks, Statistiken.

- `detectLanguage(_:)`  
  Spracherkennung (z. B. English/German/Persian).

- `getLemma(for:in:)` (private)  
  Bestimmt Grundform eines Tokens.

- `mapTagToPartOfSpeech(_:)` (private)  
  Mapping von `NLTag` auf App-Enum.

- `countSentences(_:)` (private)  
  Zaehlt Saetze mit `NLTokenizer`.

- `checkSpelling(_:language:)` (private)  
  Rechtschreibcheck + Vorschlaege.

- `checkGrammarIssues(_:)` (private)  
  Heuristische Grammatikregeln (a/an, Wiederholungen, typische Fehler).

- `checkSentenceStructure(_:)` (private)  
  Strukturpruefung (Grossschreibung, Satzende, Laenge, Leerzeichen, Interpunktion).

- `checkImprovementSuggestions(_:words:)` (private)  
  Stil-/Verbesserungshinweise (Wortwahl, Passive-Overuse, Satzanfangsvarianz).

## `GrammarDatabase` (`Services/GrammarDatabase.swift`)

- `allRules`  
  Offline-Regelsammlung (`GrammarRule`) mit Kategorien, Formeln, Beispielen, Lerntipps.

## `LearningAnalyticsService` (`Services/LearningAnalyticsService.swift`)

Erweiterte Lernfortschritt-Analyse auf Basis vorhandener SRS-Daten.

- `accuracyTrend(for:days:)`  
  Taeglich aggregierte Genauigkeit der letzten N Tage.

- `retentionCurve(for:)`  
  Vergessenskurve: Behaltenrate nach SRS-Intervall-Bucketen (1d, 2-3d, 4-7d, etc.).

- `velocity(for:)`  
  Lerngeschwindigkeit: Woerter/Tag, geschaetzte Tage bis alle gemeistert, Mastery-Quote.

- `weakestTags(for:limit:)`  
  Schwaechste Kategorien/Tags nach durchschnittlicher Trefferquote.

- `activityByHour(for:)`  
  Lernaktivitaet pro Stunde (Anzahl Reviews + Genauigkeit).

- `bestLearningHour(for:)`  
  Stunde mit hoechster Accuracy (min. 3 Reviews).

## `SemanticSearchService` (`Services/SemanticSearchService.swift`)

Semantische Suche mit Apple NLEmbedding (offline, kein Netzwerk).

- `search(query:in:limit:)`  
  Findet semantisch aehnliche Vokabeln via Cosine-Similarity.  
  Match-Typen: Exakt, Semantisch, Uebersetzung, Kontext.

- `findSimilarWords(to:limit:)`  
  Aehnliche Woerter direkt aus dem Embedding (nicht aus Vokabelliste).

- Automatischer Fallback auf String-Matching falls kein Embedding verfuegbar.

## `LocalLLMService` (`Services/LocalLLMService.swift`)

Infrastruktur fuer zukuenftiges On-Device LLM (Core ML / GGML).

- `LocalLLMProvider` – Protokoll fuer austauschbare Backends
- `TemplateBasedLLM` – Aktueller regelbasierter Fallback
- `CoreMLLLMProvider` – Platzhalter fuer Core ML Modelle (Phi-3-mini)
- `LocalLLMService.shared` – Zentraler Service mit automatischer Backend-Wahl
- `generate(prompt:maxTokens:)` – Generiert Antwort mit bestem verfuegbarem Backend

## `KeychainService` (`Services/KeychainService.swift`)

Sichere Speicherung von API-Keys im iOS Keychain.

- `bootstrapIfNeeded(key:fallbackSecret:)` – Initiales Setzen aus Environment/Info.plist
- `save(_:for:)` – Wert sicher speichern
- `read(for:)` – Wert lesen

---

## 5) ViewModels und Funktionen

## `BrowseViewModel`

- `deleteVocabulary(_:modelContext:)` – loescht Eintrag.
- `filteredVocabulary(_:)` – Suche + Sortierung.

## `InputViewModel`

- `toggleMode()` – Wechsel Einzel/Bulk-Modus.
- `setBulkText(_:)` – setzt Text und parsed Vorschau.
- `loadForEditing(_:)` – befuellt Formular fuer Edit.
- `importBulk(modelContext:)` – Bulk-Speichern.
- `save(modelContext:)` – Validierung + Save (neu/Update).
- `clearForm()` – Formular-Reset.

## `FlashcardViewModel`

- `loadCards(_:)` – Karten laden/shufflen.
- `shuffleCards()` – Reihenfolge neu.
- `flipCard()` – Vorder-/Rueckseite wechseln.
- `nextCard()` – naechste Karte.
- `previousCard()` – vorherige Karte.
- `markAsLearned(isCorrect:modelContext:)` – Fortschritt schreiben.

## `QuizViewModel`

- `startNewQuiz(vocabulary:)` – neue Session erstellen.
- `createQuestion(...)` (private) – Frage + Distraktoren bauen.
- `selectAnswer(_:modelContext:)` – Antwortwerten + Progress update.
- `nextQuestion()` – Navigation / Finish.

---

## 6) Views und Funktionen

## `ContentView`

- Root-Tab-Navigation und Initialisierung von Sample-Daten.

## `BrowseView`

- `deleteItems(offsets:)` – Swipe-Loeschlogik.
- **Semantische Suche** – Toggle (🧠-Button) aktiviert NLEmbedding-basierte Suche.
- Zeigt Match-Typ (Exakt/Semantisch/Uebersetzung) und Aehnlichkeits-Score an.

## `InputView`

- `parseText()` – Bulk-Text in Vorschau parsen.
- `importEntries()` – Bulk-Import ausfuehren.

## `FlashcardView`

- `loadCards()`, `shuffleCards()`, `previousCard()`, `nextCard()`
- `markAsLearned(_:)` – Antwort als richtig/falsch markieren

## `QuizHubView`

- `destinationView(for:)` – Routing zu Quiz-Untermodi.

## `QuizView` (Multiple Choice)

- `startNewQuiz()`
- `generateQuestions()`
- `handleAnswer(_:)`
- `nextQuestion()`
- `optionBackground(_:)` – visuelles Feedback

## `ClozeQuizView`

- **NLP-basierte Lueckentext-Generierung** mit `NLTagger`
- `ClozeQuestion.generate(for:allVocabulary:)` – Waehlt Inhaltswort per POS-Tagging
- Priorisiert Zielwort > Nomen > Verben > Adjektive
- `quizCard(_:)` – UI mit Smart Hints (Wortart, Anfangsbuchstabe, Laenge)
- `checkAnswer(_:)` – Fuzzy Matching (Levenshtein ≤ 2 → "Fast richtig")
- Differenzierte SRS-Quality: Hint genutzt → `correct_difficult`
- SRS-priorisierte Fragenauswahl (schwierigste Woerter zuerst)

## `DictationView`

- `dictationCard(_:)` – Diktat-UI
- `checkAnswer(_:)`
- `nextCard()`

## `SRSReviewView`

- `cardArea(card:)` – Lernkarte + Flip + Bewertung
- `cardFace(content:color:)` – Karten-Layout
- `qualityButtons(card:)` – Recall-Bewertung
- `qualityColor(_:)` – Bewertungsfarbe
- `upcomingReviews()` – kommende Faelligkeiten
- `loadDueCards()` – Session-Aufbau
- `applyQuality(_:to:)` – SRS-Update pro Antwort

## `StatsView`

- `statCard(title:value:icon:color:)` – KPI-Karte
- `upcomingReviewData()` – Datengrundlage fuer SRS-Chart
- **Accuracy-Trend-Chart** – Liniendiagramm der letzten 7 Tage
- **Vergessenskurve-Chart** – Retention-Rate nach Intervall-Bucketen
- **Lerngeschwindigkeit-Dashboard** – Woerter/Tag, ETA, beste Lernzeit

## `SynonymsView`

- `deleteItems(offsets:)`
- `parseText()`
- `importEntries()`

### `SynonymTextParser` (im View-File)

- `parseText(_:)` – Synonym-Bulkparser
- `parseLine(_:)` – Zeilenparser

## `TextAnalysisView` / `AIChatView`

- KI-Chat mit 7 Modi: Chat, Grammatik, Stil verbessern, Analysieren, Uebersetzen, Professionell, Wortschatz
- `AIIntentRouter` – Automatische Erkennung der Benutzerabsicht
- `AIChatRepository` – Orchestriert Inferenz-Pipeline:
  1. **Proxy-API** (OpenAI-kompatibel, wenn API-Key vorhanden + online)
  2. **Local LLM** (wenn Core ML Modell verfuegbar)
  3. **On-Device Engine** (regelbasiert, immer offline verfuegbar)
- `DictionaryRepository` – Woerterbuch-Lookup mit Cache (TTL 7 Tage)
- `GrammarTopicRecommender` – Empfiehlt passende Grammatikthemen
- Zeigt genutzten Inference-Path im Chat an (On-device / Proxy-API / Local LLM)

## `GrammarView`

- Nutzt `GrammarDatabase.allRules`, Filterung nach Kategorie, Suche, Expand/Collapse fuer Details.

---

## 7) Lernlogik (didaktisch)

- **Spaced Repetition (SM-2):** steigende Wiederholungsintervalle nach Antwortqualitaet
- **Aktive Abrufuebung:** Karten, Quiz, Cloze, Diktat
- **Mehrkanal-Lernen:** Lesen + Hoeren (TTS) + Schreiben (Diktat/Cloze)
- **Fehlerfokus:** Stats + SRS zeigen schwierige Karten priorisiert

---

## 8) Offline- und Sicherheitseigenschaften

- Keine Cloud-Abhaengigkeit fuer Kernfunktionen
- Lokale Persistenz via SwiftData
- Lokale NLP-Verarbeitung (NaturalLanguage + NLEmbedding)
- TTS lokal via `AVFoundation`
- API-Keys sicher im iOS Keychain (nicht im Klartext)
- Proxy-API optional: App funktioniert vollstaendig ohne Netzwerk

---

## 9) KI-Architektur

### Inferenz-Pipeline (Priorisierung)

```
1. Proxy-API (OpenAI-kompatibel) → wenn API-Key + online
2. Local LLM (Core ML)           → wenn Modell im Bundle
3. On-Device Engine (Regelbasiert)→ immer verfuegbar
```

### Semantische Suche

- Nutzt `NLEmbedding.wordEmbedding(for: .english)` (Apple-integriert)
- Cosine-Similarity fuer Wortaehnlichkeit
- Kein Netzwerk noetig, ca. 200MB on-device Embedding

### Lernanalyse

- Basiert auf vorhandenen SRS-Daten (keine zusaetzliche Datenerfassung)
- Berechnet Vergessenskurve, Accuracy-Trend, Lerngeschwindigkeit
- Identifiziert optimale Lernzeiten und schwache Kategorien

---

## 10) Start- und Laufhinweise

### Build (Beispiel Simulator)

```zsh
cd /Users/rezamousavi/Downloads/MyFlashcard
xcodebuild -project MyFlashcard.xcodeproj -scheme MyFlashcardR -configuration Debug -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.5' build
```

### SwiftData-LoadIssueModelContainer (bekannter Fehlerfall)

Falls alte lokale Daten nicht zum aktuellen Schema passen:

1. App startet jetzt mit In-Memory-Fallback (kein Crash).
2. Optional Simulator-App loeschen und neu starten, um Store frisch zu erstellen.

---

## 11) Dateireferenz (Schnellindex)

- App-Entry: `MyFlashcard/MyFlashcardApp.swift`
- Models: `MyFlashcard/Models/Vocabulary.swift`
- Services:
  - `DataService.swift` – Datenimport, Dublettenkontrolle
  - `SpeechService.swift` – Text-to-Speech
  - `SRSService.swift` – Spaced Repetition (SM-2)
  - `TextAnalysisService.swift` – Offline-NLP-Analyse
  - `GrammarDatabase.swift` – Grammatik-Regelsammlung
  - `KeychainService.swift` – Sichere Key-Speicherung
  - `LearningAnalyticsService.swift` – Erweiterte Lernanalyse
  - `SemanticSearchService.swift` – Semantische Suche (NLEmbedding)
  - `LocalLLMService.swift` – On-Device LLM Infrastruktur
- ViewModels: `MyFlashcard/ViewModels/ViewModels.swift`
- Views: `MyFlashcard/Views/*.swift`

---

## 12) Empfohlene naechste Doku-Schritte

- API-aehnliche Kurzdocs direkt per `///` an allen oeffentlichen Funktionen ergaenzen
- Changelog-Datei (`CHANGELOG.md`) fuer neue Features
- Nutzerhandbuch (separat, nicht-technisch) fuer Endanwender

---

## 13) Changelog (letzte Aenderungen)

### 2026-06-14

- **Proxy-API angebunden** – OpenAI-kompatible API mit modus-spezifischen System-Prompts
- **Lernfortschritt-Analyse erweitert** – Vergessenskurve, Accuracy-Trend, Lerngeschwindigkeit, beste Lernzeit
- **Cloze-Generierung verbessert** – NLP-basierte Wortauswahl, Smart Hints, Fuzzy Matching
- **Semantische Suche** – NLEmbedding in BrowseView mit Match-Typ-Anzeige
- **On-Device LLM Infrastruktur** – Protokoll, Core ML Platzhalter, Template-Fallback

