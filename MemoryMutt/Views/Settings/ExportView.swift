import SwiftUI
import SwiftData

struct ExportView: View {
    @Query(sort: \Deck.name) private var decks: [Deck]

    private var sortedDecks: [Deck] { decks }

    var body: some View {
        List {
            ForEach(sortedDecks) { deck in
                DeckExportRow(deck: deck)
            }
        }
        .overlay {
            if sortedDecks.isEmpty {
                ContentUnavailableView("No Decks", systemImage: "rectangle.stack")
            }
        }
        .navigationTitle("Export Data")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct DeckExportRow: View {
    @Environment(\.modelContext) private var modelContext
    let deck: Deck

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: deck.icon)
                .foregroundStyle(Color(deck.color))
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 2) {
                Text(deck.name)
                Text("\(deck.cardsCount) cards")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            ShareLink(item: csvContent, subject: Text(deck.name)) {
                Image(systemName: "square.and.arrow.up")
                    .foregroundStyle(Color.accentColor)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 2)
    }

    private var csvContent: String {
        CSVImportService(modelContext: modelContext).exportCSV(deck: deck)
    }
}

#Preview {
    ExportView()
        .modelContainer(for: [Deck.self, Card.self, StudySession.self, Review.self], inMemory: true)
}
