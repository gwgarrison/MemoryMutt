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
    var statusRawValue: String
    var easeFactor: Double
    var interval: Int // in days
    var nextReviewDate: Date
    var createdAt: Date
    var updatedAt: Date
    
    var deck: Deck?
    
    @Relationship(deleteRule: .cascade, inverse: \Review.card)
    var reviews: [Review] = []
    
    var status: CardStatus {
        get { CardStatus(rawValue: statusRawValue) ?? .new }
        set { statusRawValue = newValue.rawValue }
    }
    
    var isDue: Bool {
        nextReviewDate <= Date()
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
        self.statusRawValue = status.rawValue
        self.easeFactor = easeFactor
        self.interval = interval
        self.nextReviewDate = nextReviewDate
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
