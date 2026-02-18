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
    func startSession(deck: Deck, newCardsLimit: Int = 20, reviewLimit: Int = 100) {
        // Get due cards and new cards
        let dueCards = deck.cards.filter { $0.isDue && $0.status != .new }
        let newCards = deck.cards.filter { $0.status == .new }
        
        // Limit cards based on settings
        let selectedNewCards = Array(newCards.prefix(newCardsLimit))
        let selectedReviewCards = Array(dueCards.prefix(reviewLimit))
        
        // Combine and shuffle
        cardQueue = (selectedNewCards + selectedReviewCards).shuffled()
        currentCardIndex = 0
        cardStartTime = Date()
        
        // Create session
        let session = StudySession(
            cardsNew: selectedNewCards.count,
            cardsReview: selectedReviewCards.count
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
