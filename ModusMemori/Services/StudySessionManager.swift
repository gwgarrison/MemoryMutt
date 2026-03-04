import Foundation
import SwiftData
import Combine

@MainActor
class StudySessionManager: ObservableObject {
    @Published var currentSession: StudySession?
    @Published var cardQueue: [Card] = []
    @Published var currentCardIndex: Int = 0
    @Published var isSessionActive: Bool = false
    @Published var cardStartTime: Date = Date()
    @Published var isReversed: Bool = false
    
    private var modelContext: ModelContext?
    
    var currentCard: Card? {
        guard currentCardIndex < cardQueue.count else { return nil }
        return cardQueue[currentCardIndex]
    }
    
    var progress: Double {
        guard !cardQueue.isEmpty else { return 0 }
        return Double(currentCardIndex) / Double(cardQueue.count)
    }
    
    var cardsRemaining: Int {
        max(0, cardQueue.count - currentCardIndex)
    }
    
    var cardsStudied: Int {
        currentCardIndex
    }
    
    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
    }
    
    /// Start a new study session for a deck
    func startSession(deck: Deck, cardLimit: Int = 20, newCardsLimit: Int = 20, reviewLimit: Int = 100, reversed: Bool = false) {
        self.isReversed = reversed
        // Get cards by category
        let newCards = deck.cards.filter { $0.status == .new }
        let dueCards = deck.cards.filter { $0.isDue && $0.status != .new }
        
        // Limit cards based on settings
        let selectedNewCards = Array(newCards.shuffled().prefix(newCardsLimit))
        let selectedReviewCards = Array(dueCards.shuffled().prefix(reviewLimit))
        
        // Combine and cap to the session card limit
        var combined = (selectedNewCards + selectedReviewCards).shuffled()
        
        // If we don't have enough due/new cards to fill the session,
        // include learning cards that aren't due yet so the user can still study
        if combined.count < cardLimit {
            let selectedIds = Set(combined.map { $0.id })
            let additionalCards = deck.cards
                .filter { !selectedIds.contains($0.id) && $0.status != .mastered }
                .shuffled()
            combined.append(contentsOf: additionalCards.prefix(cardLimit - combined.count))
        }
        
        cardQueue = Array(combined.prefix(cardLimit))
        currentCardIndex = 0
        cardStartTime = Date()
        
        // Create session
        let actualNewCount = cardQueue.filter { $0.status == .new }.count
        let actualReviewCount = cardQueue.count - actualNewCount
        let session = StudySession(
            cardsNew: actualNewCount,
            cardsReview: actualReviewCount
        )
        session.deck = deck
        currentSession = session
        isSessionActive = true
        
        // Insert session into context
        modelContext?.insert(session)
    }
    
    /// Record a review for the current card
    func recordReview(rating: ReviewRating) {
        guard let card = currentCard, let session = currentSession else { return }
        
        // Calculate time spent on this card
        let timeSpent = Int(Date().timeIntervalSince(cardStartTime))
        
        // Create review record
        let review = Review(
            rating: rating,
            timeSpent: timeSpent
        )
        review.card = card
        review.session = session
        
        // Apply SM-2 algorithm
        SM2Algorithm.applyReview(to: card, rating: rating)
        
        // Update session stats
        session.cardsStudied += 1
        if rating.isCorrect {
            session.correctCount += 1
        }
        
        // Insert review
        modelContext?.insert(review)
        
        // Move to next card
        currentCardIndex += 1
        cardStartTime = Date()
        
        // Check if session is complete
        if currentCardIndex >= cardQueue.count {
            endSession()
        }
    }
    
    /// End the current session
    func endSession() {
        currentSession?.endTime = Date()
        isSessionActive = false
        
        // Save changes
        try? modelContext?.save()
    }
    
    /// Reset session state
    func reset() {
        currentSession = nil
        cardQueue = []
        currentCardIndex = 0
        isSessionActive = false
    }
}
