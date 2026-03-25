import SwiftUI
import UIKit

struct HangmanView: View {
    let questionText: String
    let answer: String
    let onResult: (Bool) -> Void

    @AppStorage("enableHaptics") private var enableHaptics: Bool = true
    @State private var guessedLetters: Set<Character> = []
    @State private var gameOver = false

    private let maxWrong = 6
    private let keyboardRows: [[Character]] = [
        Array("QWERTYUIOP"),
        Array("ASDFGHJKL"),
        Array("ZXCVBNM")
    ]

    private var normalizedAnswer: String { answer.uppercased() }

    private var wrongGuesses: Int {
        guessedLetters.filter { !normalizedAnswer.contains($0) }.count
    }

    private var guessableLetters: Set<Character> {
        Set(normalizedAnswer.filter { $0.isLetter })
    }

    private var isWon: Bool {
        guessableLetters.isSubset(of: guessedLetters)
    }

    private var isLost: Bool { wrongGuesses >= maxWrong }

    var body: some View {
        VStack(spacing: 0) {
            // Clue
            Text(questionText)
                .font(.title3.weight(.semibold))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)

            // Hangman figure
            HangmanFigure(wrongGuesses: wrongGuesses)
                .frame(height: 170)
                .padding(.horizontal, 50)

            // Wrong guess counter
            Text("\(wrongGuesses) / \(maxWrong) wrong")
                .font(.caption)
                .foregroundStyle(wrongGuesses >= maxWrong - 1 ? .red : .secondary)
                .padding(.top, 4)

            // Word blanks
            wordDisplay
                .padding(.horizontal, 16)
                .padding(.vertical, 16)

            Spacer()

            // Keyboard or result
            if gameOver {
                resultView
            } else {
                letterKeyboard
            }
        }
        .onChange(of: guessedLetters) { _, _ in
            if isWon || isLost { gameOver = true }
        }
    }

    // MARK: - Word Display

    private var wordDisplay: some View {
        let lines = splitIntoLines(normalizedAnswer)
        return VStack(spacing: 10) {
            ForEach(lines.indices, id: \.self) { i in
                HStack(spacing: 6) {
                    ForEach(lines[i].indices, id: \.self) { j in
                        letterTile(char: lines[i][j])
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func letterTile(char: Character) -> some View {
        if char == " " {
            Color.clear.frame(width: 14, height: 36)
        } else {
            VStack(spacing: 3) {
                Group {
                    if char.isLetter {
                        let revealed = guessedLetters.contains(char) || (gameOver && isLost)
                        Text(revealed ? String(char) : " ")
                            .foregroundStyle(
                                gameOver && isLost && !guessedLetters.contains(char)
                                    ? .red : .primary
                            )
                    } else {
                        // Punctuation / numbers always shown
                        Text(String(char))
                    }
                }
                .font(.system(size: 18, weight: .bold))
                .frame(minWidth: 20)

                if char.isLetter {
                    Rectangle()
                        .frame(height: 2)
                        .foregroundStyle(.primary)
                }
            }
        }
    }

    /// Break the answer into display lines, splitting at spaces when line gets long.
    private func splitIntoLines(_ word: String) -> [[Character]] {
        let chars = Array(word)
        guard chars.count > 14 else { return [chars] }

        var lines: [[Character]] = []
        var current: [Character] = []
        for char in chars {
            current.append(char)
            if char == " " && current.count >= 10 {
                lines.append(current)
                current = []
            }
        }
        if !current.isEmpty { lines.append(current) }
        return lines.isEmpty ? [chars] : lines
    }

    // MARK: - Keyboard

    private var letterKeyboard: some View {
        VStack(spacing: 6) {
            ForEach(keyboardRows.indices, id: \.self) { row in
                HStack(spacing: 5) {
                    ForEach(keyboardRows[row], id: \.self) { letter in
                        Button {
                            guessedLetters.insert(letter)
                            if enableHaptics {
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            }
                        } label: {
                            Text(String(letter))
                                .font(.system(size: 15, weight: .semibold))
                                .frame(width: 30, height: 38)
                                .background(keyBackground(for: letter))
                                .foregroundStyle(keyForeground(for: letter))
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                        }
                        .disabled(guessedLetters.contains(letter))
                    }
                }
            }
        }
        .padding(.horizontal, 8)
        .padding(.bottom, 24)
    }

    private func keyBackground(for letter: Character) -> Color {
        guard guessedLetters.contains(letter) else { return Color(.systemGray5) }
        return normalizedAnswer.contains(letter) ? .green : .red
    }

    private func keyForeground(for letter: Character) -> Color {
        guessedLetters.contains(letter) ? .white : .primary
    }

    // MARK: - Result

    private var resultView: some View {
        VStack(spacing: 14) {
            Image(systemName: isWon ? "checkmark.circle.fill" : "xmark.circle.fill")
                .font(.system(size: 52))
                .foregroundStyle(isWon ? .green : .red)

            Text(isWon ? "Correct!" : "Game Over")
                .font(.title2.bold())

            if isLost {
                Text(answer)
                    .font(.headline)
                    .foregroundStyle(.secondary)
            }

            Button {
                onResult(isWon)
            } label: {
                Text("Next Card")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding(.horizontal, 40)
        }
        .padding(.bottom, 28)
    }
}

// MARK: - Hangman Figure

struct HangmanFigure: View {
    let wrongGuesses: Int

    var body: some View {
        Canvas { ctx, size in
            let w = size.width
            let h = size.height
            let lw: CGFloat = 3

            // Gallows
            var gallows = Path()
            gallows.move(to: CGPoint(x: w * 0.05, y: h * 0.95))
            gallows.addLine(to: CGPoint(x: w * 0.95, y: h * 0.95))   // base
            gallows.move(to: CGPoint(x: w * 0.20, y: h * 0.95))
            gallows.addLine(to: CGPoint(x: w * 0.20, y: h * 0.05))   // pole
            gallows.move(to: CGPoint(x: w * 0.20, y: h * 0.05))
            gallows.addLine(to: CGPoint(x: w * 0.65, y: h * 0.05))   // beam
            gallows.move(to: CGPoint(x: w * 0.65, y: h * 0.05))
            gallows.addLine(to: CGPoint(x: w * 0.65, y: h * 0.16))   // rope
            ctx.stroke(gallows, with: .color(.primary), lineWidth: lw)

            let cx = w * 0.65
            let headTop = h * 0.16
            let headR = h * 0.09

            // 1 — head
            if wrongGuesses >= 1 {
                var p = Path()
                p.addEllipse(in: CGRect(x: cx - headR, y: headTop, width: headR * 2, height: headR * 2))
                ctx.stroke(p, with: .color(.primary), lineWidth: lw)
            }
            // 2 — body
            if wrongGuesses >= 2 {
                var p = Path()
                p.move(to: CGPoint(x: cx, y: headTop + headR * 2))
                p.addLine(to: CGPoint(x: cx, y: h * 0.65))
                ctx.stroke(p, with: .color(.primary), lineWidth: lw)
            }
            // 3 — left arm
            if wrongGuesses >= 3 {
                var p = Path()
                p.move(to: CGPoint(x: cx, y: h * 0.42))
                p.addLine(to: CGPoint(x: cx - w * 0.16, y: h * 0.54))
                ctx.stroke(p, with: .color(.primary), lineWidth: lw)
            }
            // 4 — right arm
            if wrongGuesses >= 4 {
                var p = Path()
                p.move(to: CGPoint(x: cx, y: h * 0.42))
                p.addLine(to: CGPoint(x: cx + w * 0.16, y: h * 0.54))
                ctx.stroke(p, with: .color(.primary), lineWidth: lw)
            }
            // 5 — left leg
            if wrongGuesses >= 5 {
                var p = Path()
                p.move(to: CGPoint(x: cx, y: h * 0.65))
                p.addLine(to: CGPoint(x: cx - w * 0.16, y: h * 0.86))
                ctx.stroke(p, with: .color(.primary), lineWidth: lw)
            }
            // 6 — right leg
            if wrongGuesses >= 6 {
                var p = Path()
                p.move(to: CGPoint(x: cx, y: h * 0.65))
                p.addLine(to: CGPoint(x: cx + w * 0.16, y: h * 0.86))
                ctx.stroke(p, with: .color(.primary), lineWidth: lw)
            }
        }
    }
}
