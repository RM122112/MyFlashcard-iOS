# MyFlashcard – Technische Dokumentation (iOS)

Stand: 2026-05-27  
Plattform: iOS (SwiftUI + SwiftData, 100% offline)

---

## 1) App-Ueberblick

`MyFlashcard` ist eine Offline-Lernapp fuer Vokabeln, Grammatik und Textanalyse mit Fokus auf:

- Vokabeltraining (Karten, Quiz, Synonyme)
- Lernpsychologie (SRS / spaced repetition)
- Sprachunterstuetzung (EN/DE/FA, inklusive RTL fuer Persisch)
- Aussprache (TTS mit US-Englisch)
- Lokale Analyse ohne Cloud

### Hauptbereiche (Tabs)

1. `Browse` – Alle Vokabeln durchsuchen und loeschen
2. `Add` – Einzel- und Bulk-Import
3. `Cards` – Karteikarten/Flip-Lernen
4. `Quiz` – Quiz-Hub (Multiple Choice, Cloze, Diktat, SRS)
5. `Synonyms` – Synonym-Saetze und Import
6. `Analyze` – Lokale Textanalyse (POS, Grammatik-/Strukturhinweise)
7. `Grammar` – Offline-Grammatikdatenbank
8. `Stats` – Lernstatistiken, Streak, SRS-Uebersicht

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

### Persistenz

- SwiftData mit `Vocabulary` + `Synonym`
- App-Start in `MyFlashcardApp.swift`
- Fallback auf In-Memory-Container bei Persistenz-Ladefehlern

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

- `quizCard(_:)` – UI fuer Cloze-Aufgabe
- `clozeText(_:)` – Lueckentext-Generierung
- `generateQuestions()`
- `checkAnswer(_:)`
- `next()`

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

## `SynonymsView`

- `deleteItems(offsets:)`
- `parseText()`
- `importEntries()`

### `SynonymTextParser` (im View-File)

- `parseText(_:)` – Synonym-Bulkparser
- `parseLine(_:)` – Zeilenparser

## `TextAnalysisView`

- `analyzeText()` – Analyse starten
- `clearAll()` – Eingabe/Ergebnisse zuruecksetzen
- `colorFor(_:)` (zweimal in getrennten UI-Komponenten) – POS/Issue-Farbmapping
- `sizeThatFits(...)`, `placeSubviews(...)` – Custom-Layout fuer Flow-Elemente

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
- Lokale NLP-Verarbeitung (NaturalLanguage)
- TTS lokal via `AVFoundation`

---

## 9) Start- und Laufhinweise

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

## 10) Dateireferenz (Schnellindex)

- App-Entry: `MyFlashcard/MyFlashcardApp.swift`
- Models: `MyFlashcard/Models/Vocabulary.swift`
- Services: `MyFlashcard/Services/*.swift`
- ViewModels: `MyFlashcard/ViewModels/ViewModels.swift`
- Views: `MyFlashcard/Views/*.swift`

---

## 11) Empfohlene naechste Doku-Schritte

- API-aehnliche Kurzdocs direkt per `///` an allen oeffentlichen Funktionen ergaenzen
- Changelog-Datei (`CHANGELOG.md`) fuer neue Features
- Nutzerhandbuch (separat, nicht-technisch) fuer Endanwender

