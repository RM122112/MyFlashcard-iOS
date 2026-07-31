# Changelog

Alle wesentlichen Änderungen werden in dieser Datei dokumentiert.

Format basiert auf [Keep a Changelog](https://keepachangelog.com/de/1.0.0/).

---

## [Unreleased] – Lernfortschritt & Datenintegrität

### Geändert

- **`StatsView.swift` nutzt jetzt durchgängig SwiftData-Fortschrittsdaten**
  - Streak, Tagesziel, Reviews heute und Gesamt-XP kommen nun aus `LearningProgress` statt aus veralteten `AppStorage`-Werten.
  - Wochenübersicht basiert auf persistierten Tages-Reviews.
  - Tagesziel-Änderungen werden über `LearningProgressService` gespeichert.

- **`LearningProgressService` erweitert**
  - Neue Methode `setDailyGoal(_:modelContext:)` für zentrale, persistente Tagesziel-Verwaltung.

- **`DataService` Duplikatlogik verbessert**
  - Case-insensitive Duplikatprüfung für Einzel-Insert korrigiert.
  - Bulk-Import erkennt nun auch Dubletten innerhalb desselben Imports.

- **PDF-Löschen direkt im Reader ergänzt**
  - `PDFReaderView` enthält jetzt einen sichtbaren Löschen-Button in der Toolbar.
  - Vor dem Löschen wird ein Bestätigungsdialog angezeigt.

- **PDF-Bibliothek modernisiert**
  - `PDFLibraryService` erweitert um Seitenzahl, Dateigröße und persistente Thumbnail-Vorschau pro Dokument.
  - Bibliothek zeigt nun Karten mit Metadaten und Schnellaktionen (Öffnen, Teilen, Favorisieren, Umbenennen, Löschen).
  - Löschen in der Bibliothek erfolgt jetzt mit Sicherheitsabfrage.

- **Import-/Sharing-Wege erweitert**
  - Mehrfachimport via Dateiauswahl.
  - Import aus Share Sheet / `onOpenURL` sowie Drag & Drop (`dropDestination`).

- **Reader-Aktionsleiste erweitert**
  - Auswahlaktionen direkt nach Textmarkierung: Markieren, Unterstreichen, Durchstreichen, Kopieren, Übersetzen, Suchen, Definieren, Notiz, Teilen.
  - `PDFAnnotationType` um `strikethrough` ergänzt.
  - OCR-Fallback für Textaktionen ergänzt, wenn ein PDF keinen eingebetteten Text liefert.

- **PDF-Rendering stabilisiert**
  - Reader startet standardmäßig im kontinuierlichen Einzelseitenmodus statt zweispaltiger Ansicht.
  - Seitenstatus (`Seite x / n`) wird sichtbar geführt, inkl. robuster Seitenzahlvalidierung beim Laden.

- **Werkzeugleiste auf Reader-Ebene professionalisiert**
  - GoodNotes-inspirierte Top-Toolbar in 4 Bereichen: Werkzeuge, dynamische Eigenschaften, Farbpalette (inkl. Custom/Recent) und Schnellaktionen.
  - Werkzeugsatz erweitert um Füller/Laser (vorbereitet), Eraser-Modi (Strich/Alles), Seitensprung, Reader-Einstellungen und PDF-Teilen direkt im Reader.
  - Persistente Toolbar-Profile für Tool/Farbe/Deckkraft/Strichstärke/Toolbar-Sichtbarkeit sowie Undo/Redo für Annotationen inkl. Wiederherstellung in PDF + Metadaten.

## [Unreleased] – KI-Funktion entfernt

### Geändert

- **KI-Chat vollständig aus der App-Oberfläche entfernt**
  - `ContentView.swift`: KI-Chat-Tab entfernt.
  - `MyFlashcardApp.swift`: KI-Bootstrap beim App-Start entfernt.

## [Unreleased] – Phase 2: PDF-Bibliothek & Reader

### Hinzugefügt

- **`PDFLibraryService.swift`** – Lokaler PDF-Metadaten-Store.
  - Persistiert Dokumente, Favoriten, Sortierung, letzte gelesene Seite, Lesezeichen und Annotationen.
  - Speichert Metadaten als JSON im App-Sandbox-Verzeichnis.

- **`PDFLibraryView.swift`** – Neue PDF-Oberfläche mit:
  - PDF-Import über Dateiauswahl
  - Bibliotheksliste (Sortieren, Favorisieren, Umbenennen, Löschen)
  - Reader-Integration via PDFKit

- **Reader-Features**
  - Zoom und flüssiges Scrollen
  - Zuletzt gelesene Seite (persistiert)
  - Lesezeichen anlegen/löschen
  - Annotationen: Markieren, Unterstreichen, Notiz hinzufügen, bearbeiten, löschen
  - Annotationen als Text exportieren

### Geändert

- **`ContentView.swift`** – Neuer Tab „PDFs“ für den direkten Zugriff auf die lokale Bibliothek.
- **`MyFlashcard.xcodeproj/project.pbxproj`** – Neue PDF-Dateien in Build-Phasen eingebunden.

## [Unreleased] – Phase 1: Architektur-Grundlage

### Hinzugefügt

- **`LearningProgress.swift`** – Neues SwiftData-Modell für täglichen Lernfortschritt.
  - Speichert: `reviewsToday`, `xpToday`, `totalXP`, `currentStreak`, `longestStreak`, `dailyGoal`, `studyTimeSecondsToday`.
  - Ersetzt UserDefaults-basierte Streak/XP-Persistenz vollständig.
  - Einmalige Migration von vorhandenen UserDefaults-Werten beim App-Start.

- **`LearningProgressService`** – Service für Fortschritts-Persistenz und -Abfrage.
  - `todayProgress(modelContext:)` – Gibt/erstellt den heutigen Eintrag.
  - `recordReview(xpGained:modelContext:)` – Zeichnet ein Review auf.
  - `recentHistory(days:modelContext:)` – Letzte N Tage für Statistiken.
  - `migrateFromUserDefaultsIfNeeded(modelContext:)` – Einmalige Migration.

- **`BrowseViewModel.swift`** – Eigenständige Datei (aus `ViewModels.swift` extrahiert).
- **`InputViewModel.swift`** – Eigenständige Datei mit vollem Error Handling.
- **`FlashcardViewModel.swift`** – Eigenständige Datei mit `progress`-Computed-Property.
- **`QuizViewModel.swift`** – Eigenständige Datei mit `scorePercent`-Computed-Property.

- **`GrammarModels.swift`** – `GrammarCategory`, `GrammarRule`, `GrammarExample` (aus `Vocabulary.swift` extrahiert).
- **`QuizModels.swift`** – `QuestionType`, `QuizQuestion` (aus `Vocabulary.swift` extrahiert).
- **`TextAnalysisModels.swift`** – `PartOfSpeech`, `AnalyzedWord`, `IssueType`, `GrammarIssue`, `TextAnalysisResult` (aus `Vocabulary.swift` extrahiert).
- **`GrammarRecommendationStore.swift`** – Eigenständige Datei (aus `Vocabulary.swift` extrahiert).

### Geändert

- **`DataService.wordExists()`** – Von O(n) auf O(log n) optimiert.
  - **Vorher:** Alle Vokabeln werden geladen, Swift-Filter läuft über Array.
  - **Nachher:** `FetchDescriptor` mit `#Predicate` + `fetchLimit = 1` direkt auf SQLite.

- **`DataService.bulkImportWithDuplicateCheck()`** – Optimiert.
  - Lädt vorhandene Wörter einmalig als `Set<String>` statt N Einzelabfragen.

- **`SRSService.applyReview()`** – Signatur erweitert um `modelContext: ModelContext?`.
  - Ruft `LearningProgressService.recordReview()` auf wenn Context vorhanden.
  - Vollständig rückwärtskompatibel (Default: `nil`).

- **`SRSService`** – Import auf `SwiftData` aktualisiert.
  - Legacy `updateLearningProgress()` (UserDefaults) **entfernt**.
  - `ProgressKeys` Enum **entfernt**.

- **`MyFlashcardApp`** – Schema um `LearningProgress.self` erweitert.
  - Migration-Task beim App-Start eingefügt.

- **`Vocabulary.swift`** – Auf 175 Zeilen reduziert (vorher 528 Zeilen).
  - Enthält jetzt nur: `WordStatus`, `LearningStatusHelper`, `Vocabulary`, `Synonym`, `ParsedEntry`, `ParsedSynonymEntry`.
  - `import Combine` entfernt (nicht benötigt).

- **`ViewModels.swift`** – Deprecated. Enthält nur noch einen Hinweiskommentar.

- **Alle ViewModels** – `try? modelContext.save()` durch `do/catch` mit `print`-Logging ersetzt.
- **`InputViewModel`** – `save(modelContext:)` gibt bei SwiftData-Fehler `false` zurück statt stillschweigend zu scheitern.

### Behoben

- **Bug:** `DataService.wordExists()` lud alle Vokabeln für einen einfachen Duplikat-Check (O(n)).
- **Bug:** `SRSService.updateLearningProgress()` war eine statische Methode mit UserDefaults-Zustand ohne Testbarkeit.
- **Bug:** `Vocabulary.swift` enthielt 5 unzusammenhängende Typen (Grammatik, Quiz, TextAnalysis, etc.) – verletzt Single Responsibility.
- **Bug:** Alle ViewModels in einer Datei (`ViewModels.swift`) – schwer navigierbar, keine klare Verantwortung.
- **Bug:** `try? modelContext.save()` in allen ViewModels unterdrückte Fehler stillschweigend.
- **Bug:** `import Combine` in `Vocabulary.swift` ohne Nutzung.

### Technische Schulden verringert

- God-File `Vocabulary.swift` (528 Zeilen) in 5 fokussierte Dateien aufgeteilt.
- God-File `ViewModels.swift` in 4 fokussierte ViewModels aufgeteilt.
- Streak/XP von UserDefaults in SwiftData migriert (ermöglicht zukünftigen Cloud-Sync).
- Strukturiertes Logging via `OSLog` in `DataService` eingeführt.
