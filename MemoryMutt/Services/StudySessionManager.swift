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
    @Published var studyMode: StudyMode = .flashcard
    @Published var currentChoices: [String] = []
    @Published var timeRemaining: Int = 60
    @Published var isBlitzMode: Bool = false

    private var modelContext: ModelContext?
    private var allDeckCards: [Card] = []
    private var requeuedCounts: [UUID: Int] = [:]
    private var blitzTimerTask: Task<Void, Never>?
    private var currentDeckId: UUID?
    private let blitzDuration = 60
    
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

    private func startBlitzTimer() {
        blitzTimerTask?.cancel()
        timeRemaining = blitzDuration
        blitzTimerTask = Task {
            while !Task.isCancelled && timeRemaining > 0 {
                try? await Task.sleep(for: .seconds(1))
                guard !Task.isCancelled else { break }
                timeRemaining -= 1
                if timeRemaining == 0 { endSession() }
            }
        }
    }
    
    /// Start a new study session for a deck
    func startSession(deck: Deck, cardLimit: Int = 20, newCardsLimit: Int = 20, reviewLimit: Int = 100, reversed: Bool = false, mode: StudyMode = .flashcard, reviewOrder: String = "random") {
        self.isReversed = reversed
        self.studyMode = mode
        self.allDeckCards = deck.cards
        // Get cards by category
        let newCards = deck.cards.filter { $0.status == .new }
        let dueCards = deck.cards.filter { $0.isDue && $0.status != .new }

        // Limit cards based on settings
        let selectedNewCards = Array(newCards.shuffled().prefix(newCardsLimit))
        let selectedReviewCards = Array(dueCards.shuffled().prefix(reviewLimit))

        // Combine and order based on review order preference
        var combined: [Card]
        switch reviewOrder {
        case "oldest":
            combined = (selectedNewCards + selectedReviewCards).sorted {
                ($0.nextReviewDate ?? Date.distantPast) < ($1.nextReviewDate ?? Date.distantPast)
            }
        case "newest":
            combined = (selectedNewCards + selectedReviewCards).sorted {
                ($0.nextReviewDate ?? Date.distantPast) > ($1.nextReviewDate ?? Date.distantPast)
            }
        default:
            combined = (selectedNewCards + selectedReviewCards).shuffled()
        }
        
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
        requeuedCounts = [:]
        cardStartTime = Date()

        isBlitzMode = mode == .speedRound
        currentDeckId = deck.id

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

        if mode == .speedRound { startBlitzTimer() }

        // Generate choices for multiple choice and speed round modes
        if mode == .multipleChoice || mode == .speedRound {
            generateChoices()
        }
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

        // Re-queue incorrect cards for immediate retry (up to 2 times)
        if rating == .incorrect {
            let count = requeuedCounts[card.id, default: 0]
            if count < 2 {
                cardQueue.append(card)
                requeuedCounts[card.id] = count + 1
            }
        }

        // Check if session is complete
        if currentCardIndex >= cardQueue.count {
            endSession()
        } else if studyMode == .multipleChoice || studyMode == .speedRound {
            generateChoices()
        }
    }
    
    /// Record reviews for all cards after completing a match game session.
    /// All cards are marked correct since the user must successfully match every pair to finish.
    func recordMatchGameReviews(correctCount: Int, totalCount: Int) {
        guard let session = currentSession else { return }

        for card in cardQueue {
            let review = Review(rating: .correct, timeSpent: 0)
            review.card = card
            review.session = session
            SM2Algorithm.applyReview(to: card, rating: .correct)
            modelContext?.insert(review)
        }

        session.cardsStudied = totalCount
        session.correctCount = correctCount
        endSession()
    }

    /// End the current session
    func endSession() {
        blitzTimerTask?.cancel()
        blitzTimerTask = nil

        if isBlitzMode, let deckId = currentDeckId, let session = currentSession {
            let key = "speedRoundBestScore_\(deckId.uuidString)"
            let prev = UserDefaults.standard.integer(forKey: key)
            if session.correctCount > prev {
                UserDefaults.standard.set(session.correctCount, forKey: key)
            }
        }

        currentSession?.endTime = Date()
        isSessionActive = false

        // Save changes
        try? modelContext?.save()
    }
    
    /// Generate 4 multiple choice options for the current card
    func generateChoices() {
        guard let card = currentCard else {
            currentChoices = []
            return
        }
        
        // The correct answer is the "back" side (or "front" if reversed)
        let correctAnswer = isReversed ? card.front : card.back
        
        // Gather distractor answers from other cards in the deck
        let otherAnswers = allDeckCards
            .filter { $0.id != card.id }
            .map { isReversed ? $0.front : $0.back }
            .filter { $0 != correctAnswer }
        
        let distractors = Array(otherAnswers.shuffled().prefix(3))
        
        // Combine correct answer with distractors and shuffle
        var choices = [correctAnswer] + distractors
        choices.shuffle()
        
        currentChoices = choices
    }
    
    /// The correct answer for the current card in multiple choice mode
    var correctAnswer: String? {
        guard let card = currentCard else { return nil }
        return isReversed ? card.front : card.back
    }
    
    /// Reset session state
    func reset() {
        blitzTimerTask?.cancel()
        blitzTimerTask = nil
        currentSession = nil
        cardQueue = []
        currentCardIndex = 0
        isSessionActive = false
        currentChoices = []
        allDeckCards = []
        requeuedCounts = [:]
        timeRemaining = blitzDuration
        isBlitzMode = false
        currentDeckId = nil
    }
}
