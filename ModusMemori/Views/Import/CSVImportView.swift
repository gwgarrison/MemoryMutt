import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct CSVImportView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var deckName: String = ""
    @State private var hasHeader: Bool = true
    @State private var isImporting: Bool = false
    @State private var showingFilePicker: Bool = false
    @State private var importResult: CSVImportService.ImportResult?
    @State private var showingResult: Bool = false
    @State private var errorMessage: String?
    @State private var showingError: Bool = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text("Import flashcards from a CSV file. The file should have columns for the front and back of each card.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                Section("CSV Format") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Expected format:")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        
                        Text("front,back,hint (optional)")
                            .font(.system(.caption, design: .monospaced))
                            .padding(8)
                            .background(Color(.systemGray6))
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                    }
                    
                    Toggle("First row is header", isOn: $hasHeader)
                }
                
                Section("Deck Settings") {
                    TextField("Deck Name (optional)", text: $deckName)
                    
                    Text("Leave empty to use the filename")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Section {
                    Button {
                        showingFilePicker = true
                    } label: {
                        HStack {
                            Image(systemName: "doc.badge.plus")
                            Text("Select CSV File")
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .disabled(isImporting)
                }
                
                Section("Example CSV") {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("front,back,hint")
                            .font(.system(.caption, design: .monospaced))
                        Text("\"What is 2+2?\",\"4\",\"Basic math\"")
                            .font(.system(.caption, design: .monospaced))
                        Text("\"Capital of France?\",\"Paris\",\"\"")
                            .font(.system(.caption, design: .monospaced))
                        Text("\"Hello in Spanish\",\"Hola\",")
                            .font(.system(.caption, design: .monospaced))
                    }
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("Import CSV")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .fileImporter(
                isPresented: $showingFilePicker,
                allowedContentTypes: [.commaSeparatedText, .plainText],
                allowsMultipleSelection: false
            ) { result in
                handleFileSelection(result)
            }
            .alert("Import Successful", isPresented: $showingResult) {
                Button("Done") {
                    dismiss()
                }
            } message: {
                if let result = importResult {
                    Text("Created deck '\(result.deck?.name ?? "")' with \(result.cardsImported) cards.\(result.cardsSkipped > 0 ? " \(result.cardsSkipped) rows were skipped." : "")")
                }
            }
            .alert("Import Failed", isPresented: $showingError) {
                Button("OK", role: .cancel) { }
            } message: {
                if let error = errorMessage {
                    Text(error)
                }
            }
            .overlay {
                if isImporting {
                    ProgressView("Importing...")
                        .padding()
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
        }
    }
    
    private func handleFileSelection(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            importFile(url)
            
        case .failure(let error):
            errorMessage = error.localizedDescription
            showingError = true
        }
    }
    
    private func importFile(_ url: URL) {
        isImporting = true
        
        Task {
            do {
                let service = CSVImportService(modelContext: modelContext)
                let result = try service.importCSV(
                    from: url,
                    deckName: deckName.isEmpty ? nil : deckName,
                    hasHeader: hasHeader
                )
                
                await MainActor.run {
                    isImporting = false
                    importResult = result
                    showingResult = true
                }
            } catch {
                await MainActor.run {
                    isImporting = false
                    errorMessage = error.localizedDescription
                    showingError = true
                }
            }
        }
    }
}

#Preview {
    CSVImportView()
        .modelContainer(for: [Deck.self, Card.self, StudySession.self, Review.self], inMemory: true)
}
