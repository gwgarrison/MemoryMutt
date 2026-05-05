import Foundation
import SwiftData

enum ReviewRating: String, Codable, CaseIterable {
    case incorrect = "incorrect"  // User doesn't know the answer (X button)
    case correct = "correct"      // User knows the answer (checkmark button)
    
    var displayName: String {
        switch self {
        case .incorrect: return "Don't Know"
        case .correct: return "Know It"
        }
    }
    
    /// Quality score for SM-2 algorithm (0-5 scale)
    var quality: Int {
        switch self {
        case .incorrect: return 0
        case .correct: return 4
        }
    }
    
    var isCorrect: Bool {
        switch self {
        case .incorrect: return false
        case .correct: return true
        }
    }
}

@Model
final class Review {
    var id: UUID
    var ratingRawValue: String
    var reviewedAt: Date
    var timeSpent: Int // in seconds
    
    var card: Card?
    var session: StudySession?
    
    var rating: ReviewRating {
        get { ReviewRating(rawValue: ratingRawValue) ?? .incorrect }
        set { ratingRawValue = newValue.rawValue }
    }
    
    init(
        id: UUID = UUID(),
        rating: ReviewRating,
        reviewedAt: Date = Date(),
        timeSpent: Int = 0
    ) {
        self.id = id
        self.ratingRawValue = rating.rawValue
        self.reviewedAt = reviewedAt
        self.timeSpent = timeSpent
    }
}
