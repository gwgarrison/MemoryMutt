import SwiftUI

struct MultipleChoiceView: View {
    let questionText: String
    let choices: [String]
    let correctAnswer: String
    let onAnswer: (Bool) -> Void
    
    @State private var selectedAnswer: String?
    @State private var hasAnswered = false
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            // Question card
            questionCard
                .padding(.horizontal, 20)
            
            Spacer()
            
            // Answer choices
            choiceButtons
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            
            // Next button (shown after answering)
            if hasAnswered {
                Button {
                    let wasCorrect = selectedAnswer == correctAnswer
                    // Reset state before calling onAnswer to avoid stale UI
                    selectedAnswer = nil
                    hasAnswered = false
                    onAnswer(wasCorrect)
                } label: {
                    Text("Next")
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
    }
    
    private var questionCard: some View {
        VStack {
            Text("Question")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.top, 16)
            
            Spacer()
            
            Text(questionText)
                .font(questionText.isEmoji ? .system(size: 80) : .title2)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
            
            Spacer()
            
            Text("Choose the correct answer")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.bottom, 16)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 250)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
    }
    
    private var choiceButtons: some View {
        VStack(spacing: 12) {
            ForEach(choices, id: \.self) { choice in
                Button {
                    guard !hasAnswered else { return }
                    selectedAnswer = choice
                    hasAnswered = true
                } label: {
                    HStack {
                        Text(choice)
                            .font(.body)
                            .multilineTextAlignment(.leading)
                        
                        Spacer()
                        
                        if hasAnswered {
                            if choice == correctAnswer {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.green)
                            } else if choice == selectedAnswer {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(.red)
                            }
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(choiceBackground(for: choice))
                    .foregroundStyle(choiceForeground(for: choice))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(choiceBorder(for: choice), lineWidth: 2)
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }
    
    private func choiceBackground(for choice: String) -> Color {
        guard hasAnswered else {
            return Color(.systemGray6)
        }
        if choice == correctAnswer {
            return Color.green.opacity(0.15)
        }
        if choice == selectedAnswer {
            return Color.red.opacity(0.15)
        }
        return Color(.systemGray6)
    }
    
    private func choiceForeground(for choice: String) -> Color {
        guard hasAnswered else {
            return .primary
        }
        if choice == correctAnswer {
            return .green
        }
        if choice == selectedAnswer {
            return .red
        }
        return .secondary
    }
    
    private func choiceBorder(for choice: String) -> Color {
        guard hasAnswered else {
            return .clear
        }
        if choice == correctAnswer {
            return .green
        }
        if choice == selectedAnswer && choice != correctAnswer {
            return .red
        }
        return .clear
    }
}

#Preview {
    MultipleChoiceView(
        questionText: "What is the capital of France?",
        choices: ["Berlin", "Paris", "London", "Madrid"],
        correctAnswer: "Paris"
    ) { wasCorrect in
        print("Answered correctly: \(wasCorrect)")
    }
}
