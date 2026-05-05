import SwiftUI
import SwiftData

struct StarterDecksView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var existingDecks: [Deck]
    
    @State private var installingDeckID: String?
    @State private var showingError = false
    @State private var errorMessage = ""
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            ForEach(StarterDeckService.availableDecks) { info in
                let alreadyInstalled = StarterDeckService.isInstalled(info, existingDecks: existingDecks)
                
                HStack(spacing: 14) {
                    Image(systemName: info.icon)
                        .font(.title2)
                        .foregroundStyle(Color(info.color))
                        .frame(width: 44, height: 44)
                        .background(Color(info.color).opacity(0.15))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    
                    VStack(alignment: .leading, spacing: 3) {
                        Text(info.name)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        
                        Text("\(info.cardCount) cards")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                    
                    if alreadyInstalled {
                        Label("Added", systemImage: "checkmark.circle.fill")
                            .font(.caption)
                            .foregroundStyle(.green)
                    } else if installingDeckID == info.id {
                        ProgressView()
                            .controlSize(.small)
                    } else {
                        Button {
                            installDeck(info)
                        } label: {
                            Text("Add")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 6)
                                .background(Color.accentColor)
                                .foregroundStyle(.white)
                                .clipShape(Capsule())
                        }
                    }
                }
                .padding(12)
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }
        }
        .alert("Import Error", isPresented: $showingError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
    }
    
    private func installDeck(_ info: StarterDeckInfo) {
        installingDeckID = info.id
        
        // Use a small delay so the progress indicator shows
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            do {
                try StarterDeckService.installDeck(info, modelContext: modelContext)
            } catch {
                errorMessage = error.localizedDescription
                showingError = true
            }
            installingDeckID = nil
        }
    }
}

#Preview {
    StarterDecksView()
        .padding()
        .modelContainer(for: [Deck.self, Card.self, StudySession.self, Review.self], inMemory: true)
}
