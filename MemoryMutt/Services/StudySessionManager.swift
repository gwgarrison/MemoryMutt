import Foundation
import SwiftData
import Combine

/// The two passes a trouble card must clear to be rescued: recognise it among
/// distractors, then recall it cold.
enum RescuePhase: Int {
    case recognition = 0
    case recall = 1
}

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
    @Published var trueFalseDisplayedAnswer: String = ""
    @Published var trueFalseIsTrue: Bool = true
    @Published var rescuePhase: RescuePhase = .recognition
    @Published var rescuedCount: Int = 0
    @Published var rescueTotal: Int = 0
    @Published var releasedCount: Int = 0
    /// Set when a card is missed in a Rescue Round and has no hint yet, so the UI can
    /// offer to add one at the moment it would actually help.
    @Published var cardNeedingHint: Card?

    private var modelContext: ModelContext?
    private var allDeckCards: [Card] = []
    private var requeuedCounts: [UUID: Int] = [:]
    private var blitzTimerTask: Task<Void, Never>?
    private var currentDeckId: UUID?
    private let blitzDuration = 60
    private var rescuePhases: [UUID: Int] = [:]
    private var rescueAttempts: [UUID: Int] = [:]
    private var hintPromptedIds: Set<UUID> = []
    /// Attempts before a stubborn card is released from the queue so the round can end.
    private let maxRescueAttempts = 6
    
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
        } else if mode == .trueFalse {
            generateTrueFalseScenario()
        }
    }
    
    /// Record a review for the current card
    func recordReview(rating: ReviewRating) {
        guard let card = currentCard, let session = currentSession else { return }
        
        // Count a forgotten-again card as a lapse before the review lands
        TroubleCardService.registerReview(rating, for: card)
        
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
        } else if studyMode == .trueFalse {
            generateTrueFalseScenario()
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

    // MARK: - Rescue Round

    /// Start a Rescue Round over a hand-picked set of trouble cards. Unlike a normal
    /// session this ignores due dates entirely — the point is the cards themselves.
    /// - Parameters:
    ///   - cards: the trouble cards to rescue.
    ///   - deck: the owning deck, or nil for a rescue that spans decks.
    ///   - distractorPool: cards to draw multiple-choice distractors from.
    func startRescueSession(cards: [Card], deck: Deck?, distractorPool: [Card]) {
        guard !cards.isEmpty else { return }

        studyMode = .rescue
        isReversed = false
        isBlitzMode = false
        allDeckCards = distractorPool
        cardQueue = TroubleCardService.sorted(cards)
        currentCardIndex = 0
        requeuedCounts = [:]
        rescuePhases = [:]
        rescueAttempts = [:]
        hintPromptedIds = []
        cardNeedingHint = nil
        rescueTotal = cards.count
        rescuedCount = 0
        releasedCount = 0
        rescuePhase = .recognition
        cardStartTime = Date()
        currentDeckId = deck?.id

        let session = StudySession(cardsNew: 0, cardsReview: cards.count)
        session.deck = deck
        currentSession = session
        isSessionActive = true
        modelContext?.insert(session)

        generateChoices()
    }

    /// Record one answer inside a Rescue Round.
    ///
    /// Rescue answers are logged as real reviews (they count towards streaks and daily
    /// totals) but deliberately do *not* run SM-2 per answer and never add a lapse —
    /// the card is already known to be struggling, and re-punishing it mid-rescue would
    /// only drive its ease factor further into the floor. Scheduling is repaired once,
    /// when the card clears both passes.
    func recordRescueAnswer(correct: Bool) {
        guard let card = currentCard, let session = currentSession else { return }

        let review = Review(
            rating: correct ? .correct : .incorrect,
            timeSpent: Int(Date().timeIntervalSince(cardStartTime))
        )
        review.card = card
        review.session = session
        modelContext?.insert(review)

        session.cardsStudied += 1
        if correct { session.correctCount += 1 }

        let attempts = rescueAttempts[card.id, default: 0] + 1
        rescueAttempts[card.id] = attempts

        cardQueue.removeFirst()

        if correct {
            if rescuePhases[card.id, default: 0] >= RescuePhase.recall.rawValue {
                // Recognised, then recalled — the card is rescued.
                TroubleCardService.completeRescue(for: card)
                rescuedCount += 1
            } else {
                rescuePhases[card.id] = RescuePhase.recall.rawValue
                cardQueue.append(card)
            }
        } else {
            // A miss sends the card back to the start of the ladder.
            rescuePhases[card.id] = RescuePhase.recognition.rawValue

            if (card.hint?.isEmpty ?? true) && !hintPromptedIds.contains(card.id) {
                hintPromptedIds.insert(card.id)
                cardNeedingHint = card
            }

            if attempts < maxRescueAttempts {
                cardQueue.append(card)
            } else {
                // Stubborn card — let it go for today rather than trapping the user.
                releasedCount += 1
            }
        }

        advanceRescue()
    }

    private func advanceRescue() {
        cardStartTime = Date()

        guard let next = cardQueue.first else {
            endSession()
            return
        }

        rescuePhase = RescuePhase(rawValue: rescuePhases[next.id, default: 0]) ?? .recognition
        if rescuePhase == .recognition {
            generateChoices()
        }
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
        var pool = allDeckCards.filter { $0.id != card.id }
        
        // A cross-deck Rescue Round draws from every deck, so keep distractors in the
        // same deck as the card wherever there are enough of them to choose from
        if studyMode == .rescue, let deckId = card.deck?.id {
            let sameDeck = pool.filter { $0.deck?.id == deckId }
            if sameDeck.count >= 3 { pool = sameDeck }
        }
        
        let otherAnswers = pool
            .map { isReversed ? $0.front : $0.back }
            .filter { $0 != correctAnswer }
        
        let distractors = Array(otherAnswers.shuffled().prefix(3))
        
        // Combine correct answer with distractors and shuffle
        var choices = [correctAnswer] + distractors
        choices.shuffle()
        
        currentChoices = choices
    }
    
    /// Generate a true/false scenario for the current card: 50% chance of showing the
    /// correct answer (true), 50% chance of showing a random wrong answer (false).
    func generateTrueFalseScenario() {
        guard let card = currentCard else { return }
        let correctAnswer = isReversed ? card.front : card.back
        let isTrueScenario = Bool.random()

        if isTrueScenario {
            trueFalseIsTrue = true
            trueFalseDisplayedAnswer = correctAnswer
        } else {
            let distractors = allDeckCards
                .filter { $0.id != card.id }
                .map { isReversed ? $0.front : $0.back }
                .filter { $0 != correctAnswer }
            if let distractor = distractors.randomElement() {
                trueFalseIsTrue = false
                trueFalseDisplayedAnswer = distractor
            } else {
                // Only one card in deck — can't generate a false answer, force true
                trueFalseIsTrue = true
                trueFalseDisplayedAnswer = correctAnswer
            }
        }
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
        rescuePhases = [:]
        rescueAttempts = [:]
        hintPromptedIds = []
        cardNeedingHint = nil
        rescuePhase = .recognition
        rescuedCount = 0
        rescueTotal = 0
        releasedCount = 0
    }
}
