import SwiftUI

struct WatchDeckListView: View {
    @State private var connectivity = WatchConnectivityService.shared

    var body: some View {
        NavigationStack {
            Group {
                if connectivity.isLoading {
                    VStack(spacing: 8) {
                        ProgressView()
                        Text("Connecting…")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                } else if connectivity.decks.isEmpty {
                    emptyView
                } else {
                    deckList
                }
            }
            .navigationTitle("MemoryMutt")
            .onAppear { connectivity.requestDecks() }
        }
    }

    private var deckList: some View {
        List(connectivity.decks) { deck in
            NavigationLink {
                WatchStudyView(deck: deck)
            } label: {
                VStack(alignment: .leading, spacing: 2) {
                    Text(deck.name)
                        .font(.body)
                    Text("\(deck.dueCount) due")
                        .font(.caption2)
                        .foregroundStyle(.orange)
                }
            }
        }
    }

    private var emptyView: some View {
        VStack(spacing: 8) {
            if let error = connectivity.errorMessage {
                Image(systemName: "iphone.slash")
                    .font(.title2)
                Text(error)
                    .font(.caption)
                    .multilineTextAlignment(.center)
            } else {
                Image(systemName: "checkmark.circle")
                    .font(.title2)
                Text("No cards due")
                    .font(.caption)
            }
            Button("Refresh") { connectivity.requestDecks() }
                .font(.caption2)
        }
    }
}
