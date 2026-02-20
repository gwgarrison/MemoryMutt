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
    @State private var reverseCards = false
    @State private var hasStarted = false
    
    var body: some View {
        NavigationStack {
            Group {
                if !hasStarted {
                    sessionSetupView
                } else if sessionManager.isSessionActive {
                    if let card = sessionManager.currentCard {
                        studyCardView(card: card)
                    } else {
                        completionView
                    }
                } else if sessionManager.cardQueue.isEmpty && sessionManager.currentSession == nil {
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
    
    // MARK: - Session Setup
    
    private var sessionSetupView: some View {
        VStack(spacing: 30) {
            Spacer()
            
            Image(systemName: deck.icon)
                .font(.system(size: 60))
                .foregroundStyle(Color(deck.color))
                .frame(width: 120, height: 120)
                .background(Color(deck.color).opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: 24))
            
            VStack(spacing: 8) {
                Text(deck.name)
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("\(deck.cardsDueCount) due · \(deck.newCardsCount) new")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            // Reverse toggle
            VStack(spacing: 12) {
                Toggle(isOn: $reverseCards) {
                    HStack(spacing: 12) {
                        Image(systemName: "arrow.left.arrow.right")
                            .font(.title3)
                            .foregroundStyle(Color.accentColor)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Reverse Cards")
                                .font(.headline)
                            Text("Show the answer first, guess the question")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .padding(.horizontal, 20)
            
            Spacer()
            
            Button {
                sessionManager.setModelContext(modelContext)
                sessionManager.startSession(deck: deck, reversed: reverseCards)
                hasStarted = true
            } label: {
                Label("Start Studying", systemImage: "play.fill")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 30)
        }
    }
    
    @ViewBuilder
    private func studyCardView(card: Card) -> some View {
        VStack(spacing: 0) {
            Spacer()
            
            // Flashcard
            flashcardView(card: card)
                .padding(.horizontal, 20)
                .id(card.id) // Force view refresh when card changes
            
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
        let frontContent = sessionManager.isReversed ? card.back : card.front
        let backContent = sessionManager.isReversed ? card.front : card.back
        
        return ZStack {
            // Back of card
            cardFace(
                content: backContent,
                isBack: true
            )
            .rotation3DEffect(
                .degrees(isFlipped ? 0 : 180),
                axis: (x: 0, y: 1, z: 0)
            )
            .opacity(isFlipped ? 1 : 0)
            
            // Front of card
            cardFace(
                content: frontContent,
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
        let label = isBack
            ? (sessionManager.isReversed ? "Front" : "Answer")
            : (sessionManager.isReversed ? "Back" : "Question")
        
        return VStack {
            Text(label)
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
            Text("Did you know it?")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            HStack(spacing: 40) {
                // X button - Don't know
                Button {
                    submitRating(.incorrect)
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 80, height: 80)
                        .background(Color.red)
                        .clipShape(Circle())
                        .shadow(color: .red.opacity(0.3), radius: 8, x: 0, y: 4)
                }
                
                // Checkmark button - Know it
                Button {
                    submitRating(.correct)
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
    
    private func submitRating(_ rating: ReviewRating) {
        // Reset state immediately (no animation) before moving to next card
        isFlipped = false
        showingHint = false
        
        // Record the review (this advances to next card)
        sessionManager.recordReview(rating: rating)
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
