import SwiftUI
import SwiftData
import UIKit

/// A focused session over the cards that keep beating the learner. Each card has to be
/// recognised (multiple choice) and then recalled cold (flashcard) before it counts as
/// rescued; a miss at either step sends it back to the start of the ladder.
struct RescueRoundView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let cards: [Card]
    var deck: Deck? = nil

    @StateObject private var sessionManager = StudySessionManager()
    @AppStorage("enableHaptics") private var enableHaptics: Bool = true

    @State private var hasStarted = false
    @State private var isRevealed = false
    @State private var showingExitAlert = false

    var body: some View {
        NavigationStack {
            Group {
                if cards.isEmpty {
                    noTroubleView
                } else if !hasStarted {
                    introView
                } else if sessionManager.isSessionActive, let card = sessionManager.currentCard {
                    roundView(card: card)
                } else {
                    completionView
                }
            }
            .navigationTitle("Rescue Round")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        if sessionManager.isSessionActive && sessionManager.rescuedCount > 0 {
                            showingExitAlert = true
                        } else {
                            if sessionManager.isSessionActive { sessionManager.endSession() }
                            dismiss()
                        }
                    } label: {
                        Image(systemName: "xmark")
                    }
                }
            }
            .alert("End Rescue Round?", isPresented: $showingExitAlert) {
                Button("Keep Going", role: .cancel) { }
                Button("End Round") {
                    sessionManager.endSession()
                    dismiss()
                }
            } message: {
                Text("You've rescued \(sessionManager.rescuedCount) of \(sessionManager.rescueTotal) cards. Cards you haven't finished stay flagged as trouble.")
            }
            .sheet(item: $sessionManager.cardNeedingHint) { card in
                HintPromptView(card: card)
            }
        }
    }

    // MARK: - Intro

    private var introView: some View {
        VStack(spacing: 28) {
            Spacer()

            Image(systemName: "cross.case.fill")
                .font(.system(size: 56))
                .foregroundStyle(.white)
                .frame(width: 110, height: 110)
                .background(Color.red.gradient)
                .clipShape(RoundedRectangle(cornerRadius: 24))

            VStack(spacing: 8) {
                Text("\(cards.count) Trouble \(cards.count == 1 ? "Card" : "Cards")")
                    .font(.title)
                    .fontWeight(.bold)

                Text(deck.map { "in \($0.name)" } ?? "across all your decks")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Text("These are cards you'd learned and then lost again. Let's get them back.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                    .padding(.top, 4)
            }

            VStack(spacing: 12) {
                rescueStepRow(
                    number: 1,
                    icon: "list.bullet.circle",
                    title: "Recognize it",
                    detail: "Pick the answer out of four choices"
                )
                rescueStepRow(
                    number: 2,
                    icon: "rectangle.portrait.on.rectangle.portrait",
                    title: "Recall it",
                    detail: "Then produce the answer with no help"
                )
            }
            .padding(.horizontal, 20)

            Text("Miss either step and the card goes back to step one.")
                .font(.caption)
                .foregroundStyle(.secondary)

            Spacer()

            Button {
                sessionManager.setModelContext(modelContext)
                sessionManager.startRescueSession(
                    cards: cards,
                    deck: deck,
                    distractorPool: distractorPool()
                )
                hasStarted = true
            } label: {
                Label("Start Rescue", systemImage: "cross.case.fill")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.red)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 30)
        }
    }

    /// Multiple-choice distractors come from the decks the trouble cards actually live in,
    /// resolved when the round starts so Home never has to hold every card in memory.
    private func distractorPool() -> [Card] {
        if let deck { return deck.cards }
        var seenDecks = Set<UUID>()
        var pool: [Card] = []
        for owner in cards.compactMap({ $0.deck }) where seenDecks.insert(owner.id).inserted {
            pool.append(contentsOf: owner.cards)
        }
        return pool
    }

    private func rescueStepRow(number: Int, icon: String, title: String, detail: String) -> some View {
        HStack(spacing: 14) {
            Text("\(number)")
                .font(.headline)
                .foregroundStyle(.white)
                .frame(width: 30, height: 30)
                .background(Color.red)
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Round

    @ViewBuilder
    private func roundView(card: Card) -> some View {
        VStack(spacing: 0) {
            phaseHeader

            if sessionManager.rescuePhase == .recognition {
                MultipleChoiceView(
                    questionText: card.front,
                    choices: sessionManager.currentChoices,
                    correctAnswer: sessionManager.correctAnswer ?? card.back
                ) { wasCorrect in
                    submit(correct: wasCorrect)
                }
                .id("mc-\(card.id)")
            } else {
                recallView(card: card)
                    .id("recall-\(card.id)")
            }
        }
    }

    private var phaseHeader: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: sessionManager.rescuePhase == .recognition
                      ? "list.bullet.circle"
                      : "rectangle.portrait.on.rectangle.portrait")
                Text(sessionManager.rescuePhase == .recognition
                     ? "Step 1 of 2 · Recognize"
                     : "Step 2 of 2 · Recall")
                    .fontWeight(.medium)
                Spacer()
                Text("\(sessionManager.rescuedCount) rescued")
                    .foregroundStyle(.secondary)
            }
            .font(.caption)

            ProgressView(
                value: Double(sessionManager.rescuedCount),
                total: Double(max(sessionManager.rescueTotal, 1))
            )
            .tint(.red)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
    }

    private func recallView(card: Card) -> some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 16) {
                Text(isRevealed ? "Answer" : "Question")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text(isRevealed ? card.back : card.front)
                    .font((isRevealed ? card.back : card.front).isEmoji ? .system(size: 80) : .title2)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)

                if !isRevealed, let hint = card.hint, !hint.isEmpty {
                    Label(hint, systemImage: "lightbulb")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 300)
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.red.opacity(0.35), lineWidth: 2)
            )
            .padding(.horizontal, 20)

            Spacer()

            if isRevealed {
                VStack(spacing: 12) {
                    Text("Did you get it without help?")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    HStack(spacing: 40) {
                        Button {
                            submit(correct: false)
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
                            submit(correct: true)
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
                }
                .padding(.bottom, 30)
            } else {
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) { isRevealed = true }
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
                .padding(.bottom, 30)
            }
        }
    }

    private func submit(correct: Bool) {
        if enableHaptics {
            UIImpactFeedbackGenerator(style: correct ? .light : .rigid).impactOccurred()
        }
        isRevealed = false
        sessionManager.recordRescueAnswer(correct: correct)
    }

    // MARK: - Completion

    private var completionView: some View {
        let rescued = sessionManager.rescuedCount
        let total = sessionManager.rescueTotal
        let allRescued = total > 0 && rescued == total

        return ZStack {
            VStack(spacing: 28) {
                Spacer()

                Image(systemName: allRescued ? "checkmark.seal.fill" : "cross.case.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(allRescued ? .green : .orange)

                VStack(spacing: 6) {
                    Text(allRescued ? "All Rescued!" : "Rescue Round Complete")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)

                    Text("\(rescued) of \(total) cards brought back")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                HStack(spacing: 40) {
                    CompletionStat(
                        value: "\(rescued)",
                        label: "Rescued",
                        icon: "checkmark.circle.fill"
                    )

                    CompletionStat(
                        value: "\(max(0, total - rescued))",
                        label: "Still Trouble",
                        icon: "exclamationmark.triangle.fill"
                    )
                }
                .padding()
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .padding(.horizontal)

                Text(completionMessage(rescued: rescued, total: total))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)

                Spacer()

                Button {
                    dismiss()
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

            if allRescued {
                ConfettiView()
                    .allowsHitTesting(false)
            }
        }
    }

    private func completionMessage(rescued: Int, total: Int) -> String {
        guard total > 0 else { return "Nothing to rescue." }
        if rescued == total {
            return "Every one of them is back in the learning queue with a clean slate. 🐶"
        }
        if rescued == 0 {
            return "These ones are stubborn. Try adding hints and come back tomorrow. 💪"
        }
        return "Good progress — the rest stay flagged and will be waiting for you. 🎯"
    }

    private var noTroubleView: some View {
        ContentUnavailableView {
            Label("No Trouble Cards", systemImage: "checkmark.circle.fill")
        } description: {
            Text("Nothing is giving you repeated trouble right now.")
        } actions: {
            Button("Done") { dismiss() }
                .buttonStyle(.borderedProminent)
        }
    }
}

/// Offered the moment a rescue card is missed — the one point where writing a hint is
/// obviously worth the effort.
struct HintPromptView: View {
    @Environment(\.dismiss) private var dismiss

    let card: Card

    @State private var hintText: String = ""

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(card.front)
                            .font(.headline)
                        Text(card.back)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text("The card")
                }

                Section {
                    TextField("e.g. starts with 'B', on the river", text: $hintText, axis: .vertical)
                        .lineLimit(2...4)
                } header: {
                    Text("Hint")
                } footer: {
                    Text("Hints show on the question side, before you answer. A good one nudges your memory without giving the answer away.")
                }
            }
            .navigationTitle("Add a Hint?")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Not Now") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let trimmed = hintText.trimmingCharacters(in: .whitespacesAndNewlines)
                        card.hint = trimmed.isEmpty ? nil : trimmed
                        card.updatedAt = Date()
                        dismiss()
                    }
                    .disabled(hintText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}

#Preview {
    RescueRoundView(cards: [])
        .modelContainer(for: [Deck.self, Card.self, StudySession.self, Review.self], inMemory: true)
}
