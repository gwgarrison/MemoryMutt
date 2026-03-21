import SwiftUI

struct PrivacyPolicyView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Effective Date: March 21, 2026")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text("ModusMemori does not collect, transmit, or share any personal data. All data you create in the App lives exclusively on your device.")
                    .padding()
                    .background(Color.secondary.opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                Group {
                    Text("Information We Collect")
                        .font(.headline)
                    Text("We collect no information. The App does not collect, transmit, store on external servers, or share any personal information or usage data.")
                }

                Group {
                    Text("Data Stored on Your Device")
                        .font(.headline)
                    Text("The App stores the following data locally on your device only, using Apple's SwiftData framework:\n\n• Flashcard decks and cards you create\n• Study session history and review records\n• Spaced-repetition state for each card\n\nStudy settings and display preferences are stored via Apple's UserDefaults. This data never leaves your device and is not accessible to the App's developers.")
                }

                Group {
                    Text("CSV Import")
                        .font(.headline)
                    Text("When you import a CSV file, the App reads the file you select using Apple's standard document picker. The file is read once to create flashcards and is not retained, copied to external storage, or transmitted anywhere.")
                }

                Group {
                    Text("Third-Party Services")
                        .font(.headline)
                    Text("The App uses no third-party SDKs, analytics tools, advertising networks, or external APIs. There are no in-app purchases, accounts, or sign-in flows.")
                }

                Group {
                    Text("Children's Privacy")
                        .font(.headline)
                    Text("The App does not collect any data from any users, including children under 13. It is compliant with COPPA by virtue of collecting no data at all.")
                }

                Group {
                    Text("Data Deletion")
                        .font(.headline)
                    Text("To delete all App data, delete the App from your device. This permanently removes all flashcard decks, study history, and preferences.")
                }

                Group {
                    Text("Changes to This Policy")
                        .font(.headline)
                    Text("If this policy changes in a future version, the updated policy will be included with that app update. The \"Last Updated\" date above will reflect the revision date.")
                }

                Group {
                    Text("Contact")
                        .font(.headline)
                    Text("ManicMutt LLC")
                    Link("darwingarrison2012@gmail.com", destination: URL(string: "mailto:darwingarrison2012@gmail.com")!)
                }
            }
            .padding()
        }
        .navigationTitle("Privacy Policy")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        PrivacyPolicyView()
    }
}
