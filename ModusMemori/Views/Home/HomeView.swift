import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var decks: [Deck]
    @Query(sort: \StudySession.startTime, order: .reverse) private var recentSessions: [StudySession]
    
    private var totalCardsDue: Int {
        decks.reduce(0) { $0 + $1.cardsDueCount }
    }
    
    private var totalCards: Int {
        decks.reduce(0) { $0 + $1.cardsCount }
    }
    
    private var statisticsService: StatisticsService {
        StatisticsService(modelContext: modelContext)
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Welcome Header
                    welcomeHeader
                    
                    // Quick Stats
                    quickStatsSection
                    
                    // Due Cards Section
                    if totalCardsDue > 0 {
                        dueCardsSection
                    }
                    
                    // Recent Decks
                    if !decks.isEmpty {
                        recentDecksSection
                    } else {
                        emptyStateView
                    }
                }
                .padding()
            }
            .navigationTitle("ModusMemori")
        }
    }
    
    private var welcomeHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(greeting)
                .font(.title2)
                .foregroundStyle(.secondary)
            
            if totalCardsDue > 0 {
                Text("You have \(totalCardsDue) cards to review")
                    .font(.headline)
            } else {
                Text("You're all caught up!")
                    .font(.headline)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 0..<12: return "Good morning!"
        case 12..<17: return "Good afternoon!"
        default: return "Good evening!"
        }
    }
    
    private var quickStatsSection: some View {
        HStack(spacing: 12) {
            StatCard(
                title: "Streak",
                value: "\(statisticsService.currentStreak())",
                icon: "flame.fill",
                color: .orange
            )
            
            StatCard(
                title: "Today",
                value: "\(statisticsService.cardsStudiedToday())",
                icon: "calendar",
                color: .blue
            )
            
            StatCard(
                title: "Due",
                value: "\(totalCardsDue)",
                icon: "clock.fill",
                color: .purple
            )
        }
    }
    
    private var dueCardsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Ready to Study")
                .font(.headline)
            
            ForEach(decks.filter { $0.cardsDueCount > 0 }.prefix(3)) { deck in
                NavigationLink {
                    DeckDetailView(deck: deck)
                } label: {
                    DueCardRow(deck: deck)
                }
                .buttonStyle(.plain)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private var recentDecksSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Your Decks")
                .font(.headline)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(decks.prefix(4)) { deck in
                    NavigationLink {
                        DeckDetailView(deck: deck)
                    } label: {
                        DeckCard(deck: deck)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "rectangle.stack.badge.plus")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)
            
            Text("No decks yet")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Create your first deck to start learning")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            NavigationLink {
                DeckEditorView()
            } label: {
                Label("Create Deck", systemImage: "plus")
                    .font(.headline)
                    .padding()
                    .background(Color.accentColor)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .padding(.vertical, 40)
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
            
            Text(value)
                .font(.title)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct DueCardRow: View {
    let deck: Deck
    
    var body: some View {
        HStack {
            Image(systemName: deck.icon)
                .font(.title2)
                .foregroundStyle(Color(deck.color))
                .frame(width: 44, height: 44)
                .background(Color(deck.color).opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            
            VStack(alignment: .leading) {
                Text(deck.name)
                    .font(.headline)
                
                Text("\(deck.cardsDueCount) cards due")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct DeckCard: View {
    let deck: Deck
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: deck.icon)
                .font(.title)
                .foregroundStyle(Color(deck.color))
            
            Text(deck.name)
                .font(.headline)
                .lineLimit(1)
            
            Text("\(deck.cardsCount) cards")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// Color extension for deck colors
extension Color {
    init(_ name: String) {
        switch name.lowercased() {
        case "blue": self = .blue
        case "red": self = .red
        case "green": self = .green
        case "orange": self = .orange
        case "purple": self = .purple
        case "pink": self = .pink
        case "yellow": self = .yellow
        case "teal": self = .teal
        case "indigo": self = .indigo
        default: self = .blue
        }
    }
}

#Preview {
    HomeView()
        .modelContainer(for: [Deck.self, Card.self, StudySession.self, Review.self], inMemory: true)
}
