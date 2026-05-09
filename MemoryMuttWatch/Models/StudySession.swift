import Foundation
import SwiftData

enum StudyMode: String, Codable, CaseIterable {
    case flashcard = "flashcard"
    case multipleChoice = "multipleChoice"
    case matchGame = "matchGame"
    case hangman = "hangman"
    case speedRound = "speedRound"

    var displayName: String {
        switch self {
        case .flashcard: return "Flashcard"
        case .multipleChoice: return "Multiple Choice"
        case .matchGame: return "Match Game"
        case .hangman: return "Hangman"
        case .speedRound: return "Speed Round"
        }
    }

    var icon: String {
        switch self {
        case .flashcard: return "rectangle.portrait.on.rectangle.portrait"
        case .multipleChoice: return "list.bullet.circle"
        case .matchGame: return "square.grid.2x2"
        case .hangman: return "figure.stand"
        case .speedRound: return "bolt.fill"
        }
    }
}

@Model
final class StudySession {
    var id: UUID
    var startTime: Date
    var endTime: Date?
    var cardsStudied: Int
    var cardsNew: Int
    var cardsReview: Int
    var correctCount: Int
    
    var deck: Deck?
    
    @Relationship(deleteRule: .cascade, inverse: \Review.session)
    var reviews: [Review] = []
    
    var accuracy: Double {
        guard cardsStudied > 0 else { return 0 }
        return Double(correctCount) / Double(cardsStudied) * 100
    }
    
    var duration: TimeInterval {
        guard let endTime = endTime else { return 0 }
        return endTime.timeIntervalSince(startTime)
    }
    
    var durationFormatted: String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return "\(minutes)m \(seconds)s"
    }
    
    init(
        id: UUID = UUID(),
        startTime: Date = Date(),
        endTime: Date? = nil,
        cardsStudied: Int = 0,
        cardsNew: Int = 0,
        cardsReview: Int = 0,
        correctCount: Int = 0
    ) {
        self.id = id
        self.startTime = startTime
        self.endTime = endTime
        self.cardsStudied = cardsStudied
        self.cardsNew = cardsNew
        self.cardsReview = cardsReview
        self.correctCount = correctCount
    }
}
