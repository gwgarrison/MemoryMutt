import SwiftUI

@main
struct MemoryMuttWatchApp: App {
    var body: some Scene {
        WindowGroup {
            #if DEBUG
            if WatchScreenshotDemo.isActive {
                WatchScreenshotDemo.rootView()
            } else {
                WatchDeckListView()
            }
            #else
            WatchDeckListView()
            #endif
        }
    }
}
