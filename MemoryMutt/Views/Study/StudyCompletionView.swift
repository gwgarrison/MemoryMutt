import SwiftUI

struct StudyCompletionView: View {
    let session: StudySession?
    let onDismiss: () -> Void
    var isSpeedRound: Bool = false
    var bestScore: Int? = nil

    var body: some View {
        VStack(spacing: 30) {
            Spacer()

            Image(systemName: isSpeedRound ? "bolt.circle.fill" : "checkmark.circle.fill")
                .font(.system(size: 80))
                .foregroundStyle(isSpeedRound ? .yellow : .green)

            VStack(spacing: 6) {
                Text(isSpeedRound ? "Speed Round Complete!" : "Session Complete!")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                if isSpeedRound, let session, let best = bestScore, session.correctCount >= best {
                    Text("New Best!")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(Color.yellow)
                        .clipShape(Capsule())
                }
            }

            if let session = session {
                VStack(spacing: 20) {
                    if isSpeedRound {
                        HStack(spacing: 40) {
                            CompletionStat(
                                value: "\(session.correctCount)",
                                label: "Score",
                                icon: "bolt.fill"
                            )

                            CompletionStat(
                                value: bestScore.map { "\($0)" } ?? "—",
                                label: "Best",
                                icon: "trophy.fill"
                            )
                        }

                        HStack(spacing: 40) {
                            CompletionStat(
                                value: session.durationFormatted,
                                label: "Time",
                                icon: "clock.fill"
                            )

                            CompletionStat(
                                value: "\(session.cardsStudied)",
                                label: "Attempted",
                                icon: "rectangle.stack.fill"
                            )
                        }
                    } else {
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
                }
                .padding()
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .padding(.horizontal)
            }

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
        guard let session else { return "Keep up the great work!" }

        if isSpeedRound {
            if session.correctCount >= 20 { return "Lightning fast! You're on fire! ⚡️" }
            if session.correctCount >= 12 { return "Great speed! Keep pushing! 🚀" }
            if session.correctCount >= 6 { return "Good effort! Speed comes with practice! 💪" }
            return "Keep going — every round builds faster recall! 🎯"
        }

        if session.accuracy >= 90 { return "Excellent! You're mastering this material! 🌟" }
        if session.accuracy >= 70 { return "Great job! Keep practicing to improve even more! 💪" }
        if session.accuracy >= 50 { return "Good effort! Regular practice makes perfect! 📚" }
        return "Don't give up! Each review helps you learn! 🎯"
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
