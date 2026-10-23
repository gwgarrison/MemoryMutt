#if DEBUG
import Foundation
import SwiftData

/// Demo content for App Store screenshot runs.
///
/// A fresh install has an empty database, which makes for empty screenshots. When the
/// app is launched with `-ScreenshotMode`, `MemoryMuttApp` swaps in an in-memory store
/// and seeds it here, so a capture run always sees the same decks, streak, and history.
/// The whole file is `#if DEBUG`, so none of it ships in a Release build, and the
/// in-memory store means a run can never touch real user data.
enum ScreenshotDemoData {

    /// Passed by the UI test via `app.launchArguments`.
    static let launchArgument = "-ScreenshotMode"

    static var isActive: Bool {
        ProcessInfo.processInfo.arguments.contains(launchArgument)
    }

    /// Days of unbroken study history to fabricate. Drives the streak and the heatmap.
    private static let streakDays = 12
    /// Target overall accuracy. Reviews are dealt correct/incorrect to land near this.
    private static let targetAccuracy = 0.87

    // MARK: - Seeding

    static func seed(into context: ModelContext) {
        var rng = DeterministicRandom(seed: 0x4D656D4D_75747421)   // "MemMutt!"

        let decks = installDecks(into: context)
        guard !decks.isEmpty else { return }

        shapeCardStates(in: decks, using: &rng)
        buildStudyHistory(for: decks, into: context, using: &rng)

        try? context.save()
    }

    // MARK: - Decks

    /// The starter decks make the best screenshots — real content, believable counts —
    /// so the demo state reuses them rather than inventing parallel fixtures.
    private static let starterDeckIDs = ["world_capitals", "spanish", "us_capitals", "us_presidents"]

    private static func installDecks(into context: ModelContext) -> [Deck] {
        for id in starterDeckIDs {
            guard let info = StarterDeckService.availableDecks.first(where: { $0.id == id }) else { continue }
            try? StarterDeckService.installDeck(info, modelContext: context)
        }

        addCustomDeck(to: context)

        // Sorted, because SwiftData makes no ordering promise and the demo state has to
        // come out identical on every device in a capture run.
        let descriptor = FetchDescriptor<Deck>(sortBy: [SortDescriptor(\.name)])
        return (try? context.fetch(descriptor)) ?? []
    }

    /// One hand-made deck, so the Decks tab doesn't read as nothing but bundled content.
    private static func addCustomDeck(to context: ModelContext) {
        let deck = Deck(
            name: "Spanish Verbs — Irregular",
            deckDescription: "The ones that refuse to follow the rules",
            tags: ["Language", "Spanish"],
            color: "orange",
            icon: "character.book.closed.fill"
        )
        context.insert(deck)

        let pairs = [
            ("ser", "to be (permanent)"), ("estar", "to be (temporary)"),
            ("ir", "to go"), ("tener", "to have"), ("hacer", "to do / to make"),
            ("poder", "to be able to"), ("decir", "to say / to tell"),
            ("venir", "to come"), ("poner", "to put"), ("saber", "to know"),
            ("querer", "to want"), ("ver", "to see"), ("dar", "to give"),
            ("salir", "to leave"), ("traer", "to bring"), ("caer", "to fall"),
            ("conocer", "to know (someone)"), ("oír", "to hear"),
        ]

        for (front, back) in pairs {
            let card = Card(front: front, back: back)
            card.deck = deck
            context.insert(card)
        }
    }

    // MARK: - Card state

    /// Spread cards across the four statuses so progress rings and status breakdowns
    /// have something to show, and leave a believable number due today.
    private static func shapeCardStates(in decks: [Deck], using rng: inout DeterministicRandom) {
        let now = Date()

        for deck in decks {
            // `deck.cards` comes back unordered, so sort before dealing out states.
            for (index, card) in deck.cards.sorted(by: { $0.front < $1.front }).enumerated() {
                let roll = rng.nextDouble()

                switch roll {
                case ..<0.30:
                    card.status = .new
                    card.interval = 0
                    card.easeFactor = 2.5
                    card.nextReviewDate = now
                case ..<0.50:
                    card.status = .learning
                    card.interval = rng.nextInt(in: 1...20)
                    card.easeFactor = 2.1 + rng.nextDouble() * 0.3
                    card.nextReviewDate = offset(now, days: rng.nextInt(in: -2...6))
                case ..<0.80:
                    card.status = .review
                    card.interval = rng.nextInt(in: 21...59)
                    card.easeFactor = 2.3 + rng.nextDouble() * 0.3
                    card.nextReviewDate = offset(now, days: rng.nextInt(in: -1...30))
                default:
                    card.status = .mastered
                    card.interval = rng.nextInt(in: 60...180)
                    card.easeFactor = 2.6 + rng.nextDouble() * 0.3
                    card.nextReviewDate = offset(now, days: rng.nextInt(in: 10...120))
                }

                // A few cards per deck are genuine leeches, so the Trouble Cards and
                // Rescue Round entry points aren't empty in the screenshots.
                if index % 47 == 11 {
                    card.status = .learning
                    card.lapseCount = rng.nextInt(in: 3...5)
                    card.easeFactor = 1.3
                    card.interval = 1
                    card.nextReviewDate = now
                }
            }
        }
    }

    // MARK: - History

    /// Build one finished session per day for the last `streakDays` days, each with its
    /// own reviews, so streak, accuracy, study time, and the heatmap all agree.
    private static func buildStudyHistory(
        for decks: [Deck],
        into context: ModelContext,
        using rng: inout DeterministicRandom
    ) {
        let calendar = Calendar.current
        let studiedCards = decks
            .flatMap { $0.cards.sorted(by: { $0.front < $1.front }) }
            .filter { $0.status != .new }
        guard !studiedCards.isEmpty else { return }

        var cardCursor = 0

        for dayOffset in (0..<streakDays).reversed() {
            guard let day = calendar.date(byAdding: .day, value: -dayOffset, to: Date()) else { continue }
            let startOfDay = calendar.startOfDay(for: day)
            // Evening study, so the timestamps look like a real habit.
            let start = calendar.date(byAdding: .minute, value: 19 * 60 + rng.nextInt(in: 0...90), to: startOfDay) ?? startOfDay

            let deck = decks[rng.nextInt(in: 0...(decks.count - 1))]
            let cardsStudied = rng.nextInt(in: 18...34)

            let session = StudySession(startTime: start, cardsStudied: cardsStudied)
            session.deck = deck
            context.insert(session)

            var correct = 0
            var elapsed = 0

            for _ in 0..<cardsStudied {
                let card = studiedCards[cardCursor % studiedCards.count]
                cardCursor += 1

                let isCorrect = rng.nextDouble() < targetAccuracy
                if isCorrect { correct += 1 }

                let timeSpent = rng.nextInt(in: 3...11)
                elapsed += timeSpent

                let review = Review(
                    rating: isCorrect ? .correct : .incorrect,
                    reviewedAt: calendar.date(byAdding: .second, value: elapsed, to: start) ?? start,
                    timeSpent: timeSpent
                )
                review.card = card
                review.session = session
                context.insert(review)
            }

            session.correctCount = correct
            session.cardsReview = cardsStudied
            session.endTime = calendar.date(byAdding: .second, value: elapsed, to: start)
        }
    }

    // MARK: - Helpers

    private static func offset(_ date: Date, days: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: days, to: date) ?? date
    }
}

/// SplitMix64. Seeded explicitly so every capture run — and every device in a run —
/// produces byte-identical demo content.
private struct DeterministicRandom: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) { self.state = seed }

    mutating func next() -> UInt64 {
        state &+= 0x9E3779B97F4A7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        return z ^ (z >> 31)
    }

    mutating func nextDouble() -> Double {
        Double(next() >> 11) * (1.0 / 9007199254740992.0)
    }

    mutating func nextInt(in range: ClosedRange<Int>) -> Int {
        Int.random(in: range, using: &self)
    }
}
#endif
