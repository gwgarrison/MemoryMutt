import Foundation
import SwiftData

/// Detection and repair of "trouble cards" — cards the learner has already learned once
/// and keeps losing again. SM-2 on its own never notices these: its ease factor bottoms
/// out at 1.3 and the card simply cycles forever at a short interval.
@MainActor
enum TroubleCardService {

    private static let backfillKey = "troubleCardsLapseBackfillCompleted"

    // MARK: - Queries

    /// Every trouble card across all decks, worst first.
    static func troubleCards(in context: ModelContext) -> [Card] {
        let descriptor = FetchDescriptor<Card>(predicate: #Predicate { $0.lapseCount >= 1 })
        let lapsed = (try? context.fetch(descriptor)) ?? []
        return sorted(lapsed.filter { $0.isTroubleCard })
    }

    /// Order a set of cards worst-first for the rescue queue.
    static func sorted(_ cards: [Card]) -> [Card] {
        cards.sorted { $0.troubleScore > $1.troubleScore }
    }

    // MARK: - Recording

    /// Count a miss as a lapse when the card had already been learned. Call this *before*
    /// the review is applied, while the card still reflects its pre-review state.
    static func registerReview(_ rating: ReviewRating, for card: Card) {
        guard rating == .incorrect, card.hasBeenLearned else { return }
        card.lapseCount += 1
    }

    // MARK: - Rescue

    /// A card has been recognised and then recalled cleanly. Wipe its lapse history and
    /// drop it back into the learning phase with a fresh ease factor, so it re-graduates
    /// on merit instead of staying pinned at the 1.3 floor.
    static func completeRescue(for card: Card) {
        card.lapseCount = 0
        card.rescuedAt = Date()
        card.easeFactor = SM2Algorithm.defaultEaseFactor
        card.interval = 1
        card.status = .learning
        card.nextReviewDate = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
        card.updatedAt = Date()
    }

    // MARK: - Migration

    /// Reconstruct `lapseCount` from existing review history, once, so the feature is
    /// useful on day one for people who already have months of reviews recorded.
    static func backfillLapseCountsIfNeeded(in context: ModelContext) {
        guard !UserDefaults.standard.bool(forKey: backfillKey) else { return }

        // Walk reviews rather than cards: only cards with review history can have lapsed,
        // and this faults in exactly that set instead of the whole library.
        let descriptor = FetchDescriptor<Review>(sortBy: [SortDescriptor(\.reviewedAt)])
        let reviews = (try? context.fetch(descriptor)) ?? []

        var reviewedCards: [UUID: Card] = [:]
        var seenCorrect: Set<UUID> = []
        var lapses: [UUID: Int] = [:]

        for review in reviews {
            guard let card = review.card else { continue }
            reviewedCards[card.id] = card
            if review.rating == .correct {
                seenCorrect.insert(card.id)
            } else if seenCorrect.contains(card.id) {
                lapses[card.id, default: 0] += 1
            }
        }

        for (id, card) in reviewedCards {
            let count = lapses[id] ?? 0
            if card.lapseCount != count {
                card.lapseCount = count
            }
        }
        try? context.save()

        UserDefaults.standard.set(true, forKey: backfillKey)
    }
}
