import SwiftUI
import SwiftData

struct DeckEditorView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    var deck: Deck?
    
    @State private var name: String = ""
    @State private var deckDescription: String = ""
    @State private var selectedColor: String = "blue"
    @State private var selectedIcon: String = "rectangle.stack.fill"
    @State private var tagsText: String = ""
    
    private var isEditing: Bool { deck != nil }
    
    private let availableColors = [
        "blue", "red", "green", "orange", "purple", "pink", "yellow", "teal", "indigo"
    ]
    
    private let availableIcons = [
        "rectangle.stack.fill",
        "book.fill",
        "brain.head.profile",
        "lightbulb.fill",
        "star.fill",
        "heart.fill",
        "globe",
        "music.note",
        "graduationcap.fill",
        "atom",
        "function",
        "number",
        "textformat.abc",
        "character.book.closed.fill",
        "flag.fill"
    ]
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Deck Info") {
                    TextField("Name", text: $name)
                    
                    TextField("Description (optional)", text: $deckDescription, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                Section("Appearance") {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Color")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 12) {
                            ForEach(availableColors, id: \.self) { color in
                                Circle()
                                    .fill(Color(color))
                                    .frame(width: 44, height: 44)
                                    .overlay {
                                        if selectedColor == color {
                                            Image(systemName: "checkmark")
                                                .foregroundStyle(.white)
                                                .fontWeight(.bold)
                                        }
                                    }
                                    .onTapGesture {
                                        selectedColor = color
                                    }
                            }
                        }
                    }
                    .padding(.vertical, 8)
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Icon")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 12) {
                            ForEach(availableIcons, id: \.self) { icon in
                                Image(systemName: icon)
                                    .font(.title2)
                                    .frame(width: 44, height: 44)
                                    .background(selectedIcon == icon ? Color(selectedColor) : Color(.systemGray5))
                                    .foregroundStyle(selectedIcon == icon ? .white : .primary)
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                                    .onTapGesture {
                                        selectedIcon = icon
                                    }
                            }
                        }
                    }
                    .padding(.vertical, 8)
                }
                
                Section {
                    TextField("Tags (comma separated)", text: $tagsText)
                } header: {
                    Text("Tags")
                } footer: {
                    Text("Add tags to organize your decks (e.g., Spanish, Vocabulary, Chapter 1)")
                }
                
                // Preview
                Section("Preview") {
                    HStack(spacing: 16) {
                        Image(systemName: selectedIcon)
                            .font(.largeTitle)
                            .foregroundStyle(Color(selectedColor))
                            .frame(width: 60, height: 60)
                            .background(Color(selectedColor).opacity(0.15))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        
                        VStack(alignment: .leading) {
                            Text(name.isEmpty ? "Deck Name" : name)
                                .font(.headline)
                            
                            if !deckDescription.isEmpty {
                                Text(deckDescription)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(2)
                            }
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
            .navigationTitle(isEditing ? "Edit Deck" : "New Deck")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button(isEditing ? "Save" : "Create") {
                        saveDeck()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear {
                if let deck = deck {
                    name = deck.name
                    deckDescription = deck.deckDescription
                    selectedColor = deck.color
                    selectedIcon = deck.icon
                    tagsText = deck.tags.joined(separator: ", ")
                }
            }
        }
    }
    
    private func saveDeck() {
        let tags = tagsText
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        
        if let deck = deck {
            // Update existing deck
            deck.name = name.trimmingCharacters(in: .whitespaces)
            deck.deckDescription = deckDescription
            deck.color = selectedColor
            deck.icon = selectedIcon
            deck.tags = tags
            deck.updatedAt = Date()
        } else {
            // Create new deck
            let newDeck = Deck(
                name: name.trimmingCharacters(in: .whitespaces),
                deckDescription: deckDescription,
                tags: tags,
                color: selectedColor,
                icon: selectedIcon
            )
            modelContext.insert(newDeck)
        }
        
        dismiss()
    }
}

#Preview {
    DeckEditorView()
        .modelContainer(for: [Deck.self, Card.self, StudySession.self, Review.self], inMemory: true)
}
