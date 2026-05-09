//
//  MemoryMuttApp.swift
//  MemoryMutt
//
//  Created by Gary Garrison on 2/17/26.
//

import SwiftUI
import SwiftData

@main
struct MemoryMuttApp: App {
    var sharedModelContainer: ModelContainer = {
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
        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            MainTabView()
        }
        .modelContainer(sharedModelContainer)
    }
}
