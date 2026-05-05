import Foundation
import SwiftData

@Model
final class Deck {
    var id: UUID
    var name: String
    var deckDescription: String
    var tags: [String]
    var color: String
    var icon: String
    var createdAt: Date
    var updatedAt: Date
    
    @Relationship(deleteRule: .cascade, inverse: \Card.deck)
    var cards: [Card] = []
    
    @Relationship(deleteRule: .cascade, inverse: \StudySession.deck)
    var studySessions: [StudySession] = []
    
    var cardsCount: Int {
        cards.count
    }
    
    var cardsDueCount: Int {
        cards.filter { $0.isDue }.count
    }
    
    var newCardsCount: Int {
        cards.filter { $0.status == .new }.count
    }
    
    var masteredCardsCount: Int {
        cards.filter { $0.status == .mastered }.count
    }
    
    init(
        id: UUID = UUID(),
        name: String,
        deckDescription: String = "",
        tags: [String] = [],
        color: String = "blue",
        icon: String = "rectangle.stack.fill",
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.deckDescription = deckDescription
        self.tags = tags
        self.color = color
        self.icon = icon
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
