import Foundation
import SwiftData

@MainActor
class StatisticsService {
    
    private let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    // MARK: - Card Statistics
    
    /// Get total number of cards across all decks
    func totalCards() -> Int {
        let descriptor = FetchDescriptor<Card>()
        return (try? modelContext.fetchCount(descriptor)) ?? 0
    }
    
    /// Get count of cards by status
    func cardsByStatus() -> [CardStatus: Int] {
        var result: [CardStatus: Int] = [:]
        for status in CardStatus.allCases {
            let descriptor = FetchDescriptor<Card>(
                predicate: #Predicate { $0.statusRawValue == status.rawValue }
            )
            result[status] = (try? modelContext.fetchCount(descriptor)) ?? 0
        }
        return result
    }
    
    /// Get number of cards due for review
    func cardsDueCount() -> Int {
        let now = Date()
        let descriptor = FetchDescriptor<Card>(
            predicate: #Predicate { $0.nextReviewDate <= now }
        )
        return (try? modelContext.fetchCount(descriptor)) ?? 0
    }
    
    // MARK: - Study Statistics
    
    /// Get cards studied in a date range
    func cardsStudied(from startDate: Date, to endDate: Date) -> Int {
        let descriptor = FetchDescriptor<Review>(
            predicate: #Predicate { $0.reviewedAt >= startDate && $0.reviewedAt <= endDate }
        )
        return (try? modelContext.fetchCount(descriptor)) ?? 0
    }
    
    /// Get cards studied today
    func cardsStudiedToday() -> Int {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? Date()
        return cardsStudied(from: startOfDay, to: endOfDay)
    }
    
    /// Get cards studied this week
    func cardsStudiedThisWeek() -> Int {
        let calendar = Calendar.current
        let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date())) ?? Date()
        return cardsStudied(from: startOfWeek, to: Date())
    }
    
    /// Get cards studied this month
    func cardsStudiedThisMonth() -> Int {
        let calendar = Calendar.current
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: Date())) ?? Date()
        return cardsStudied(from: startOfMonth, to: Date())
    }
    
    // MARK: - Streak Calculation
    
    /// Calculate current study streak (consecutive days)
    func currentStreak() -> Int {
        let calendar = Calendar.current
        var streak = 0
        var checkDate = calendar.startOfDay(for: Date())
        
        // Check if studied today
        let todayCount = cardsStudied(
            from: checkDate,
            to: calendar.date(byAdding: .day, value: 1, to: checkDate) ?? Date()
        )
        
        if todayCount == 0 {
            // Check yesterday instead
            checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate) ?? checkDate
        }
        
        // Count consecutive days
        while true {
            let dayStart = checkDate
            let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart) ?? dayStart
            
            let count = cardsStudied(from: dayStart, to: dayEnd)
            if count > 0 {
                streak += 1
                checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate) ?? checkDate
            } else {
                break
            }
            
            // Safety limit
            if streak > 365 { break }
        }
        
        return streak
    }
    
    // MARK: - Session Statistics
    
    /// Get total study sessions
    func totalSessions() -> Int {
        let descriptor = FetchDescriptor<StudySession>()
        return (try? modelContext.fetchCount(descriptor)) ?? 0
    }
    
    /// Get average accuracy across all sessions
    func averageAccuracy() -> Double {
        let descriptor = FetchDescriptor<StudySession>(
            predicate: #Predicate { $0.cardsStudied > 0 }
        )
        guard let sessions = try? modelContext.fetch(descriptor), !sessions.isEmpty else {
            return 0
        }
        
        let totalAccuracy = sessions.reduce(0.0) { $0 + $1.accuracy }
        return totalAccuracy / Double(sessions.count)
    }
    
    /// Get total study time in seconds
    func totalStudyTime() -> TimeInterval {
        let descriptor = FetchDescriptor<StudySession>(
            predicate: #Predicate { $0.endTime != nil }
        )
        guard let sessions = try? modelContext.fetch(descriptor) else {
            return 0
        }
        
        return sessions.reduce(0) { $0 + $1.duration }
    }
    
    /// Get study activity for the last N days (for heatmap)
    func studyActivity(days: Int) -> [Date: Int] {
        var activity: [Date: Int] = [:]
        let calendar = Calendar.current
        
        for i in 0..<days {
            guard let date = calendar.date(byAdding: .day, value: -i, to: Date()) else { continue }
            let startOfDay = calendar.startOfDay(for: date)
            let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? startOfDay
            
            activity[startOfDay] = cardsStudied(from: startOfDay, to: endOfDay)
        }
        
        return activity
    }
}
