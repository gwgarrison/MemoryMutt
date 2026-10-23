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
        let schema = Schema([
            Deck.self,
            Card.self,
            StudySession.self,
            Review.self,
        ])
        #if DEBUG
        // App Store screenshot runs get a throwaway in-memory store seeded with demo
        // content, so captures are reproducible and never touch the real database.
        if ScreenshotDemoData.isActive {
            let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
            do {
                let container = try ModelContainer(for: schema, configurations: [configuration])
                ScreenshotDemoData.seed(into: container.mainContext)
                return container
            } catch {
                fatalError("Could not create screenshot ModelContainer: \(error)")
            }
        }
        #endif

        // Pin the store to the app sandbox, where every release through 1.20 kept it.
        // With an App Group entitlement present, SwiftData's default would silently move
        // to the group container and existing users would open to an empty library.
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false, groupContainer: .none)

        do {
            let container = try ModelContainer(for: schema, configurations: [modelConfiguration])
            WatchConnectivityService.shared.configure(with: container.mainContext)
            TroubleCardService.backfillLapseCountsIfNeeded(in: container.mainContext)
            return container
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
