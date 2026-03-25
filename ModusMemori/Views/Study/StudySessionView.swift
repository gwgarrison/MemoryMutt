import SwiftUI
import SwiftData

struct StudySessionView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    let deck: Deck
    
    @StateObject private var sessionManager = StudySessionManager()
    @AppStorage("cardsPerSession") private var cardsPerSession: Int = 20
    @State private var sessionCardCount: Int = 20
    @State private var isFlipped = false
    @State private var showingHint = false
    @State private var cardStartTime = Date()
    @State private var showingExitAlert = false
    @State private var reverseCards = false
    @State private var studyMode: StudyMode = .flashcard
    @State private var matchCardCount: Int = 5
    @State private var hasStarted = false
    
    var body: some View {
        NavigationStack {
            Group {
                if !hasStarted {
                    sessionSetupView
                } else if sessionManager.cardQueue.isEmpty {
                    noCardsView
                } else if sessionManager.isSessionActive {
                    if sessionManager.studyMode == .matchGame {
                        matchGameView
                    } else if let card = sessionManager.currentCard {
                        if sessionManager.studyMode == .multipleChoice {
                            multipleChoiceCardView(card: card)
                        } else if sessionManager.studyMode == .hangman {
                            hangmanCardView(card: card)
                        } else {
                            studyCardView(card: card)
                        }
                    } else {
                        completionView
                    }
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
                
                if sessionManager.isSessionActive && sessionManager.studyMode != .matchGame {
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
            
            // Study mode and options
            VStack(spacing: 12) {
                // Study mode picker
                HStack(spacing: 12) {
                    Image(systemName: studyMode.icon)
                        .font(.title3)
                        .foregroundStyle(Color.accentColor)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Study Mode")
                            .font(.headline)
                        Text(studyModeDescription)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                    
                    Picker("Study Mode", selection: $studyMode) {
                        ForEach(StudyMode.allCases, id: \.self) { mode in
                            Text(mode.displayName).tag(mode)
                        }
                    }
                    .pickerStyle(.menu)
                }
                .padding()
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 16))
                
                // Reverse toggle (only for flashcard mode)
                if studyMode == .flashcard {
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
                
                if studyMode == .matchGame {
                    // Match pairs stepper (max 7)
                    Stepper(value: $matchCardCount, in: 2...7) {
                        HStack(spacing: 12) {
                            Image(systemName: "square.grid.2x2")
                                .font(.title3)
                                .foregroundStyle(Color.accentColor)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Pairs to Match")
                                    .font(.headline)
                                Text("\(matchCardCount) pairs (\(matchCardCount * 2) tiles)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                } else {
                    // Cards per session stepper
                    Stepper(value: $sessionCardCount, in: 5...200, step: 5) {
                        HStack(spacing: 12) {
                            Image(systemName: "number")
                                .font(.title3)
                                .foregroundStyle(Color.accentColor)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Cards Per Session")
                                    .font(.headline)
                                Text("\(sessionCardCount) cards")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }
            }
            .padding(.horizontal, 20)
            
            Spacer()
            
            Button {
                sessionManager.setModelContext(modelContext)
                let limit = studyMode == .matchGame ? min(matchCardCount, deck.cards.count) : sessionCardCount
                sessionManager.startSession(deck: deck, cardLimit: limit, reversed: reverseCards, mode: studyMode)
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
        .onAppear {
            sessionCardCount = cardsPerSession
        }}
    
    private var studyModeDescription: String {
        switch studyMode {
        case .flashcard: return "Flip cards to reveal answers"
        case .multipleChoice: return "Pick from 4 answer choices"
        case .matchGame: return "Match questions to answers"
        case .hangman: return "Guess the answer letter by letter"
        }
    }
    
    private var matchGameView: some View {
        MatchGameView(cards: sessionManager.cardQueue) { correctMatches, totalAttempts in
            // Record results into the session
            if let session = sessionManager.currentSession {
                session.cardsStudied = correctMatches
                session.correctCount = correctMatches
            }
            sessionManager.endSession()
        }
    }
    
    @ViewBuilder
    private func hangmanCardView(card: Card) -> some View {
        let rawQuestion = sessionManager.isReversed ? card.back : card.front
        let rawAnswer = sessionManager.isReversed ? card.front : card.back

        // If the answer is a number, use the name (question side) as the word to guess
        // and the number as the clue
        let isNumeric = rawAnswer.trimmingCharacters(in: .whitespacesAndNewlines)
            .allSatisfy { $0.isNumber || $0 == "." || $0 == "," || $0 == " " }
        let questionText = isNumeric ? rawAnswer : rawQuestion
        let answer = isNumeric ? rawQuestion : rawAnswer

        HangmanView(questionText: questionText, answer: answer) { wasCorrect in
            sessionManager.recordReview(rating: wasCorrect ? .correct : .incorrect)
        }
        .id(card.id)
    }

    @ViewBuilder
    private func multipleChoiceCardView(card: Card) -> some View {
        let questionText = sessionManager.isReversed ? card.back : card.front
        
        MultipleChoiceView(
            questionText: questionText,
            choices: sessionManager.currentChoices,
            correctAnswer: sessionManager.correctAnswer ?? ""
        ) { wasCorrect in
            sessionManager.recordReview(rating: wasCorrect ? .correct : .incorrect)
        }
        .id(card.id)
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
                otherSideContent: frontContent,
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
                otherSideContent: backContent,
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
    
    private func wikipediaURL(for text: String, fallback: String) -> URL? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        // If the answer is a number, use the question side instead
        let target = trimmed.allSatisfy({ $0.isNumber || $0 == "." || $0 == "," || $0 == " " })
            ? fallback.trimmingCharacters(in: .whitespacesAndNewlines)
            : trimmed
        let query = target.replacingOccurrences(of: " ", with: "_")
        guard let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed),
              !encoded.isEmpty else { return nil }
        return URL(string: "https://en.wikipedia.org/wiki/\(encoded)")
    }
    
    private func cardFace(content: String, otherSideContent: String, isBack: Bool) -> some View {
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
                .font(content.isEmoji ? .system(size: 80) : .title2)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
            
            Spacer()
            
            if isBack, let url = wikipediaURL(for: content, fallback: otherSideContent) {
                Link(destination: url) {
                    HStack(spacing: 4) {
                        Image(systemName: "book.closed")
                        Text("Wikipedia")
                    }
                    .font(.caption)
                    .foregroundStyle(.blue)
                }
                .padding(.bottom, 16)
            } else if !isBack && !isFlipped {
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
