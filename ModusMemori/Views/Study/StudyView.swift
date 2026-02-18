import SwiftUI
import SwiftData

struct StudyView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Deck.updatedAt, order: .reverse) private var decks: [Deck]
    
    @State private var selectedDeck: Deck?
    @State private var showingStudySession = false
    
    private var decksWithDueCards: [Deck] {
        decks.filter { $0.cardsDueCount > 0 || $0.newCardsCount > 0 }
    }
    
    private var totalDueCards: Int {
        decks.reduce(0) { $0 + $1.cardsDueCount }
    }
    
    private var totalNewCards: Int {
        decks.reduce(0) { $0 + $1.newCardsCount }
    }
    
    var body: some View {
        NavigationStack {
            Group {
                if decks.isEmpty {
                    emptyDecksView
                } else if decksWithDueCards.isEmpty {
                    allCaughtUpView
                } else {
                    studyContent
                }
            }
            .navigationTitle("Study")
            .fullScreenCover(item: $selectedDeck) { deck in
                StudySessionView(deck: deck)
            }
        }
    }
    
    private var studyContent: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Summary Card
                summaryCard
                
                // Decks ready to study
                VStack(alignment: .leading, spacing: 12) {
                    Text("Ready to Study")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    ForEach(decksWithDueCards) { deck in
                        StudyDeckRow(deck: deck) {
                            selectedDeck = deck
                        }
                        .padding(.horizontal)
                    }
                }
            }
            .padding(.vertical)
        }
    }
    
    private var summaryCard: some View {
        VStack(spacing: 16) {
            HStack(spacing: 30) {
                VStack {
                    Text("\(totalDueCards)")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundStyle(.orange)
                    Text("Due")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                VStack {
                    Text("\(totalNewCards)")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundStyle(.green)
                    Text("New")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            
            if let firstDeck = decksWithDueCards.first {
                Button {
                    selectedDeck = firstDeck
                } label: {
                    Label("Start Studying", systemImage: "play.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal)
    }
    
    private var emptyDecksView: some View {
        ContentUnavailableView {
            Label("No Decks", systemImage: "rectangle.stack")
        } description: {
            Text("Create a deck and add some cards to start studying")
        }
    }
    
    private var allCaughtUpView: some View {
        ContentUnavailableView {
            Label("All Caught Up!", systemImage: "checkmark.circle.fill")
        } description: {
            Text("Great job! You've reviewed all your due cards. Check back later or add more cards to your decks.")
        }
    }
}

struct StudyDeckRow: View {
    let deck: Deck
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: deck.icon)
                    .font(.title2)
                    .foregroundStyle(Color(deck.color))
                    .frame(width: 50, height: 50)
                    .background(Color(deck.color).opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(deck.name)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    
                    HStack(spacing: 12) {
                        if deck.cardsDueCount > 0 {
                            Label("\(deck.cardsDueCount) due", systemImage: "clock")
                                .font(.caption)
                                .foregroundStyle(.orange)
                        }
                        
                        if deck.newCardsCount > 0 {
                            Label("\(deck.newCardsCount) new", systemImage: "sparkles")
                                .font(.caption)
                                .foregroundStyle(.green)
                        }
                    }
                }
                
                Spacer()
                
                Image(systemName: "play.circle.fill")
                    .font(.title)
                    .foregroundStyle(Color.accentColor)
            }
            .padding()
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    StudyView()
        .modelContainer(for: [Deck.self, Card.self, StudySession.self, Review.self], inMemory: true)
}
