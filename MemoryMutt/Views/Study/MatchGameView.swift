import SwiftUI
import UIKit

struct MatchGameView: View {
    let cards: [Card]
    let onComplete: (Int, Int) -> Void // (correctMatches, totalAttempts)

    @AppStorage("enableHaptics") private var enableHaptics: Bool = true
    @State private var tiles: [MatchTile] = []
    @State private var selectedTile: MatchTile?
    @State private var matchedPairs: Set<UUID> = [] // card IDs that have been matched
    @State private var incorrectPair: Set<String> = [] // tile IDs currently showing as wrong
    @State private var attempts: Int = 0
    @State private var correctMatches: Int = 0
    @State private var isComplete = false
    
    private var isPerfectScore: Bool {
        attempts == cards.count && correctMatches == cards.count
    }
    
    private let columns = [
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10)
    ]
    
    var body: some View {
        ZStack {
            VStack(spacing: 16) {
                // Score header
                HStack {
                    Label("\(correctMatches)/\(cards.count)", systemImage: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                    
                    Spacer()
                    
                    Label("\(attempts) attempts", systemImage: "hand.tap")
                        .foregroundStyle(.secondary)
                }
                .font(.subheadline)
                .padding(.horizontal, 20)
                .padding(.top, 8)
                
                if isComplete {
                    completionContent
                } else {
                    // Tile grid
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 10) {
                            ForEach(tiles) { tile in
                                MatchTileView(
                                    tile: tile,
                                    isSelected: selectedTile?.id == tile.id,
                                    isMatched: matchedPairs.contains(tile.cardID),
                                    isIncorrect: incorrectPair.contains(tile.id)
                                )
                                .onTapGesture {
                                    handleTileTap(tile)
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                }
            }
            
            if isComplete && isPerfectScore {
                ConfettiView()
                    .ignoresSafeArea()
            }
        }
        .onAppear {
            setupTiles()
        }
    }
    
    private var completionContent: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: isPerfectScore ? "trophy.circle.fill" : "star.circle.fill")
                .font(.system(size: 60))
                .foregroundStyle(isPerfectScore ? .yellow : .yellow)
                .symbolEffect(.bounce, value: isPerfectScore)
            
            Text(isPerfectScore ? "Perfect Score!" : "All Matched!")
                .font(.title2)
                .fontWeight(.bold)
            
            VStack(spacing: 8) {
                Text("\(correctMatches) pairs matched")
                Text("\(attempts) total attempts")
                    .foregroundStyle(.secondary)
                
                let accuracy = attempts > 0 ? Int(Double(correctMatches) / Double(attempts) * 100) : 0
                Text("\(accuracy)% accuracy")
                    .font(.headline)
                    .foregroundStyle(accuracy >= 70 ? .green : .orange)
                
                if isPerfectScore {
                    Text("No mistakes — flawless!")
                        .font(.subheadline)
                        .foregroundStyle(.yellow)
                        .fontWeight(.semibold)
                }
            }
            .font(.subheadline)
            
            Spacer()
            
            Button {
                onComplete(correctMatches, attempts)
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
    
    private func setupTiles() {
        var newTiles: [MatchTile] = []
        for card in cards {
            newTiles.append(MatchTile(cardID: card.id, text: card.front, isQuestion: true))
            newTiles.append(MatchTile(cardID: card.id, text: card.back, isQuestion: false))
        }
        tiles = newTiles.shuffled()
    }
    
    private func handleTileTap(_ tile: MatchTile) {
        // Ignore taps on already matched tiles
        guard !matchedPairs.contains(tile.cardID) else { return }
        // Ignore taps on incorrect tiles that are animating
        guard !incorrectPair.contains(tile.id) else { return }
        // Ignore if tapping the same tile
        guard selectedTile?.id != tile.id else {
            selectedTile = nil
            return
        }
        
        if let first = selectedTile {
            // Second tile selected — check for match
            // A valid match requires tiles from the same card but different sides
            attempts += 1
            
            if first.cardID == tile.cardID && first.isQuestion != tile.isQuestion {
                // Correct match
                if enableHaptics { UIImpactFeedbackGenerator(style: .light).impactOccurred() }
                withAnimation(.easeInOut(duration: 0.3)) {
                    matchedPairs.insert(tile.cardID)
                    correctMatches += 1
                }
                selectedTile = nil

                // Check if all pairs matched
                if matchedPairs.count == cards.count {
                    withAnimation(.easeInOut(duration: 0.5).delay(0.5)) {
                        isComplete = true
                    }
                }
            } else {
                // Wrong match — flash red briefly then deselect
                if enableHaptics { UINotificationFeedbackGenerator().notificationOccurred(.error) }
                let wrongIDs: Set<String> = [first.id, tile.id]
                withAnimation(.easeInOut(duration: 0.2)) {
                    incorrectPair = wrongIDs
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        incorrectPair = []
                    }
                }
                selectedTile = nil
            }
        } else {
            // First tile selected
            selectedTile = tile
        }
    }
}

struct MatchTile: Identifiable {
    let id: String
    let cardID: UUID
    let text: String
    let isQuestion: Bool
    
    init(cardID: UUID, text: String, isQuestion: Bool) {
        self.id = "\(cardID.uuidString)-\(isQuestion ? "q" : "a")"
        self.cardID = cardID
        self.text = text
        self.isQuestion = isQuestion
    }
}

struct MatchTileView: View {
    let tile: MatchTile
    let isSelected: Bool
    let isMatched: Bool
    let isIncorrect: Bool
    
    var body: some View {
        Text(tile.text)
            .font(tile.text.isEmoji ? .title : .subheadline)
            .multilineTextAlignment(.center)
            .lineLimit(3)
            .minimumScaleFactor(0.7)
            .padding(12)
            .frame(maxWidth: .infinity)
            .frame(minHeight: 70)
            .background(backgroundColor)
            .foregroundStyle(foregroundColor)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(borderColor, lineWidth: isSelected || isMatched || isIncorrect ? 2.5 : 0)
            )
            .opacity(isMatched ? 0.5 : 1.0)
            .allowsHitTesting(!isMatched)
    }
    
    private var backgroundColor: Color {
        if isMatched {
            return Color.green.opacity(0.15)
        }
        if isIncorrect {
            return Color.red.opacity(0.15)
        }
        if isSelected {
            return Color.accentColor.opacity(0.15)
        }
        return tile.isQuestion ? Color(.systemGray6) : Color(.systemGray5)
    }
    
    private var foregroundColor: Color {
        if isMatched {
            return .green
        }
        if isIncorrect {
            return .red
        }
        if isSelected {
            return .accentColor
        }
        return .primary
    }
    
    private var borderColor: Color {
        if isMatched {
            return .green
        }
        if isIncorrect {
            return .red
        }
        if isSelected {
            return .accentColor
        }
        return .clear
    }
}

#Preview {
    MatchGameView(
        cards: [
            Card(front: "Hello", back: "Hola"),
            Card(front: "Goodbye", back: "Adiós"),
            Card(front: "Thank you", back: "Gracias"),
            Card(front: "Please", back: "Por favor"),
        ]
    ) { correct, attempts in
        print("Matched \(correct) with \(attempts) attempts")
    }
}
