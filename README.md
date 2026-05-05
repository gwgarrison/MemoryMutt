# MemoryMutt

A flashcard app for iOS that uses spaced repetition to help you learn and memorize information efficiently.

## Features

- **Deck Management** - Create and organize flashcard decks with custom colors and icons
- **Spaced Repetition** - SM-2 algorithm optimizes review intervals for better retention
- **Progress Tracking** - Track streaks, cards studied, and mastery progress
- **Clean UI** - Minimalist SwiftUI interface with dark mode support

## Requirements

- iOS 17.0+
- Xcode 15.0+

## Getting Started

### Adding Decks and Cards

#### Creating a New Deck

1. Open the app and navigate to the **Decks** tab
2. Tap the **+** button in the top-right corner
3. Fill in the deck details:
   - **Name** (required) - Give your deck a descriptive name
   - **Description** (optional) - Add notes about what the deck covers
   - **Color** - Choose a color to visually identify the deck
   - **Icon** - Select an icon that represents the deck's content
   - **Tags** (optional) - Add comma-separated tags for organization (e.g., "Spanish, Vocabulary, Chapter 1")
4. Tap **Create** to save the deck

#### Adding Cards to a Deck

1. Navigate to the **Decks** tab and tap on the deck you want to add cards to
2. In the deck detail view, tap the **+** button next to "Cards" or use the menu (⋯) and select **Add Card**
3. Fill in the card details:
   - **Front** (required) - Enter the question or prompt
   - **Back** (required) - Enter the answer
   - **Hint** (optional) - Add a hint to help recall the answer
4. Tap **Add** to save the card
5. Repeat to add more cards

#### Editing Decks and Cards

- **Edit a Deck**: Open the deck, tap the menu (⋯), and select **Edit Deck**
- **Edit a Card**: In the deck detail view, tap on any card to open the editor
- **Delete a Card**: Swipe left on a card in the list, or open the card editor and tap **Delete Card**
- **Delete a Deck**: Open the deck, tap the menu (⋯), and select **Delete Deck**

#### Importing Cards from CSV

You can import flashcards from a CSV file to quickly create a deck with many cards.

1. Navigate to the **Decks** tab
2. Tap the **+** button and select **Import CSV**
3. Configure import settings:
   - **Deck Name** (optional) - Leave empty to use the filename
   - **First row is header** - Enable if your CSV has a header row
4. Tap **Select CSV File** and choose your file
5. The deck will be created with all imported cards

**CSV Format:**

Your CSV file should have the following columns:

| Column | Required | Description |
|--------|----------|-------------|
| front | Yes | The question or prompt |
| back | Yes | The answer |
| hint | No | Optional hint for the card |

**Example CSV file:**
```csv
front,back,hint
"What is 2+2?","4","Basic math"
"Capital of France?","Paris",""
"Hello in Spanish","Hola",
```

**Tips for CSV Import:**
- Use quotes around fields that contain commas or newlines
- The hint column is optional - you can omit it entirely
- Empty rows are automatically skipped
- The importer supports UTF-8 and Latin-1 encoded files

### Studying Cards

1. Go to the **Study** tab to see decks with cards due for review
2. Tap on a deck or press **Start Studying** to begin a session
3. For each card:
   - Read the question on the front
   - Tap **Show Answer** or tap the card to flip it
   - Rate how well you knew the answer:
     - **Again** - Didn't know it (card resets)
     - **Hard** - Struggled to recall (shorter interval)
     - **Good** - Knew it with some effort (normal interval)
     - **Easy** - Knew it instantly (longer interval)
4. Complete the session to see your results

### Understanding Card Status

Cards progress through these stages based on your reviews:

| Status | Description |
|--------|-------------|
| **New** | Never studied |
| **Learning** | Currently being learned |
| **Review** | In regular review rotation |
| **Mastered** | Well-known with long intervals |

### Tips for Effective Learning

- **Study daily** - Consistent practice builds streaks and improves retention
- **Be honest with ratings** - Accurate ratings help the algorithm optimize your reviews
- **Keep cards simple** - One concept per card works best
- **Use hints sparingly** - They're helpful but can become a crutch

## Project Structure

```
MemoryMutt/
├── MemoryMuttApp.swift       # App entry point
├── Models/                    # SwiftData models
│   ├── Deck.swift
│   ├── Card.swift
│   ├── StudySession.swift
│   └── Review.swift
├── Services/                  # Business logic
│   ├── SM2Algorithm.swift     # Spaced repetition
│   ├── StudySessionManager.swift
│   └── StatisticsService.swift
└── Views/                     # SwiftUI views
    ├── MainTabView.swift
    ├── Home/
    ├── Decks/
    ├── Cards/
    ├── Study/
    ├── Statistics/
    └── Settings/
```

## License

MIT License
