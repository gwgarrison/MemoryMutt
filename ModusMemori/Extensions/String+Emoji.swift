import Foundation

extension String {
    /// Returns true if the string is composed entirely of emoji characters.
    var isEmoji: Bool {
        let trimmed = self.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return false }
        return trimmed.unicodeScalars.allSatisfy { scalar in
            scalar.properties.isEmoji && scalar.value > 0x23
        }
    }
}
