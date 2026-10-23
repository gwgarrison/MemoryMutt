import WatchConnectivity
import SwiftData

@MainActor
final class WatchConnectivityService: NSObject, WCSessionDelegate {
    static let shared = WatchConnectivityService()

    private var modelContext: ModelContext?

    /// WCSession messages are capped at ~64 KB, and a single untouched starter deck is
    /// ~40 KB (new cards are due immediately). Send a wrist-sized batch per deck instead.
    private static let maxCardsPerDeck = 25

    override init() {
        super.init()
        guard WCSession.isSupported() else { NSLog("MMWC phone WCSession NOT supported"); return }
        WCSession.default.delegate = self
        WCSession.default.activate()
        NSLog("MMWC phone init: activate() called")
    }

    func configure(with context: ModelContext) {
        modelContext = context
    }

    // MARK: - WCSessionDelegate

    nonisolated func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        NSLog("MMWC phone activationDidComplete state=\(activationState.rawValue) error=\(error?.localizedDescription ?? "nil")")
    }
    nonisolated func sessionDidBecomeInactive(_ session: WCSession) {}
    nonisolated func sessionDidDeactivate(_ session: WCSession) { session.activate() }

    nonisolated func session(_ session: WCSession, didReceiveMessage message: [String: Any], replyHandler: @escaping ([String: Any]) -> Void) {
        NSLog("MMWC phone didReceiveMessage type=\(message["type"] as? String ?? "nil")")
        guard let type = message["type"] as? String else { replyHandler([:]); return }
        switch type {
        case "requestDecks":
            Task { @MainActor in replyHandler(self.buildDeckPayload()) }
        case "recordReview":
            Task { @MainActor in self.applyReview(from: message); replyHandler(["ok": true]) }
        default:
            replyHandler([:])
        }
    }

    /// Reviews the watch queued while the phone was unreachable.
    nonisolated func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any] = [:]) {
        guard userInfo["type"] as? String == "recordReview" else { return }
        Task { @MainActor in self.applyReview(from: userInfo) }
    }

    // MARK: - Helpers

    private func buildDeckPayload() -> [String: Any] {
        guard let context = modelContext else { return [:] }
        let descriptor = FetchDescriptor<Deck>(sortBy: [SortDescriptor(\.name)])
        let decks = (try? context.fetch(descriptor)) ?? []
        NSLog("MMWC phone buildDeckPayload: \(decks.count) decks total")

        let payload: [[String: Any]] = decks.compactMap { deck in
            let due = deck.cards.filter { $0.isDue }
            guard !due.isEmpty else { return nil }
            // Cards already in rotation come before new ones, most overdue first.
            let batch = due.sorted {
                ($0.status == .new ? 1 : 0, $0.nextReviewDate) < ($1.status == .new ? 1 : 0, $1.nextReviewDate)
            }.prefix(Self.maxCardsPerDeck)
            return [
                "id": deck.id.uuidString,
                "name": deck.name,
                "dueCount": due.count,
                "cards": batch.map { card in
                    ["id": card.id.uuidString,
                     "front": card.front,
                     "back": card.back,
                     "easeFactor": card.easeFactor,
                     "interval": card.interval,
                     "statusRaw": card.statusRawValue] as [String: Any]
                }
            ]
        }
        return ["decks": payload]
    }

    private func applyReview(from message: [String: Any]) {
        guard let context = modelContext,
              let idStr = message["cardID"] as? String,
              let id = UUID(uuidString: idStr),
              let ratingStr = message["rating"] as? String,
              let rating = ReviewRating(rawValue: ratingStr),
              let easeFactor = message["newEaseFactor"] as? Double,
              let interval = message["newInterval"] as? Int,
              let statusRaw = message["newStatusRaw"] as? String,
              let ts = message["newNextReviewDate"] as? Double
        else { return }

        var descriptor = FetchDescriptor<Card>(predicate: #Predicate { $0.id == id })
        descriptor.fetchLimit = 1
        guard let card = try? context.fetch(descriptor).first else { return }

        // Keep trouble-card detection in sync with reviews done on the watch
        TroubleCardService.registerReview(rating, for: card)

        card.easeFactor = easeFactor
        card.interval = interval
        card.statusRawValue = statusRaw
        card.nextReviewDate = Date(timeIntervalSince1970: ts)
        card.updatedAt = Date()

        let review = Review(rating: rating, timeSpent: 0)
        review.card = card
        context.insert(review)
        try? context.save()
    }
}
