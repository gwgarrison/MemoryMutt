import SwiftUI
import SwiftData

enum CardSortOrder: String, CaseIterable {
    case recent = "Recent"
    case difficulty = "Difficulty"
}

struct DeckDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Bindable var deck: Deck

    @State private var showingAddCard = false
    @State private var showingEditDeck = false
    @State private var showingStudySession = false
    @State private var showingDeleteAlert = false
    @State private var searchText = ""
    @State private var sortOrder: CardSortOrder = .recent

    private var filteredCards: [Card] {
        let base: [Card]
        if searchText.isEmpty {
            base = deck.cards
        } else {
            base = deck.cards.filter {
                $0.front.localizedCaseInsensitiveContains(searchText) ||
                $0.back.localizedCaseInsensitiveContains(searchText)
            }
        }
        switch sortOrder {
        case .recent:
            return base.sorted { $0.createdAt > $1.createdAt }
        case .difficulty:
            return base.sorted { lhs, rhs in
                if lhs.reviews.isEmpty && rhs.reviews.isEmpty { return lhs.createdAt > rhs.createdAt }
                if lhs.reviews.isEmpty { return false }
                if rhs.reviews.isEmpty { return true }
                return lhs.accuracy < rhs.accuracy
            }
        }
    }
    
    var body: some View {
        List {
            // Stats Section
            Section {
                statsView
            }
            
            // Study Button
            if !deck.cards.isEmpty {
                Section {
                    Button {
                        showingStudySession = true
                    } label: {
                        HStack {
                            Image(systemName: "play.fill")
                            Text("Study Now")
                            Spacer()
                            if deck.cardsDueCount > 0 {
                                Text("\(deck.cardsDueCount) due")
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .font(.headline)
                }
            }
            
            // Cards Section
            Section {
                if deck.cards.isEmpty {
                    ContentUnavailableView {
                        Label("No Cards", systemImage: "rectangle.on.rectangle")
                    } description: {
                        Text("Add cards to this deck to start studying")
                    } actions: {
                        Button {
                            showingAddCard = true
                        } label: {
                            Text("Add Card")
                        }
                        .buttonStyle(.borderedProminent)
                    }
                } else {
                    ForEach(filteredCards) { card in
                        NavigationLink {
                            CardEditorView(deck: deck, card: card)
                        } label: {
                            CardRow(card: card)
                        }
                    }
                    .onDelete(perform: deleteCards)
                }
            } header: {
                HStack {
                    Text("Cards (\(deck.cardsCount))")
                    Spacer()
                    Button {
                        showingAddCard = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                    }
                }
            }
        }
        .navigationTitle(deck.name)
        .searchable(text: $searchText, prompt: "Search cards")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button {
                        showingAddCard = true
                    } label: {
                        Label("Add Card", systemImage: "plus")
                    }
                    
                    Button {
                        showingEditDeck = true
                    } label: {
                        Label("Edit Deck", systemImage: "pencil")
                    }

                    Divider()

                    Menu("Sort By") {
                        ForEach(CardSortOrder.allCases, id: \.self) { order in
                            Button {
                                sortOrder = order
                            } label: {
                                if sortOrder == order {
                                    Label(order.rawValue, systemImage: "checkmark")
                                } else {
                                    Text(order.rawValue)
                                }
                            }
                        }
                    }

                    Divider()

                    Button(role: .destructive) {
                        showingDeleteAlert = true
                    } label: {
                        Label("Delete Deck", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showingAddCard) {
            CardEditorView(deck: deck)
        }
        .sheet(isPresented: $showingEditDeck) {
            DeckEditorView(deck: deck)
        }
        .fullScreenCover(isPresented: $showingStudySession) {
            StudySessionView(deck: deck)
        }
        .alert("Delete Deck", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                deleteDeck()
            }
        } message: {
            Text("Are you sure you want to delete '\(deck.name)'? This will also delete all \(deck.cardsCount) cards. This action cannot be undone.")
        }
    }
    
    private var statsView: some View {
        HStack(spacing: 20) {
            StatItem(value: deck.cardsCount, label: "Total", color: .blue)
            StatItem(value: deck.newCardsCount, label: "New", color: .green)
            StatItem(value: deck.cardsDueCount, label: "Due", color: .orange)
            StatItem(value: deck.masteredCardsCount, label: "Mastered", color: .purple)
        }
        .padding(.vertical, 8)
    }
    
    private func deleteCards(at offsets: IndexSet) {
        for index in offsets {
            let card = filteredCards[index]
            modelContext.delete(card)
        }
    }
    
    private func deleteDeck() {
        modelContext.delete(deck)
        dismiss()
    }
}

struct StatItem: View {
    let value: Int
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text("\(value)")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(color)
            
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct CardRow: View {
    let card: Card
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(card.front)
                .font(card.front.isEmoji ? .system(size: 40) : .headline)
                .lineLimit(1)
            
            Text(card.back)
                .font(card.back.isEmoji ? .system(size: 40) : .subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(1)
            
            HStack {
                StatusBadge(status: card.status)

                if card.isDue {
                    Text("Due")
                        .font(.caption2)
                        .fontWeight(.medium)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.orange.opacity(0.2))
                        .foregroundStyle(.orange)
                        .clipShape(Capsule())
                }

                if !card.reviews.isEmpty && card.accuracy < 70 {
                    let isHard = card.accuracy < 50
                    Text(isHard ? "Hard" : "Tricky")
                        .font(.caption2)
                        .fontWeight(.medium)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background((isHard ? Color.red : Color.yellow).opacity(0.2))
                        .foregroundStyle(isHard ? .red : .yellow)
                        .clipShape(Capsule())
                }
            }
        }
        .padding(.vertical, 4)
    }
}

struct StatusBadge: View {
    let status: CardStatus
    
    var color: Color {
        switch status {
        case .new: return .green
        case .learning: return .blue
        case .review: return .orange
        case .mastered: return .purple
        }
    }
    
    var body: some View {
        Text(status.displayName)
            .font(.caption2)
            .fontWeight(.medium)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(color.opacity(0.2))
            .foregroundStyle(color)
            .clipShape(Capsule())
    }
}

#Preview {
    NavigationStack {
        DeckDetailView(deck: Deck(name: "Sample Deck"))
    }
    .modelContainer(for: [Deck.self, Card.self, StudySession.self, Review.self], inMemory: true)
}
