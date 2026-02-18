import SwiftUI

struct StudyCompletionView: View {
    let session: StudySession?
    let onDismiss: () -> Void
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            // Celebration Icon
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 80))
                .foregroundStyle(.green)
            
            Text("Session Complete!")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            if let session = session {
                // Stats
                VStack(spacing: 20) {
                    HStack(spacing: 40) {
                        CompletionStat(
                            value: "\(session.cardsStudied)",
                            label: "Cards Studied",
                            icon: "rectangle.stack.fill"
                        )
                        
                        CompletionStat(
                            value: String(format: "%.0f%%", session.accuracy),
                            label: "Accuracy",
                            icon: "target"
                        )
                    }
                    
                    HStack(spacing: 40) {
                        CompletionStat(
                            value: session.durationFormatted,
                            label: "Time Spent",
                            icon: "clock.fill"
                        )
                        
                        CompletionStat(
                            value: "\(session.cardsNew)",
                            label: "New Cards",
                            icon: "sparkles"
                        )
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .padding(.horizontal)
            }
            
            // Motivational message
            Text(motivationalMessage)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Spacer()
            
            Button {
                onDismiss()
            } label: {
                Text("Done")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 30)
        }
    }
    
    private var motivationalMessage: String {
        guard let session = session else {
            return "Keep up the great work!"
        }
        
        if session.accuracy >= 90 {
            return "Excellent! You're mastering this material! 🌟"
        } else if session.accuracy >= 70 {
            return "Great job! Keep practicing to improve even more! 💪"
        } else if session.accuracy >= 50 {
            return "Good effort! Regular practice makes perfect! 📚"
        } else {
            return "Don't give up! Each review helps you learn! 🎯"
        }
    }
}

struct CompletionStat: View {
    let value: String
    let label: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.secondary)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(minWidth: 100)
    }
}

#Preview {
    StudyCompletionView(
        session: StudySession(
            cardsStudied: 15,
            cardsNew: 5,
            cardsReview: 10,
            correctCount: 12
        )
    ) {
        // Dismiss
    }
}
