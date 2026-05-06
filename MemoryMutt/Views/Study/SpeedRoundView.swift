import SwiftUI
import UIKit

struct SpeedRoundView: View {
    @ObservedObject var sessionManager: StudySessionManager
    let card: Card
    let enableHaptics: Bool
    let onRate: (ReviewRating) -> Void

    @State private var selectedAnswer: String? = nil

    private var timerProgress: Double {
        Double(sessionManager.timeRemaining) / Double(60)
    }

    private var timerColor: Color {
        if sessionManager.timeRemaining <= 5 { return .red }
        if sessionManager.timeRemaining <= 10 { return .orange }
        return .green
    }

    var body: some View {
        VStack(spacing: 16) {
            timerHeader
                .padding(.top, 8)

            questionCard

            choicesStack

            Spacer()
        }
        .padding(.horizontal, 20)
        .onChange(of: card.id) {
            selectedAnswer = nil
        }
    }

    private var timerHeader: some View {
        ZStack {
            Circle()
                .stroke(Color(.systemGray5), lineWidth: 6)
                .frame(width: 72, height: 72)

            Circle()
                .trim(from: 0, to: timerProgress)
                .stroke(timerColor, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                .frame(width: 72, height: 72)
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 1), value: sessionManager.timeRemaining)

            Text("\(sessionManager.timeRemaining)")
                .font(.title3.monospacedDigit())
                .fontWeight(.bold)
                .foregroundStyle(timerColor)
                .animation(.none, value: sessionManager.timeRemaining)
        }
    }

    private var questionCard: some View {
        VStack(spacing: 8) {
            Text("Question")
                .font(.caption)
                .foregroundStyle(.secondary)

            Text(sessionManager.isReversed ? card.back : card.front)
                .font((sessionManager.isReversed ? card.back : card.front).isEmoji ? .system(size: 56) : .title2)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 12)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
    }

    private var choicesStack: some View {
        VStack(spacing: 10) {
            ForEach(sessionManager.currentChoices, id: \.self) { choice in
                choiceButton(for: choice)
            }
        }
    }

    private func choiceButton(for choice: String) -> some View {
        let correct = sessionManager.correctAnswer
        let isSelected = selectedAnswer == choice
        let isCorrect = choice == correct

        var backgroundColor: Color {
            guard let selected = selectedAnswer else { return Color(.systemGray6) }
            if choice == selected {
                return isCorrect ? Color.green.opacity(0.25) : Color.red.opacity(0.25)
            }
            if isCorrect && selected != nil {
                return Color.green.opacity(0.15)
            }
            return Color(.systemGray6)
        }

        var borderColor: Color {
            guard let selected = selectedAnswer else { return Color.clear }
            if choice == selected { return isCorrect ? .green : .red }
            if isCorrect { return .green }
            return Color.clear
        }

        return Button {
            guard selectedAnswer == nil else { return }
            if enableHaptics { UIImpactFeedbackGenerator(style: .light).impactOccurred() }
            selectedAnswer = choice
            let rating: ReviewRating = isCorrect ? .correct : .incorrect
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                onRate(rating)
            }
        } label: {
            HStack {
                Text(choice)
                    .font(.body)
                    .multilineTextAlignment(.leading)
                    .foregroundStyle(.primary)
                Spacer()
                if isSelected {
                    Image(systemName: isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundStyle(isCorrect ? .green : .red)
                } else if selectedAnswer != nil && isCorrect {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity)
            .background(backgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(borderColor, lineWidth: 2)
            )
        }
        .disabled(selectedAnswer != nil)
    }
}
