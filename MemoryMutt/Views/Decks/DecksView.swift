import SwiftUI
import SwiftData

struct DecksView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Deck.updatedAt, order: .reverse) private var decks: [Deck]
    
    @State private var searchText = ""
    @State private var showingNewDeck = false
    @State private var showingImportCSV = false
    @State private var sortOrder: SortOrder = .recent
    @State private var viewMode: ViewMode = .grid
    @State private var showingStarterDecks = false
    @State private var deckToEdit: Deck?
    
    enum SortOrder: String, CaseIterable {
        case recent = "Recent"
        case name = "Name"
        case cardCount = "Card Count"
    }
    
    enum ViewMode: String, CaseIterable {
        case grid = "Grid"
        case list = "List"
    }
    
    private var filteredDecks: [Deck] {
        let filtered = searchText.isEmpty ? decks : decks.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.tags.contains { $0.localizedCaseInsensitiveContains(searchText) }
        }
        
        switch sortOrder {
        case .recent:
            return filtered
        case .name:
            return filtered.sorted { $0.name < $1.name }
        case .cardCount:
            return filtered.sorted { $0.cardsCount > $1.cardsCount }
        }
    }
    
    var body: some View {
        NavigationStack {
            Group {
                if decks.isEmpty {
                    emptyStateView
                } else {
                    deckListContent
                }
            }
            .navigationTitle("Decks")
            .searchable(text: $searchText, prompt: "Search decks")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button {
                            showingNewDeck = true
                        } label: {
                            Label("New Deck", systemImage: "plus")
                        }
                        
                        Button {
                            showingImportCSV = true
                        } label: {
                            Label("Import CSV", systemImage: "square.and.arrow.down")
                        }
                    } label: {
                        Image(systemName: "plus")
                    }
                }
                
                ToolbarItem(placement: .secondaryAction) {
                    Menu {
                        Picker("Sort", selection: $sortOrder) {
                            ForEach(SortOrder.allCases, id: \.self) { order in
                                Text(order.rawValue).tag(order)
                            }
                        }
                        
                        Picker("View", selection: $viewMode) {
                            Label("Grid", systemImage: "square.grid.2x2").tag(ViewMode.grid)
                            Label("List", systemImage: "list.bullet").tag(ViewMode.list)
                        }
                    } label: {
                        Image(systemName: "arrow.up.arrow.down")
                    }
                }
            }
            .sheet(isPresented: $showingNewDeck) {
                DeckEditorView()
            }
            .sheet(item: $deckToEdit) { deck in
                DeckEditorView(deck: deck)
            }
            .sheet(isPresented: $showingImportCSV) {
                CSVImportView()
            }
        }
    }
    
    private var deckListContent: some View {
        ScrollView {
            if viewMode == .grid {
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 16) {
                    ForEach(filteredDecks) { deck in
                        NavigationLink {
                            DeckDetailView(deck: deck)
                        } label: {
                            DeckGridItem(deck: deck)
                        }
                        .buttonStyle(.plain)
                        .contextMenu {
                            deckContextMenu(deck: deck)
                        }
                    }
                }
                .padding()
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(filteredDecks) { deck in
                        NavigationLink {
                            DeckDetailView(deck: deck)
                        } label: {
                            DeckListItem(deck: deck)
                        }
                        .buttonStyle(.plain)
                        .contextMenu {
                            deckContextMenu(deck: deck)
                        }
                    }
                }
                .padding()
            }
            
            // Starter decks section
            if !hasAddedAllStarterDecks {
                starterDecksSection
            }
        }
    }
    
    private var hasAddedAllStarterDecks: Bool {
        StarterDeckService.availableDecks.allSatisfy { info in
            StarterDeckService.isInstalled(info, existingDecks: decks)
        }
    }
    
    private var starterDecksSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button {
                withAnimation {
                    showingStarterDecks.toggle()
                }
            } label: {
                HStack {
                    Text("Starter Decks")
                        .font(.headline)
                        .foregroundStyle(.primary)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .rotationEffect(.degrees(showingStarterDecks ? 90 : 0))
                }
            }
            .buttonStyle(.plain)
            
            if showingStarterDecks {
                StarterDecksView()
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 20)
    }
    
    @ViewBuilder
    private func deckContextMenu(deck: Deck) -> some View {
        Button {
            deckToEdit = deck
        } label: {
            Label("Edit", systemImage: "pencil")
        }
        
        Button(role: .destructive) {
            deleteDeck(deck)
        } label: {
            Label("Delete", systemImage: "trash")
        }
    }
    
    private var emptyStateView: some View {
        ScrollView {
            VStack(spacing: 30) {
                Spacer(minLength: 40)
                
                VStack(spacing: 12) {
                    Image(systemName: "rectangle.stack")
                        .font(.system(size: 50))
                        .foregroundStyle(.secondary)
                    
                    Text("No Decks")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Create your own deck or add a starter deck below")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                    
                    Button {
                        showingNewDeck = true
                    } label: {
                        Text("Create Deck")
                    }
                    .buttonStyle(.borderedProminent)
                }
                
                // Starter decks
                VStack(alignment: .leading, spacing: 12) {
                    Text("Starter Decks")
                        .font(.headline)
                    
                    StarterDecksView()
                }
                .padding(.horizontal, 20)
            }
        }
    }
    
    private func deleteDeck(_ deck: Deck) {
        modelContext.delete(deck)
    }
}

struct DeckGridItem: View {
    let deck: Deck
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: deck.icon)
                    .font(.title)
                    .foregroundStyle(Color(deck.color))
                
                Spacer()
                
                if deck.cardsDueCount > 0 {
                    Text("\(deck.cardsDueCount)")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.orange)
                        .foregroundStyle(.white)
                        .clipShape(Capsule())
                }
            }
            
            Text(deck.name)
                .font(.headline)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
            
            Text("\(deck.cardsCount) cards")
                .font(.caption)
                .foregroundStyle(.secondary)
            
            // Progress bar
            if deck.cardsCount > 0 {
                ProgressView(value: Double(deck.masteredCardsCount), total: Double(deck.cardsCount))
                    .tint(Color(deck.color))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

struct DeckListItem: View {
    let deck: Deck
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: deck.icon)
                .font(.title)
                .foregroundStyle(Color(deck.color))
                .frame(width: 50, height: 50)
                .background(Color(deck.color).opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            
            VStack(alignment: .leading, spacing: 4) {
                Text(deck.name)
                    .font(.headline)
                
                Text("\(deck.cardsCount) cards • \(deck.masteredCardsCount) mastered")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            if deck.cardsDueCount > 0 {
                Text("\(deck.cardsDueCount) due")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.orange)
                    .foregroundStyle(.white)
                    .clipShape(Capsule())
            }
            
            Image(systemName: "chevron.right")
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

#Preview {
    DecksView()
        .modelContainer(for: [Deck.self, Card.self, StudySession.self, Review.self], inMemory: true)
}
