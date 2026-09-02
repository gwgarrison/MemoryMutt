import Foundation
import SwiftData

enum CardStatus: String, Codable, CaseIterable {
    case new = "new"
    case learning = "learning"
    case review = "review"
    case mastered = "mastered"

    var displayName: String {
        switch self {
        case .new: return "New"
        case .learning: return "Learning"
        case .review: return "Review"
        case .mastered: return "Mastered"
        }
    }
}

enum CardType: String, Codable, CaseIterable {
    case standard  = "standard"
    case trueFalse = "trueFalse"

    var displayName: String {
        switch self {
        case .standard:  return "Standard"
        case .trueFalse: return "True / False"
        }
    }
}

/// Tuning for trouble-card detection — the point at which a card is judged to be
/// beating the learner rather than the other way around.
enum TroubleThresholds {
    /// Lapses (forgetting a card you had already learned) that alone mark a card as trouble.
    static let lapses = 3
    /// Reviews a card needs before its accuracy is meaningful.
    static let minReviews = 4
    /// Accuracy below which a lapsing card counts as trouble.
    static let accuracy: Double = 50
}

@Model
final class Card {
    var id: UUID
    var front: String
    var back: String
    var frontImageData: Data?
    var backImageData: Data?
    var frontAudioURL: String?
    var backAudioURL: String?
    var hint: String?
    @Attribute var cardTypeRawValue: String = "standard"
    /// Number of times this card was forgotten *after* having been learned.
    @Attribute var lapseCount: Int = 0
    /// When a Rescue Round last brought this card back, if ever.
    var rescuedAt: Date?
    var statusRawValue: String
    var easeFactor: Double
    var interval: Int // in days
    var nextReviewDate: Date
    var createdAt: Date
    var updatedAt: Date
    
    var deck: Deck?
    
    @Relationship(deleteRule: .cascade, inverse: \Review.card)
    var reviews: [Review] = []
    
    var cardType: CardType {
        get { CardType(rawValue: cardTypeRawValue) ?? .standard }
        set { cardTypeRawValue = newValue.rawValue }
    }

    var status: CardStatus {
        get { CardStatus(rawValue: statusRawValue) ?? .new }
        set { statusRawValue = newValue.rawValue }
    }
    
    var isDue: Bool {
        nextReviewDate <= Date()
    }

    var correctCount: Int { reviews.filter { $0.rating == .correct }.count }
    var incorrectCount: Int { reviews.filter { $0.rating == .incorrect }.count }
    var accuracy: Double {
        guard !reviews.isEmpty else { return 0 }
        return Double(correctCount) / Double(reviews.count) * 100
    }

    /// True once the card has been answered correctly at least once, meaning a miss
    /// now is a lapse (you forgot it) rather than a first encounter.
    var hasBeenLearned: Bool { correctCount > 0 }

    /// A card that keeps slipping away: either it has lapsed enough times on its own,
    /// or it has lapsed at least once and its overall accuracy is poor.
    var isTroubleCard: Bool {
        guard lapseCount >= 1 else { return false }
        if lapseCount >= TroubleThresholds.lapses { return true }
        return reviews.count >= TroubleThresholds.minReviews && accuracy < TroubleThresholds.accuracy
    }

    /// Higher means more trouble. Used to order the rescue queue worst-first.
    var troubleScore: Double {
        Double(lapseCount) * 10 + (100 - accuracy)
    }
    
    init(
        id: UUID = UUID(),
        front: String,
        back: String,
        frontImageData: Data? = nil,
        backImageData: Data? = nil,
        frontAudioURL: String? = nil,
        backAudioURL: String? = nil,
        hint: String? = nil,
        cardType: CardType = .standard,
        lapseCount: Int = 0,
        rescuedAt: Date? = nil,
        status: CardStatus = .new,
        easeFactor: Double = 2.5,
        interval: Int = 0,
        nextReviewDate: Date = Date(),
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.front = front
        self.back = back
        self.frontImageData = frontImageData
        self.backImageData = backImageData
        self.frontAudioURL = frontAudioURL
        self.backAudioURL = backAudioURL
        self.hint = hint
        self.cardTypeRawValue = cardType.rawValue
        self.lapseCount = lapseCount
        self.rescuedAt = rescuedAt
        self.statusRawValue = status.rawValue
        self.easeFactor = easeFactor
        self.interval = interval
        self.nextReviewDate = nextReviewDate
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
