import Foundation
import SwiftData

enum ReviewRating: String, Codable, CaseIterable {
    case again = "again"
    case hard = "hard"
    case good = "good"
    case easy = "easy"
    
    var displayName: String {
        switch self {
        case .again: return "Again"
        case .hard: return "Hard"
        case .good: return "Good"
        case .easy: return "Easy"
        }
    }
    
    var quality: Int {
        switch self {
        case .again: return 0
        case .hard: return 2
        case .good: return 3
        case .easy: return 5
        }
    }
    
    var isCorrect: Bool {
        switch self {
        case .again: return false
        case .hard, .good, .easy: return true
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
        get { ReviewRating(rawValue: ratingRawValue) ?? .again }
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
