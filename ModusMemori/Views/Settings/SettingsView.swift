import SwiftUI

struct SettingsView: View {
    @AppStorage("dailyCardLimit") private var dailyCardLimit: Int = 100
    @AppStorage("newCardsPerDay") private var newCardsPerDay: Int = 20
    @AppStorage("reviewOrder") private var reviewOrder: String = "random"
    @AppStorage("showProgressDuringSession") private var showProgressDuringSession: Bool = true
    @AppStorage("enableHaptics") private var enableHaptics: Bool = true
    @AppStorage("enableSounds") private var enableSounds: Bool = false
    
    var body: some View {
        NavigationStack {
            Form {
                // Study Settings
                Section {
                    Stepper(value: $dailyCardLimit, in: 10...500, step: 10) {
                        HStack {
                            Text("Daily Card Limit")
                            Spacer()
                            Text("\(dailyCardLimit)")
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    Stepper(value: $newCardsPerDay, in: 0...100, step: 5) {
                        HStack {
                            Text("New Cards Per Day")
                            Spacer()
                            Text("\(newCardsPerDay)")
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    Picker("Review Order", selection: $reviewOrder) {
                        Text("Random").tag("random")
                        Text("Oldest First").tag("oldest")
                        Text("Newest First").tag("newest")
                    }
                } header: {
                    Text("Study Settings")
                } footer: {
                    Text("These settings control how cards are presented during study sessions.")
                }
                
                // Display Settings
                Section("Display") {
                    Toggle("Show Progress During Session", isOn: $showProgressDuringSession)
                }
                
                // Feedback Settings
                Section("Feedback") {
                    Toggle("Haptic Feedback", isOn: $enableHaptics)
                    Toggle("Sound Effects", isOn: $enableSounds)
                }
                
                // Data Management
                Section("Data") {
                    NavigationLink {
                        ExportView()
                    } label: {
                        Label("Export Data", systemImage: "square.and.arrow.up")
                    }
                    
                    NavigationLink {
                        ImportView()
                    } label: {
                        Label("Import Data", systemImage: "square.and.arrow.down")
                    }
                }
                
                // About
                Section("About") {
                    LabeledContent("Version", value: "1.0.0")
                    
                    Link(destination: URL(string: "https://example.com/privacy")!) {
                        HStack {
                            Text("Privacy Policy")
                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .font(.caption)
                        }
                    }
                    
                    Link(destination: URL(string: "https://example.com/terms")!) {
                        HStack {
                            Text("Terms of Service")
                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .font(.caption)
                        }
                    }
                }
                
                // Reset
                Section {
                    Button(role: .destructive) {
                        resetToDefaults()
                    } label: {
                        HStack {
                            Spacer()
                            Text("Reset to Defaults")
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle("Settings")
        }
    }
    
    private func resetToDefaults() {
        dailyCardLimit = 100
        newCardsPerDay = 20
        reviewOrder = "random"
        showProgressDuringSession = true
        enableHaptics = true
        enableSounds = false
    }
}

struct ExportView: View {
    var body: some View {
        ContentUnavailableView {
            Label("Export", systemImage: "square.and.arrow.up")
        } description: {
            Text("Export functionality will be available in a future update.")
        }
        .navigationTitle("Export Data")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct ImportView: View {
    @State private var showingCSVImport = false
    
    var body: some View {
        List {
            Section {
                Button {
                    showingCSVImport = true
                } label: {
                    Label("Import from CSV", systemImage: "doc.text")
                }
            } header: {
                Text("Import Options")
            } footer: {
                Text("Import flashcards from a CSV file with front, back, and optional hint columns.")
            }
        }
        .navigationTitle("Import Data")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingCSVImport) {
            CSVImportView()
        }
    }
}

#Preview {
    SettingsView()
}
