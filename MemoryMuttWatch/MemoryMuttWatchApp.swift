import SwiftUI
import SwiftData

@main
struct MemoryMuttWatchApp: App {
    let sharedModelContainer: ModelContainer = {
        let schema = Schema([Deck.self, Card.self, StudySession.self, Review.self])
        let groupID = "group.com.manicmutt.MemoryMutt"
        if let containerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: groupID) {
            let storeURL = containerURL.appendingPathComponent("MemoryMutt.store")
            let config = ModelConfiguration(schema: schema, url: storeURL)
            if let container = try? ModelContainer(for: schema, configurations: [config]) {
                return container
            }
        }
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        return try! ModelContainer(for: schema, configurations: [config])
    }()

    var body: some Scene {
        WindowGroup {
            WatchDeckListView()
        }
        .modelContainer(sharedModelContainer)
    }
}
