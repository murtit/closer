import XCTest

/// Walks through the main screens with demo data and keeps a screenshot of each one, in light and
/// dark mode. CI exports the screenshots and posts them on the pull request (see `.github/workflows/ci.yml`).
final class ScreenshotTests: XCTestCase {
    @MainActor
    func testMainScreensLight() throws {
        try captureMainScreens(appearance: .light, suffix: "light")
    }

    @MainActor
    func testMainScreensDark() throws {
        try captureMainScreens(appearance: .dark, suffix: "dark")
    }

    // MARK: - Flow

    @MainActor
    private func captureMainScreens(appearance: XCUIDevice.Appearance, suffix: String) throws {
        continueAfterFailure = false
        XCUIDevice.shared.orientation = .portrait
        XCUIDevice.shared.appearance = appearance

        let app = XCUIApplication()
        // `-demo-data` goes last: a dash argument followed by another one would be read as its value.
        app.launchArguments = ["-AppleLanguages", "(de-CH)", "-AppleLocale", "de_CH", "-demo-data"]
        app.launch()

        XCTAssertTrue(app.staticTexts["Wem bist du heute nah?"].waitForExistence(timeout: 15))
        snapshot("01-heute", suffix)

        app.tabBars.buttons["Personen"].tap()
        let personRow = app.buttons["personRow.Lea Brunner"]
        XCTAssertTrue(personRow.waitForExistence(timeout: 5))
        snapshot("02-personen", suffix)

        app.navigationBars["Personen"].buttons["Person hinzufügen"].tap()
        XCTAssertTrue(app.navigationBars["Person hinzufügen"].waitForExistence(timeout: 5))
        snapshot("03-person-hinzufuegen", suffix)
        app.navigationBars["Person hinzufügen"].buttons["Abbrechen"].tap()

        XCTAssertTrue(personRow.waitForExistence(timeout: 5))
        personRow.tap()
        XCTAssertTrue(app.navigationBars["Lea Brunner"].waitForExistence(timeout: 5))
        snapshot("04-person", suffix)

        app.staticTexts["Spontanes Date planen"].firstMatch.tap()
        XCTAssertTrue(app.navigationBars["Erinnerung"].waitForExistence(timeout: 5))
        snapshot("05-erinnerung", suffix)
    }

    // MARK: - Helpers

    /// Attaches a full-screen screenshot that survives a passing run, named e.g. `01-heute-light`.
    @MainActor
    private func snapshot(_ name: String, _ suffix: String) {
        // Let push and sheet animations finish; `waitForExistence` returns as soon as the
        // element appears, which can be mid-transition.
        Thread.sleep(forTimeInterval: 1)
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = "\(name)-\(suffix)"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
