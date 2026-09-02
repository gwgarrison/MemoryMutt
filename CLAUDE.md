# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build & Run

Open in Xcode:
```bash
open MemoryMutt.xcodeproj
```

Or build from command line:
```bash
xcodebuild -scheme MemoryMutt -destination 'platform=iOS Simulator,name=iPhone 16' build
```

Run tests:
```bash
xcodebuild -scheme MemoryMutt -destination 'platform=iOS Simulator,name=iPhone 16' test
```

**Requirements:** macOS with Xcode 15+, iOS 17.0+ simulator or device.

## Architecture

MemoryMutt is a SwiftUI + SwiftData spaced-repetition flashcard app with no external dependencies.

### Data Models (`/MemoryMutt/Models/`)

Four SwiftData `@Model` classes with a strict hierarchy:

```
Deck → Card → Review
Deck → StudySession → Review
```

- **Deck**: Root entity. Has computed properties (`cardsDueCount`, `masteredCardsCount`, etc.) that query its cards.
- **Card**: Tracks spaced repetition state — `easeFactor`, `interval`, `nextReviewDate`, and a `CardStatus` enum (`new → learning → review → mastered`). `isDue` computed property checks `nextReviewDate <= Date()`.
- **StudySession**: Aggregate metrics for one study session. Has a `StudyMode` enum (`flashcard`, `multipleChoice`, `matchGame`).
- **Review**: Atomic record per card rating. Uses `ReviewRating` (`incorrect` = quality 0, `correct` = quality 4).

The SwiftData schema is configured in `MemoryMuttApp.swift` with cascade deletes throughout.

### Services (`/MemoryMutt/Services/`)

- **SM2Algorithm.swift**: Stateless SM-2 implementation. `calculateNextReview()` returns updated easeFactor, interval, nextReviewDate, and status. Min ease factor 1.3, default 2.5. Thresholds: learning <21 days, review <60 days, mastered ≥60 days.
- **StudySessionManager.swift**: `ObservableObject` that owns the active session. Manages card queue, current index, and mode. `startSession()` filters cards by new/review limits; `recordReview()` applies SM2 and persists a `Review` record; `generateChoices()` pulls 3 random distractors from the deck for multiple-choice.
- **StatisticsService.swift**: `@MainActor` class for analytics. Computes streaks, accuracy, study time, and the activity heatmap. All queries go through SwiftData `ModelContext`.
- **CSVImportService.swift**: Auto-detects delimiter (comma, semicolon, tab, pipe), handles quoted/escaped fields, supports UTF-8 and ISO Latin-1. Uses security-scoped resource access.
- **TroubleCardService.swift**: Leech detection. `Card.lapseCount` counts misses on cards that had already been answered correctly; `Card.isTroubleCard` flags a card at 3 lapses, or 1 lapse with <50% accuracy over 4+ reviews (thresholds in `TroubleThresholds`). `completeRescue()` wipes the lapse history and resets easeFactor/interval/status so a rescued card re-graduates instead of staying pinned at the 1.3 ease floor. `backfillLapseCountsIfNeeded()` reconstructs lapse counts from existing `Review` history once, at launch.
- **StarterDeckService.swift**: Loads bundled CSV files from the app bundle. Starter decks: World Capitals (249), US States (50), US Presidents (47), Spanish (500), French (497).

### Views (`/MemoryMutt/Views/`)

Navigation is a `TabView` in `MainTabView.swift` with 5 tabs: Home, Decks, Study, Statistics, Settings.

Key view relationships:
- `RescueRoundView` conducts a Rescue Round over trouble cards (entry points: Home, `DeckDetailView`). Each card must be answered correctly in multiple choice and then in flashcard recall to count as rescued; a miss resets it to step one and offers to add a hint. Rescue answers are logged as `Review` records but skip per-answer SM-2 — scheduling is repaired once via `completeRescue()`. `StudyMode.rescue` is excluded from the normal picker via `StudyMode.selectableModes`.
- `StudySessionView` is the session conductor — it switches between `FlashcardView`, `MultipleChoiceView`, and `MatchGameView` based on the active mode, and shows `StudyCompletionView` when done.
- `DecksView` has grid/list toggle, search, and sort (recent/name/cardCount). Navigates into `DeckDetailView` → `CardEditorView`.
- Views use `@Query` for live SwiftData binding and inject `StudySessionManager` via `@EnvironmentObject`.
