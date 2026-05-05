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
    ///   - delimiter: CSV delimiter character (default: auto-detect, falls back to comma)
    /// - Returns: ImportResult with deck and statistics
    func importCSV(
        from url: URL,
        deckName: String? = nil,
        hasHeader: Bool = true,
        delimiter: Character? = nil
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
        
        // Auto-detect delimiter if not specified
        let actualDelimiter = delimiter ?? detectDelimiter(in: content)
        
        // Parse CSV lines
        let lines = parseCSVLines(content, delimiter: actualDelimiter)
        
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
        let maxErrorsToTrack = 100 // Limit error tracking to avoid memory issues
        
        // Process each row
        for (index, columns) in dataLines.enumerated() {
            let rowNumber = hasHeader ? index + 2 : index + 1
            
            // Need at least 2 columns (front, back)
            guard columns.count >= 2 else {
                cardsSkipped += 1
                if errors.count < maxErrorsToTrack {
                    errors.append("Row \(rowNumber): Not enough columns (need at least 2)")
                }
                continue
            }
            
            let front = columns[0].trimmingCharacters(in: .whitespacesAndNewlines)
            let back = columns[1].trimmingCharacters(in: .whitespacesAndNewlines)
            
            // Skip empty cards
            guard !front.isEmpty && !back.isEmpty else {
                cardsSkipped += 1
                if errors.count < maxErrorsToTrack {
                    errors.append("Row \(rowNumber): Empty front or back")
                }
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
        
        // Add summary if errors were truncated
        if cardsSkipped > maxErrorsToTrack {
            errors.append("... and \(cardsSkipped - maxErrorsToTrack) more rows skipped")
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
    
    /// Detect the most likely delimiter in the CSV content
    private func detectDelimiter(in content: String) -> Character {
        // Get the first few lines for analysis
        let lines = content.components(separatedBy: .newlines).prefix(5)
        
        let delimiters: [Character] = [",", ";", "\t", "|"]
        var scores: [Character: Int] = [:]
        
        for delimiter in delimiters {
            var counts: [Int] = []
            for line in lines where !line.isEmpty {
                // Count delimiters outside of quotes
                var count = 0
                var inQuotes = false
                for char in line {
                    if char == "\"" {
                        inQuotes.toggle()
                    } else if char == delimiter && !inQuotes {
                        count += 1
                    }
                }
                counts.append(count)
            }
            
            // Score based on consistency (same count across lines) and having at least 1 delimiter
            if let firstCount = counts.first, firstCount > 0 {
                let isConsistent = counts.allSatisfy { $0 == firstCount }
                scores[delimiter] = isConsistent ? firstCount * 10 : firstCount
            }
        }
        
        // Return delimiter with highest score, default to comma
        return scores.max(by: { $0.value < $1.value })?.key ?? ","
    }
    
    /// Parse CSV content into rows of columns, handling quoted fields
    private func parseCSVLines(_ content: String, delimiter: Character) -> [[String]] {
        var results: [[String]] = []
        var currentRow: [String] = []
        var currentField = ""
        var insideQuotes = false
        
        // Normalize line endings to \n
        let normalizedContent = content
            .replacingOccurrences(of: "\r\n", with: "\n")
            .replacingOccurrences(of: "\r", with: "\n")
        
        let chars = Array(normalizedContent)
        var i = 0
        
        while i < chars.count {
            let char = chars[i]
            
            if insideQuotes {
                if char == "\"" {
                    // Check for escaped quote ""
                    if i + 1 < chars.count && chars[i + 1] == "\"" {
                        currentField.append("\"")
                        i += 2
                        continue
                    } else {
                        // End of quoted field
                        insideQuotes = false
                    }
                } else if char == "\n" {
                    // Newline inside quotes - check if this looks like a real multi-line field
                    // or an unclosed quote. If the field is getting very long, assume unclosed quote.
                    if currentField.count > 10000 {
                        // Likely an unclosed quote - treat as end of row
                        insideQuotes = false
                        currentRow.append(currentField)
                        if currentRow.count > 0 {
                            results.append(currentRow)
                        }
                        currentRow = []
                        currentField = ""
                    } else {
                        // Allow newline inside quoted field
                        currentField.append(char)
                    }
                } else {
                    // Inside quotes, add character
                    currentField.append(char)
                }
            } else {
                if char == "\"" && currentField.isEmpty {
                    // Start of quoted field (only if at beginning of field)
                    insideQuotes = true
                } else if char == "\"" {
                    // Quote in middle of unquoted field - just add it
                    currentField.append(char)
                } else if char == delimiter {
                    // End of field
                    currentRow.append(currentField)
                    currentField = ""
                } else if char == "\n" {
                    // End of row
                    currentRow.append(currentField)
                    // Only add row if it has content
                    if currentRow.count > 0 {
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
        
        // Handle last field/row (file might not end with newline)
        currentRow.append(currentField)
        if currentRow.count > 0 && !currentRow.allSatisfy({ $0.trimmingCharacters(in: .whitespaces).isEmpty }) {
            results.append(currentRow)
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
