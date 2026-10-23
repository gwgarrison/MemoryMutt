import XCTest

/// Drives the app through the screens that make up the App Store listing.
///
/// The app is launched with `-ScreenshotMode`, which swaps in an in-memory store seeded
/// by `ScreenshotDemoData` — so every device and every run sees identical content.
/// Run it through fastlane rather than Xcode: `fastlane ios screenshots`.
@MainActor
final class ScreenshotTests: XCTestCase {

    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false

        app = XCUIApplication()
        app.launchArguments += ["-ScreenshotMode", "-AppleLanguages", "(en)", "-AppleLocale", "en_US"]
        setupSnapshot(app)
        app.launch()
    }

    func testCaptureAppStoreScreenshots() throws {
        // The seed installs ~850 cards; give the first render room to settle.
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 30))
        waitForTabBar()

        snapshot("01_Home")

        if openTab("Decks") {
            snapshot("02_Decks")

            // Drill into a deck for the card-management shot. Optional: if the cell
            // can't be found on this device's layout, keep the run going rather than
            // failing every remaining screenshot.
            if openDeck(named: "World Capitals") {
                snapshot("03_DeckDetail")
                goBack()
            }
        }

        if openTab("Study") {
            snapshot("04_Study")
        }

        if openTab("Statistics") {
            snapshot("05_Statistics")

            // The activity heatmap sits below the fold and is one of the more
            // distinctive screens, so scroll it into view for its own shot.
            app.swipeUp()
            settle()
            snapshot("06_Activity")
        }

        if openTab("Settings") {
            snapshot("07_Settings")
        }
    }

    // MARK: - Navigation helpers

    /// SwiftUI renders the tab bar differently across iPhone and iPad: iPhone gets a
    /// real `tabBar`, iPad a plain container of buttons that nests a duplicate button
    /// inside each tab. That nesting makes a plain subscript ambiguous, so every query
    /// here resolves through `.firstMatch`.
    @discardableResult
    private func openTab(_ name: String) -> Bool {
        let tabBarButton = app.tabBars.buttons[name].firstMatch
        if tabBarButton.waitForExistence(timeout: 5), tabBarButton.isHittable {
            tabBarButton.tap()
            return settle()
        }

        let anyButton = app.buttons[name].firstMatch
        if anyButton.waitForExistence(timeout: 5), anyButton.isHittable {
            anyButton.tap()
            return settle()
        }

        XCTFail("Could not find a way to open the \(name) tab. Hierarchy:\n\(app.debugDescription)")
        return false
    }

    /// Deck cells get a combined accessibility label like "105, World Capitals, 248 cards"
    /// — the due badge reads first — so match "<name>," anywhere in it rather than the
    /// bare name, which also appears on other rows and would make a subscript ambiguous.
    private func openDeck(named name: String) -> Bool {
        let cell = app.buttons
            .matching(NSPredicate(format: "label CONTAINS %@", "\(name),"))
            .firstMatch

        guard cell.waitForExistence(timeout: 5), cell.isHittable else { return false }
        cell.tap()
        return settle()
    }

    private func goBack() {
        let backButton = app.navigationBars.buttons.element(boundBy: 0)
        if backButton.exists, backButton.isHittable {
            backButton.tap()
            _ = settle()
        }
    }

    private func waitForTabBar() {
        // Seeding runs synchronously at container construction, so the first frame is
        // already populated — this just guards against a slow simulator boot.
        _ = app.tabBars.firstMatch.waitForExistence(timeout: 20)
    }

    /// Let animations and SwiftData-backed queries land before the shutter.
    @discardableResult
    private func settle() -> Bool {
        Thread.sleep(forTimeInterval: 1.2)
        return true
    }
}
