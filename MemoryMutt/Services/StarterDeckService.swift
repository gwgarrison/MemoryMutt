import Foundation
import SwiftData

struct StarterDeckInfo: Identifiable {
    let id: String
    let name: String
    let description: String
    let icon: String
    let color: String
    let csvFileName: String
    let cardCount: Int
    let tags: [String]
}

@MainActor
class StarterDeckService {
    
    static let availableDecks: [StarterDeckInfo] = [
        StarterDeckInfo(
            id: "world_capitals",
            name: "World Capitals",
            description: "Countries and their capital cities from around the world",
            icon: "globe",
            color: "blue",
            csvFileName: "world_capitals",
            cardCount: 249,
            tags: ["Geography"]
        ),
        StarterDeckInfo(
            id: "us_capitals",
            name: "US State Capitals",
            description: "All 50 US states and their capital cities",
            icon: "flag.fill",
            color: "red",
            csvFileName: "us_capitals",
            cardCount: 50,
            tags: ["Geography", "US"]
        ),
        StarterDeckInfo(
            id: "us_presidents",
            name: "US Presidents",
            description: "All US presidents and their number in office",
            icon: "building.columns.fill",
            color: "purple",
            csvFileName: "us_presidents",
            cardCount: 47,
            tags: ["History", "US"]
        ),
        StarterDeckInfo(
            id: "spanish",
            name: "Spanish Vocabulary",
            description: "500 most common Spanish words and their English translations",
            icon: "character.book.closed.fill",
            color: "orange",
            csvFileName: "spanish",
            cardCount: 500,
            tags: ["Language", "Spanish"]
        ),
        StarterDeckInfo(
            id: "french",
            name: "French Vocabulary",
            description: "Common French words and their English translations",
            icon: "character.book.closed.fill",
            color: "cyan",
            csvFileName: "french",
            cardCount: 497,
            tags: ["Language", "French"]
        )
    ]
    
    /// Install a starter deck from its bundled CSV file
    static func installDeck(_ info: StarterDeckInfo, modelContext: ModelContext) throws {
        guard let url = Bundle.main.url(forResource: info.csvFileName, withExtension: "csv") else {
            throw StarterDeckError.fileNotFound
        }
        
        let content = try String(contentsOf: url, encoding: .utf8)
        let rows = parseCSV(content)
        
        // Skip header row
        let dataRows = rows.dropFirst()
        
        let deck = Deck(
            name: info.name,
            deckDescription: info.description,
            tags: info.tags,
            color: info.color,
            icon: info.icon
        )
        modelContext.insert(deck)
        
        for columns in dataRows {
            guard columns.count >= 2 else { continue }
            let front = columns[0].trimmingCharacters(in: .whitespacesAndNewlines)
            let back = columns[1].trimmingCharacters(in: .whitespacesAndNewlines)
            guard !front.isEmpty && !back.isEmpty else { continue }
            
            let hint: String? = columns.count >= 3 ? columns[2].trimmingCharacters(in: .whitespacesAndNewlines) : nil
            
            let card = Card(
                front: front,
                back: back,
                hint: hint?.isEmpty == true ? nil : hint
            )
            card.deck = deck
            modelContext.insert(card)
        }
        
        try modelContext.save()
    }
    
    /// Check if a starter deck is already installed by matching the name
    static func isInstalled(_ info: StarterDeckInfo, existingDecks: [Deck]) -> Bool {
        existingDecks.contains { $0.name == info.name }
    }
    
    /// Simple CSV parser that handles blank lines between rows
    private static func parseCSV(_ content: String) -> [[String]] {
        let normalized = content
            .replacingOccurrences(of: "\r\n", with: "\n")
            .replacingOccurrences(of: "\r", with: "\n")
        
        var results: [[String]] = []
        
        for line in normalized.components(separatedBy: "\n") {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard !trimmed.isEmpty else { continue }
            
            // Simple comma-split (handles the format of these specific CSVs)
            let columns = trimmed.components(separatedBy: ",")
            if columns.count >= 2 {
                results.append(columns)
            }
        }
        
        return results
    }
}

enum StarterDeckError: LocalizedError {
    case fileNotFound
    case importFailed
    
    var errorDescription: String? {
        switch self {
        case .fileNotFound: return "The starter deck file could not be found."
        case .importFailed: return "Failed to import the starter deck."
        }
    }
}
