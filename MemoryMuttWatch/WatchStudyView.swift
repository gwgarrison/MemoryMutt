import SwiftUI
import SwiftData

struct WatchStudyView: View {
    let deck: Deck
    @Environment(\.modelContext) private var context
    @State private var dueCards: [Card] = []
    @State private var currentIndex = 0
    @State private var correctCount = 0
    @State private var isLoaded = false

    private var isDone: Bool { currentIndex >= dueCards.count }

    var body: some View {
        Group {
            if !isLoaded {
                ProgressView()
            } else if dueCards.isEmpty {
                ContentUnavailableView("All Caught Up!", systemImage: "checkmark.circle.fill")
            } else if isDone {
                completionView
            } else {
                studyContent
            }
        }
        .navigationTitle(deck.name)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            dueCards = deck.cards.filter { $0.isDue }.shuffled()
            isLoaded = true
        }
    }

    private var studyContent: some View {
        VStack(spacing: 4) {
            Text("\(currentIndex + 1) of \(dueCards.count)")
                .font(.caption2)
                .foregroundStyle(.secondary)

            WatchFlashcardView(card: dueCards[currentIndex]) { rating in
                handleRating(rating)
            }
            .id(dueCards[currentIndex].id)
        }
    }

    private var completionView: some View {
        VStack(spacing: 8) {
            Image(systemName: "star.fill")
                .font(.largeTitle)
                .foregroundStyle(.yellow)
            Text("Done!")
                .font(.headline)
            Text("\(correctCount) of \(dueCards.count) correct")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
    }

    private func handleRating(_ rating: ReviewRating) {
        let card = dueCards[currentIndex]
        if rating == .correct { correctCount += 1 }
        SM2Algorithm.applyReview(to: card, rating: rating)
        let review = Review(rating: rating, timeSpent: 0)
        review.card = card
        context.insert(review)
        try? context.save()
        currentIndex += 1
    }
}
