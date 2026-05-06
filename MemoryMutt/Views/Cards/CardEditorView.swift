import SwiftUI
import SwiftData

struct CardEditorView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    let deck: Deck
    var card: Card?
    
    @State private var front: String = ""
    @State private var back: String = ""
    @State private var hint: String = ""
    @State private var showingDeleteAlert = false
    
    private var isEditing: Bool { card != nil }
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Front (Question)", text: $front, axis: .vertical)
                        .lineLimit(3...8)
                } header: {
                    Text("Front")
                } footer: {
                    Text("Enter the question or prompt that will be shown first")
                }
                
                Section {
                    TextField("Back (Answer)", text: $back, axis: .vertical)
                        .lineLimit(3...8)
                } header: {
                    Text("Back")
                } footer: {
                    Text("Enter the answer that will be revealed when tapped")
                }
                
                Section {
                    TextField("Hint (optional)", text: $hint, axis: .vertical)
                        .lineLimit(2...4)
                } header: {
                    Text("Hint")
                } footer: {
                    Text("Add an optional hint to help remember the answer")
                }
                
                if isEditing, let card = card {
                    Section("Card Info") {
                        LabeledContent("Status", value: card.status.displayName)
                        LabeledContent("Ease Factor", value: String(format: "%.2f", card.easeFactor))
                        LabeledContent("Interval", value: "\(card.interval) days")
                        LabeledContent("Next Review", value: card.nextReviewDate.formatted(date: .abbreviated, time: .omitted))
                        LabeledContent("Reviews", value: "\(card.reviews.count)")
                        if !card.reviews.isEmpty {
                            LabeledContent("Accuracy", value: "\(Int(card.accuracy))% (\(card.correctCount)✓ \(card.incorrectCount)✗)")
                        }
                    }
                    
                    Section {
                        Button(role: .destructive) {
                            showingDeleteAlert = true
                        } label: {
                            HStack {
                                Spacer()
                                Text("Delete Card")
                                Spacer()
                            }
                        }
                    }
                }
            }
            .navigationTitle(isEditing ? "Edit Card" : "New Card")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button(isEditing ? "Save" : "Add") {
                        saveCard()
                    }
                    .disabled(!isValid)
                }
            }
            .onAppear {
                if let card = card {
                    front = card.front
                    back = card.back
                    hint = card.hint ?? ""
                }
            }
            .alert("Delete Card", isPresented: $showingDeleteAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    deleteCard()
                }
            } message: {
                Text("Are you sure you want to delete this card? This action cannot be undone.")
            }
        }
    }
    
    private var isValid: Bool {
        !front.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !back.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    private func saveCard() {
        if let card = card {
            // Update existing card
            card.front = front.trimmingCharacters(in: .whitespacesAndNewlines)
            card.back = back.trimmingCharacters(in: .whitespacesAndNewlines)
            card.hint = hint.isEmpty ? nil : hint.trimmingCharacters(in: .whitespacesAndNewlines)
            card.updatedAt = Date()
        } else {
            // Create new card
            let newCard = Card(
                front: front.trimmingCharacters(in: .whitespacesAndNewlines),
                back: back.trimmingCharacters(in: .whitespacesAndNewlines),
                hint: hint.isEmpty ? nil : hint.trimmingCharacters(in: .whitespacesAndNewlines)
            )
            newCard.deck = deck
            modelContext.insert(newCard)
        }
        
        deck.updatedAt = Date()
        dismiss()
    }
    
    private func deleteCard() {
        if let card = card {
            modelContext.delete(card)
        }
        dismiss()
    }
}

#Preview {
    CardEditorView(deck: Deck(name: "Sample"))
        .modelContainer(for: [Deck.self, Card.self, StudySession.self, Review.self], inMemory: true)
}
