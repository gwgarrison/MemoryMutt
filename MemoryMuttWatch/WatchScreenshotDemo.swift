#if DEBUG
import SwiftUI

/// Demo content for App Store screenshot runs on the watch.
///
/// The watch gets its decks from the phone over WatchConnectivity, which a capture run
/// can't rely on. When launched with `-ScreenshotMode`, the app skips the session and
/// shows fixed decks instead; `-ScreenshotScreen <name>` picks which screen to open on.
/// `fastlane ios watch_screenshots` drives it. The whole file is `#if DEBUG`, so none
/// of it ships in a Release build.
enum WatchScreenshotDemo {

    enum Screen: String {
        case decks, question, answer
    }

    static var isActive: Bool {
        ProcessInfo.processInfo.arguments.contains("-ScreenshotMode")
    }

    /// Read from launch arguments via UserDefaults' argument domain.
    static var screen: Screen {
        UserDefaults.standard.string(forKey: "ScreenshotScreen").flatMap(Screen.init) ?? .decks
    }

    @ViewBuilder
    static func rootView() -> some View {
        switch screen {
        case .decks:
            WatchDeckListView()
        case .question, .answer:
            NavigationStack {
                WatchStudyView(deck: studyDeck, shuffle: false, revealFirstCard: screen == .answer)
            }
        }
    }

    static let decks: [WatchDeckPayload] = [
        deck("Spanish Vocabulary", dueCount: 25, cards: spanishCards),
        deck("World Capitals", dueCount: 18, cards: [("Japan", "Tokyo"), ("Peru", "Lima")]),
        deck("French Vocabulary", dueCount: 12, cards: [("le chat", "the cat")]),
        deck("US Presidents", dueCount: 7, cards: [("16th President", "Abraham Lincoln")]),
    ]

    private static var studyDeck: WatchDeckPayload { decks[0] }

    private static let spanishCards = [
        ("la biblioteca", "the library"),
        ("el perro", "the dog"),
        ("la manzana", "the apple"),
        ("el reloj", "the watch"),
        ("la playa", "the beach"),
        ("el libro", "the book"),
        ("la ventana", "the window"),
        ("el tren", "the train"),
        ("la luna", "the moon"),
        ("el queso", "the cheese"),
        ("la cocina", "the kitchen"),
        ("el árbol", "the tree"),
    ]

    private static func deck(_ name: String, dueCount: Int, cards: [(String, String)]) -> WatchDeckPayload {
        WatchDeckPayload(
            id: UUID(),
            name: name,
            cards: cards.map {
                WatchCardPayload(id: UUID(), front: $0.0, back: $0.1, easeFactor: 2.5, interval: 1, statusRaw: CardStatus.review.rawValue)
            },
            dueCount: dueCount
        )
    }
}
#endif
