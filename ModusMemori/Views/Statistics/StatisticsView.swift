import SwiftUI
import SwiftData

struct StatisticsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var decks: [Deck]
    @Query(sort: \StudySession.startTime, order: .reverse) private var sessions: [StudySession]
    @Query private var reviews: [Review]
    
    private var statisticsService: StatisticsService {
        StatisticsService(modelContext: modelContext)
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Streak Section
                    streakSection
                    
                    // Study Overview
                    studyOverviewSection
                    
                    // Card Statistics
                    cardStatisticsSection
                    
                    // Activity Heatmap
                    activitySection
                    
                    // Recent Sessions
                    recentSessionsSection
                }
                .padding()
            }
            .navigationTitle("Statistics")
        }
    }
    
    private var streakSection: some View {
        HStack(spacing: 20) {
            VStack(spacing: 8) {
                Image(systemName: "flame.fill")
                    .font(.largeTitle)
                    .foregroundStyle(.orange)
                
                Text("\(statisticsService.currentStreak())")
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                
                Text("Day Streak")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }
    
    private var studyOverviewSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Study Overview")
                .font(.headline)
            
            HStack(spacing: 12) {
                OverviewCard(
                    title: "Today",
                    value: "\(statisticsService.cardsStudiedToday())",
                    icon: "calendar",
                    color: .blue
                )
                
                OverviewCard(
                    title: "This Week",
                    value: "\(statisticsService.cardsStudiedThisWeek())",
                    icon: "calendar.badge.clock",
                    color: .green
                )
                
                OverviewCard(
                    title: "This Month",
                    value: "\(statisticsService.cardsStudiedThisMonth())",
                    icon: "calendar.circle",
                    color: .purple
                )
            }
        }
    }
    
    private var cardStatisticsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Card Progress")
                .font(.headline)
            
            let cardsByStatus = statisticsService.cardsByStatus()
            let totalCards = statisticsService.totalCards()
            
            VStack(spacing: 16) {
                // Progress bars for each status
                CardProgressRow(
                    label: "New",
                    count: cardsByStatus[.new] ?? 0,
                    total: totalCards,
                    color: .green
                )
                
                CardProgressRow(
                    label: "Learning",
                    count: cardsByStatus[.learning] ?? 0,
                    total: totalCards,
                    color: .blue
                )
                
                CardProgressRow(
                    label: "Review",
                    count: cardsByStatus[.review] ?? 0,
                    total: totalCards,
                    color: .orange
                )
                
                CardProgressRow(
                    label: "Mastered",
                    count: cardsByStatus[.mastered] ?? 0,
                    total: totalCards,
                    color: .purple
                )
            }
            .padding()
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }
    
    private var activitySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Activity (Last 30 Days)")
                .font(.headline)
            
            let activity = statisticsService.studyActivity(days: 30)
            
            ActivityHeatmap(activity: activity)
                .padding()
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }
    
    private var recentSessionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Sessions")
                .font(.headline)
            
            if sessions.isEmpty {
                Text("No study sessions yet")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            } else {
                ForEach(sessions.prefix(5)) { session in
                    SessionRow(session: session)
                }
            }
        }
    }
}

struct OverviewCard: View {
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

struct CardProgressRow: View {
    let label: String
    let count: Int
    let total: Int
    let color: Color
    
    private var percentage: Double {
        guard total > 0 else { return 0 }
        return Double(count) / Double(total)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(label)
                    .font(.subheadline)
                Spacer()
                Text("\(count)")
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color(.systemGray4))
                        .frame(height: 8)
                        .clipShape(Capsule())
                    
                    Rectangle()
                        .fill(color)
                        .frame(width: geometry.size.width * percentage, height: 8)
                        .clipShape(Capsule())
                }
            }
            .frame(height: 8)
        }
    }
}

struct ActivityHeatmap: View {
    let activity: [Date: Int]
    
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)
    
    var body: some View {
        LazyVGrid(columns: columns, spacing: 4) {
            ForEach(sortedDates, id: \.self) { date in
                let count = activity[date] ?? 0
                Rectangle()
                    .fill(colorForCount(count))
                    .aspectRatio(1, contentMode: .fit)
                    .clipShape(RoundedRectangle(cornerRadius: 2))
            }
        }
    }
    
    private var sortedDates: [Date] {
        activity.keys.sorted()
    }
    
    private func colorForCount(_ count: Int) -> Color {
        switch count {
        case 0: return Color(.systemGray4)
        case 1...5: return Color.green.opacity(0.3)
        case 6...15: return Color.green.opacity(0.5)
        case 16...30: return Color.green.opacity(0.7)
        default: return Color.green
        }
    }
}

struct SessionRow: View {
    let session: StudySession
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(session.deck?.name ?? "Unknown Deck")
                    .font(.headline)
                
                Text(session.startTime.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(session.cardsStudied) cards")
                    .font(.subheadline)
                
                Text(String(format: "%.0f%% accuracy", session.accuracy))
                    .font(.caption)
                    .foregroundStyle(session.accuracy >= 70 ? .green : .orange)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    StatisticsView()
        .modelContainer(for: [Deck.self, Card.self, StudySession.self, Review.self], inMemory: true)
}
