import SwiftUI

struct WatchFlashcardView: View {
    let card: Card
    let onRate: (ReviewRating) -> Void

    @State private var isFlipped = false

    var body: some View {
        VStack(spacing: 6) {
            cardContent
                .onTapGesture {
                    guard !isFlipped else { return }
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isFlipped = true
                    }
                }

            if isFlipped {
                ratingButtons
            } else {
                Text("Tap to reveal")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var cardContent: some View {
        ZStack {
            cardFace(text: card.front, label: "Question")
                .opacity(isFlipped ? 0 : 1)
            cardFace(text: card.back, label: "Answer")
                .opacity(isFlipped ? 1 : 0)
        }
        .animation(.easeInOut(duration: 0.2), value: isFlipped)
        .frame(maxWidth: .infinity, minHeight: 90)
    }

    private func cardFace(text: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text(text)
                .font(text.isEmoji ? .title : .body)
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.5)
                .lineLimit(4)
        }
        .frame(maxWidth: .infinity, minHeight: 90)
        .padding(8)
        .background(Color.gray.opacity(0.2))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var ratingButtons: some View {
        HStack(spacing: 12) {
            Button {
                onRate(.incorrect)
            } label: {
                Image(systemName: "xmark")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color.red)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .buttonStyle(.plain)

            Button {
                onRate(.correct)
            } label: {
                Image(systemName: "checkmark")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color.green)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .buttonStyle(.plain)
        }
    }
}
