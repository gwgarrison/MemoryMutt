import SwiftUI
import UIKit

struct SpeedRoundView: View {
    @ObservedObject var sessionManager: StudySessionManager
    let card: Card
    let enableHaptics: Bool
    let onRate: (ReviewRating) -> Void

    private var timerProgress: Double {
        Double(sessionManager.timeRemaining) / Double(60)
    }

    private var timerColor: Color {
        if sessionManager.timeRemaining <= 5 { return .red }
        if sessionManager.timeRemaining <= 10 { return .orange }
        return .green
    }

    var body: some View {
        VStack(spacing: 0) {
            timerHeader
                .padding(.top, 8)
                .padding(.bottom, 16)

            cardDisplay
                .padding(.horizontal, 20)

            Spacer()

            ratingRow
                .padding(.bottom, 30)
        }
    }

    private var timerHeader: some View {
        ZStack {
            Circle()
                .stroke(Color(.systemGray5), lineWidth: 6)
                .frame(width: 80, height: 80)

            Circle()
                .trim(from: 0, to: timerProgress)
                .stroke(timerColor, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                .frame(width: 80, height: 80)
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 1), value: sessionManager.timeRemaining)

            Text("\(sessionManager.timeRemaining)")
                .font(.title2.monospacedDigit())
                .fontWeight(.bold)
                .foregroundStyle(timerColor)
                .animation(.none, value: sessionManager.timeRemaining)
        }
    }

    private var cardDisplay: some View {
        VStack(spacing: 0) {
            VStack(spacing: 12) {
                Text("Question")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text(card.front)
                    .font(card.front.isEmoji ? .system(size: 64) : .title2)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 12)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 24)

            Divider()

            VStack(spacing: 12) {
                Text("Answer")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text(card.back)
                    .font(card.back.isEmoji ? .system(size: 64) : .title2)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 12)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 24)
        }
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
    }

    private var ratingRow: some View {
        HStack(spacing: 40) {
            Button {
                if enableHaptics { UIImpactFeedbackGenerator(style: .light).impactOccurred() }
                onRate(.incorrect)
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 80, height: 80)
                    .background(Color.red)
                    .clipShape(Circle())
                    .shadow(color: .red.opacity(0.3), radius: 8, x: 0, y: 4)
            }

            Button {
                if enableHaptics { UIImpactFeedbackGenerator(style: .light).impactOccurred() }
                onRate(.correct)
            } label: {
                Image(systemName: "checkmark")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 80, height: 80)
                    .background(Color.green)
                    .clipShape(Circle())
                    .shadow(color: .green.opacity(0.3), radius: 8, x: 0, y: 4)
            }
        }
        .padding(.horizontal, 20)
    }
}
