import SwiftUI

struct WatchStudyView: View {
    let deck: WatchDeckPayload
    @State private var connectivity = WatchConnectivityService.shared
    @State private var cards: [WatchCardPayload] = []
    @State private var currentIndex = 0
    @State private var correctCount = 0

    private var isDone: Bool { currentIndex >= cards.count }

    var body: some View {
        Group {
            if isDone {
                completionView
            } else {
                studyContent
            }
        }
        .navigationTitle(deck.name)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { cards = deck.cards.shuffled() }
    }

    private var studyContent: some View {
        VStack(spacing: 4) {
            Text("\(currentIndex + 1) of \(cards.count)")
                .font(.caption2)
                .foregroundStyle(.secondary)

            WatchFlashcardView(card: cards[currentIndex]) { rating in
                handleRating(rating)
            }
            .id(cards[currentIndex].id)
        }
    }

    private var completionView: some View {
        VStack(spacing: 8) {
            Image(systemName: "star.fill")
                .font(.largeTitle)
                .foregroundStyle(.yellow)
            Text("Done!")
                .font(.headline)
            Text("\(correctCount) of \(cards.count) correct")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
    }

    private func handleRating(_ rating: ReviewRating) {
        let card = cards[currentIndex]
        if rating == .correct { correctCount += 1 }

        let result = SM2Algorithm.calculateNextReview(
            currentEaseFactor: card.easeFactor,
            currentInterval: card.interval,
            currentStatus: card.status,
            rating: rating
        )
        connectivity.sendReview(cardID: card.id, rating: rating, result: result)
        currentIndex += 1
    }
}
