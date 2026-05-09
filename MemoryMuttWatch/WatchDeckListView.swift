import SwiftUI
import SwiftData

struct WatchDeckListView: View {
    @Query(sort: \Deck.name) private var decks: [Deck]

    var body: some View {
        NavigationStack {
            List {
                ForEach(decks) { deck in
                    NavigationLink {
                        WatchStudyView(deck: deck)
                    } label: {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(deck.name)
                                .font(.body)
                            let due = deck.cardsDueCount
                            if due > 0 {
                                Text("\(due) due")
                                    .font(.caption2)
                                    .foregroundStyle(.orange)
                            } else {
                                Text("Up to date")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
            .navigationTitle("MemoryMutt")
            .overlay {
                if decks.isEmpty {
                    ContentUnavailableView("No Decks", systemImage: "rectangle.stack")
                }
            }
        }
    }
}
