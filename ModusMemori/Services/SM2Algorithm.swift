import Foundation

/// SM-2 Spaced Repetition Algorithm
/// Based on the SuperMemo 2 algorithm for optimal learning intervals
struct SM2Algorithm {
    
    /// Minimum ease factor to prevent intervals from becoming too short
    static let minimumEaseFactor: Double = 1.3
    
    /// Default ease factor for new cards
    static let defaultEaseFactor: Double = 2.5
    
    /// Calculate the new scheduling parameters after a review
    /// - Parameters:
    ///   - card: The card being reviewed
    ///   - rating: The user's rating of difficulty
    /// - Returns: Updated card parameters (easeFactor, interval, nextReviewDate, status)
    static func calculateNextReview(
        currentEaseFactor: Double,
        currentInterval: Int,
        currentStatus: CardStatus,
        rating: ReviewRating
    ) -> (easeFactor: Double, interval: Int, nextReviewDate: Date, status: CardStatus) {
        
        let quality = rating.quality
        
        // Calculate new ease factor
        // EF' = EF + (0.1 - (5 - q) * (0.08 + (5 - q) * 0.02))
        var newEaseFactor = currentEaseFactor + (0.1 - Double(5 - quality) * (0.08 + Double(5 - quality) * 0.02))
        newEaseFactor = max(minimumEaseFactor, newEaseFactor)
        
        var newInterval: Int
        var newStatus: CardStatus
        
        if rating == .incorrect {
            // User doesn't know the card - reset progress
            newInterval = 0
            newStatus = .learning
        } else {
            // User knows the card - advance based on current state
            switch currentStatus {
            case .new:
                // First time seeing the card correctly
                newInterval = 1
                newStatus = .learning
                
            case .learning:
                // Card is in learning phase
                if currentInterval == 0 {
                    newInterval = 1
                } else if currentInterval == 1 {
                    newInterval = 6
                } else {
                    newInterval = Int(Double(currentInterval) * newEaseFactor)
                }
                newStatus = newInterval >= 21 ? .review : .learning
                
            case .review:
                // Card is in review phase
                newInterval = Int(Double(currentInterval) * newEaseFactor)
                newStatus = newInterval >= 60 ? .mastered : .review
                
            case .mastered:
                // Card is mastered, continue with longer intervals
                newInterval = Int(Double(currentInterval) * newEaseFactor)
                newStatus = .mastered
            }
        }
        
        // Calculate next review date
        let nextReviewDate: Date
        if newInterval == 0 {
            // Incorrect answer — card is due immediately
            nextReviewDate = Date()
        } else {
            nextReviewDate = Calendar.current.date(
                byAdding: .day,
                value: newInterval,
                to: Date()
            ) ?? Date()
        }
        
        return (newEaseFactor, newInterval, nextReviewDate, newStatus)
    }
    
    /// Apply SM-2 algorithm to a card after review
    static func applyReview(to card: Card, rating: ReviewRating) {
        let result = calculateNextReview(
            currentEaseFactor: card.easeFactor,
            currentInterval: card.interval,
            currentStatus: card.status,
            rating: rating
        )
        
        card.easeFactor = result.easeFactor
        card.interval = result.interval
        card.nextReviewDate = result.nextReviewDate
        card.status = result.status
        card.updatedAt = Date()
    }
}
