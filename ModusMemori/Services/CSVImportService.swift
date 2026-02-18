import Foundation
import SwiftData
import UniformTypeIdentifiers

/// Service for importing and exporting deck data via CSV files
@MainActor
class CSVImportService {
    
    private let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    /// Supported CSV formats
    enum CSVFormat {
        case standard      // front,back
        case withHint      // front,back,hint
        case ankiBasic     // front,back (Anki export format)
        
        var expectedColumns: Int {
            switch self {
            case .standard, .ankiBasic: return 2
            case .withHint: return 3
            }
        }
    }
    
    /// Import result containing success/failure information
    struct ImportResult {
        let deck: Deck?
        let cardsImported: Int
        let cardsSkipped: Int
        let errors: [String]
        
        var isSuccess: Bool { deck != nil && errors.isEmpty }
    }
    
    /// Parse a CSV file and create a deck with cards
    /// - Parameters:
    ///   - url: URL to the CSV file
    ///   - deckName: Name for the new deck (defaults to filename)
    ///   - hasHeader: Whether the CSV has a header row to skip
    ///   - delimiter: CSV delimiter character (default: comma)
    /// - Returns: ImportResult with deck and statistics
    func importCSV(
        from url: URL,
        deckName: String? = nil,
        hasHeader: Bool = true,
        delimiter: Character = ","
    ) throws -> ImportResult {
        
        // Start accessing security-scoped resource
        guard url.startAccessingSecurityScopedResource() else {
            throw ImportError.accessDenied
        }
        defer { url.stopAccessingSecurityScopedResource() }
        
        // Read file content
        let content: String
        do {
            content = try String(contentsOf: url, encoding: .utf8)
        } catch {
            // Try other encodings
            if let latin1Content = try? String(contentsOf: url, encoding: .isoLatin1) {
                content = latin1Content
            } else {
                throw ImportError.unreadableFile
            }
        }
        
        // Parse CSV lines
        let lines = parseCSVLines(content, delimiter: delimiter)
        
        guard !lines.isEmpty else {
            throw ImportError.emptyFile
        }
        
        // Skip header if present
        let dataLines = hasHeader ? Array(lines.dropFirst()) : lines
        
        guard !dataLines.isEmpty else {
            throw ImportError.noDataRows
        }
        
        // Determine deck name
        let finalDeckName = deckName ?? url.deletingPathExtension().lastPathComponent
        
        // Create deck
        let deck = Deck(name: finalDeckName)
        modelContext.insert(deck)
        
        var cardsImported = 0
        var cardsSkipped = 0
        var errors: [String] = []
        
        // Process each row
        for (index, columns) in dataLines.enumerated() {
            let rowNumber = hasHeader ? index + 2 : index + 1
            
            // Need at least 2 columns (front, back)
            guard columns.count >= 2 else {
                cardsSkipped += 1
                errors.append("Row \(rowNumber): Not enough columns (need at least 2)")
                continue
            }
            
            let front = columns[0].trimmingCharacters(in: .whitespacesAndNewlines)
            let back = columns[1].trimmingCharacters(in: .whitespacesAndNewlines)
            
            // Skip empty cards
            guard !front.isEmpty && !back.isEmpty else {
                cardsSkipped += 1
                errors.append("Row \(rowNumber): Empty front or back")
                continue
            }
            
            // Get optional hint
            let hint: String? = columns.count >= 3 ? columns[2].trimmingCharacters(in: .whitespacesAndNewlines) : nil
            
            // Create card
            let card = Card(
                front: front,
                back: back,
                hint: hint?.isEmpty == true ? nil : hint
            )
            card.deck = deck
            modelContext.insert(card)
            cardsImported += 1
        }
        
        // If no cards were imported, delete the deck
        if cardsImported == 0 {
            modelContext.delete(deck)
            throw ImportError.noValidCards
        }
        
        // Save changes
        try modelContext.save()
        
        return ImportResult(
            deck: deck,
            cardsImported: cardsImported,
            cardsSkipped: cardsSkipped,
            errors: errors
        )
    }
    
    /// Parse CSV content into rows of columns, handling quoted fields
    private func parseCSVLines(_ content: String, delimiter: Character) -> [[String]] {
        var results: [[String]] = []
        var currentRow: [String] = []
        var currentField = ""
        var insideQuotes = false
        
        let chars = Array(content)
        var i = 0
        
        while i < chars.count {
            let char = chars[i]
            
            if insideQuotes {
                if char == "\"" {
                    // Check for escaped quote
                    if i + 1 < chars.count && chars[i + 1] == "\"" {
                        currentField.append("\"")
                        i += 2
                        continue
                    } else {
                        insideQuotes = false
                    }
                } else {
                    currentField.append(char)
                }
            } else {
                if char == "\"" {
                    insideQuotes = true
                } else if char == delimiter {
                    currentRow.append(currentField)
                    currentField = ""
                } else if char == "\n" || char == "\r" {
                    // Handle \r\n
                    if char == "\r" && i + 1 < chars.count && chars[i + 1] == "\n" {
                        i += 1
                    }
                    currentRow.append(currentField)
                    if !currentRow.allSatisfy({ $0.isEmpty }) {
                        results.append(currentRow)
                    }
                    currentRow = []
                    currentField = ""
                } else {
                    currentField.append(char)
                }
            }
            i += 1
        }
        
        // Handle last field/row
        if !currentField.isEmpty || !currentRow.isEmpty {
            currentRow.append(currentField)
            if !currentRow.allSatisfy({ $0.isEmpty }) {
                results.append(currentRow)
            }
        }
        
        return results
    }
    
    /// Export a deck to CSV format
    func exportCSV(deck: Deck, includeHints: Bool = true) -> String {
        var csv = includeHints ? "front,back,hint\n" : "front,back\n"
        
        for card in deck.cards {
            let front = escapeCSVField(card.front)
            let back = escapeCSVField(card.back)
            
            if includeHints {
                let hint = escapeCSVField(card.hint ?? "")
                csv += "\(front),\(back),\(hint)\n"
            } else {
                csv += "\(front),\(back)\n"
            }
        }
        
        return csv
    }
    
    /// Escape a field for CSV (wrap in quotes if needed)
    private func escapeCSVField(_ field: String) -> String {
        if field.contains(",") || field.contains("\"") || field.contains("\n") {
            let escaped = field.replacingOccurrences(of: "\"", with: "\"\"")
            return "\"\(escaped)\""
        }
        return field
    }
}

/// Errors that can occur during CSV import
enum ImportError: LocalizedError {
    case accessDenied
    case unreadableFile
    case emptyFile
    case noDataRows
    case noValidCards
    case invalidFormat
    
    var errorDescription: String? {
        switch self {
        case .accessDenied:
            return "Could not access the file. Please try again."
        case .unreadableFile:
            return "Could not read the file. Please ensure it's a valid text file."
        case .emptyFile:
            return "The file is empty."
        case .noDataRows:
            return "No data rows found in the file."
        case .noValidCards:
            return "No valid cards could be imported from the file."
        case .invalidFormat:
            return "The file format is not supported."
        }
    }
}

/// UTType for CSV files
extension UTType {
    static var csv: UTType {
        UTType(filenameExtension: "csv") ?? .commaSeparatedText
    }
}
