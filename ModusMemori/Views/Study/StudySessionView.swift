import SwiftUI
import SwiftData

struct StudySessionView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    let deck: Deck
    
    @StateObject private var sessionManager = StudySessionManager()
    @State private var isFlipped = false
    @State private var showingHint = false
    @State private var cardStartTime = Date()
    @State private var showingExitAlert = false
    
    var body: some View {
        NavigationStack {
            Group {
                if sessionManager.isSessionActive {
                    if let card = sessionManager.currentCard {
                        studyCardView(card: card)
                    } else {
                        completionView
                    }
                } else if sessionManager.cardQueue.isEmpty && sessionManager.currentSession == nil {
                    // Session just started but no cards
                    noCardsView
                } else {
                    completionView
                }
            }
            .navigationTitle(deck.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        if sessionManager.isSessionActive && sessionManager.cardsStudied > 0 {
                            showingExitAlert = true
                        } else {
                            dismiss()
                        }
                    } label: {
                        Image(systemName: "xmark")
                    }
                }
                
                if sessionManager.isSessionActive {
                    ToolbarItem(placement: .principal) {
                        ProgressView(value: sessionManager.progress)
                            .frame(width: 120)
                    }
                    
                    ToolbarItem(placement: .primaryAction) {
                        Text("\(sessionManager.cardsRemaining) left")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .onAppear {
                sessionManager.setModelContext(modelContext)
                sessionManager.startSession(deck: deck)
            }
            .alert("End Session?", isPresented: $showingExitAlert) {
                Button("Continue Studying", role: .cancel) { }
                Button("End Session") {
                    sessionManager.endSession()
                    dismiss()
                }
            } message: {
                Text("You've studied \(sessionManager.cardsStudied) cards. Are you sure you want to end this session?")
            }
        }
    }
    
    @ViewBuilder
    private func studyCardView(card: Card) -> some View {
        VStack(spacing: 0) {
            Spacer()
            
            // Flashcard
            flashcardView(card: card)
                .padding(.horizontal, 20)
            
            Spacer()
            
            // Hint button or rating buttons
            if isFlipped {
                ratingButtons
            } else {
                actionButtons(card: card)
            }
        }
        .padding(.bottom, 30)
    }
    
    private func flashcardView(card: Card) -> some View {
        ZStack {
            // Back of card
            cardFace(
                content: card.back,
                isBack: true
            )
            .rotation3DEffect(
                .degrees(isFlipped ? 0 : 180),
                axis: (x: 0, y: 1, z: 0)
            )
            .opacity(isFlipped ? 1 : 0)
            
            // Front of card
            cardFace(
                content: card.front,
                isBack: false
            )
            .rotation3DEffect(
                .degrees(isFlipped ? 180 : 0),
                axis: (x: 0, y: 1, z: 0)
            )
            .opacity(isFlipped ? 0 : 1)
        }
        .frame(height: 350)
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.3)) {
                isFlipped.toggle()
                showingHint = false
            }
        }
    }
    
    private func cardFace(content: String, isBack: Bool) -> some View {
        VStack {
            Text(isBack ? "Answer" : "Question")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.top, 16)
            
            Spacer()
            
            Text(content)
                .font(.title2)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
            
            Spacer()
            
            if !isBack && !isFlipped {
                Text("Tap to reveal")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.bottom, 16)
            } else {
                Spacer()
                    .frame(height: 30)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
    }
    
    private func actionButtons(card: Card) -> some View {
        VStack(spacing: 16) {
            if let hint = card.hint, !hint.isEmpty {
                Button {
                    showingHint.toggle()
                } label: {
                    Label(showingHint ? hint : "Show Hint", systemImage: "lightbulb")
                        .font(.subheadline)
                }
                .buttonStyle(.bordered)
            }
            
            Button {
                withAnimation(.easeInOut(duration: 0.3)) {
                    isFlipped = true
                }
            } label: {
                Text("Show Answer")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding(.horizontal, 20)
        }
    }
    
    private var ratingButtons: some View {
        VStack(spacing: 12) {
            Text("How well did you know this?")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            HStack(spacing: 12) {
                RatingButton(rating: .again, color: .red) {
                    submitRating(.again)
                }
                
                RatingButton(rating: .hard, color: .orange) {
                    submitRating(.hard)
                }
                
                RatingButton(rating: .good, color: .green) {
                    submitRating(.good)
                }
                
                RatingButton(rating: .easy, color: .blue) {
                    submitRating(.easy)
                }
            }
            .padding(.horizontal, 20)
        }
    }
    
    private func submitRating(_ rating: ReviewRating) {
        sessionManager.recordReview(rating: rating)
        
        // Reset for next card
        withAnimation {
            isFlipped = false
            showingHint = false
        }
    }
    
    private var completionView: some View {
        StudyCompletionView(session: sessionManager.currentSession) {
            dismiss()
        }
    }
    
    private var noCardsView: some View {
        ContentUnavailableView {
            Label("No Cards to Study", systemImage: "checkmark.circle.fill")
        } description: {
            Text("This deck has no cards due for review. Add more cards or check back later.")
        } actions: {
            Button("Done") {
                dismiss()
            }
            .buttonStyle(.borderedProminent)
        }
    }
}

struct RatingButton: View {
    let rating: ReviewRating
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text(rating.displayName)
                    .font(.headline)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(color)
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
}

#Preview {
    StudySessionView(deck: Deck(name: "Sample Deck"))
        .modelContainer(for: [Deck.self, Card.self, StudySession.self, Review.self], inMemory: true)
}
