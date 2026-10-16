import XCTest

/// Walks through the main screens with demo data and keeps a screenshot of each one, in light and
/// dark mode. CI exports the screenshots and posts them on the pull request (see `.github/workflows/ci.yml`).
final class ScreenshotTests: XCTestCase {
    @MainActor
    func testMainScreensLight() throws {
        try captureMainScreens(appearance: "light")
    }

    @MainActor
    func testMainScreensDark() throws {
        try captureMainScreens(appearance: "dark")
    }

    // MARK: - Flow

    @MainActor
    private func captureMainScreens(appearance: String) throws {
        continueAfterFailure = false
        XCUIDevice.shared.orientation = .portrait

        let app = XCUIApplication()
        // `-demo-data` goes last: a dash argument followed by another one would be read as its value.
        app.launchArguments = [
            "-AppleLanguages", "(de-CH)",
            "-AppleLocale", "de_CH",
            "-demo-appearance", appearance,
            "-demo-data",
        ]
        app.launch()

        XCTAssertTrue(app.staticTexts["Wem bist du heute nah?"].waitForExistence(timeout: 15))
        XCTAssertTrue(app.descendants(matching: .any)["partnerCard"].exists)
        snapshot("01-heute", appearance)

        app.tabBars.buttons["Personen"].tap()
        let personRow = app.buttons["personRow.Lea Brunner"]
        XCTAssertTrue(personRow.waitForExistence(timeout: 5))
        snapshot("02-personen", appearance)

        app.navigationBars["Personen"].buttons["Person hinzufügen"].tap()
        XCTAssertTrue(app.navigationBars["Person hinzufügen"].waitForExistence(timeout: 5))
        snapshot("03-person-hinzufuegen", appearance)
        app.navigationBars["Person hinzufügen"].buttons["Abbrechen"].tap()

        XCTAssertTrue(personRow.waitForExistence(timeout: 5))
        personRow.tap()
        XCTAssertTrue(app.navigationBars["Lea Brunner"].waitForExistence(timeout: 5))
        snapshot("04-person", appearance)

        app.staticTexts["Spontanes Date planen"].firstMatch.tap()
        XCTAssertTrue(app.navigationBars["Erinnerung"].waitForExistence(timeout: 5))
        snapshot("05-erinnerung", appearance)
        app.navigationBars["Erinnerung"].buttons["Abbrechen"].tap()

        XCTAssertTrue(app.navigationBars["Lea Brunner"].waitForExistence(timeout: 5))
        app.buttons["anniversaryRow"].tap()
        XCTAssertTrue(app.navigationBars["Jahrestag"].waitForExistence(timeout: 5))
        snapshot("06-jahrestag", appearance)
        app.navigationBars["Jahrestag"].buttons["Abbrechen"].tap()

        XCTAssertTrue(app.navigationBars["Lea Brunner"].waitForExistence(timeout: 5))
        app.navigationBars["Lea Brunner"].buttons["Bearbeiten"].tap()
        XCTAssertTrue(app.navigationBars["Person bearbeiten"].waitForExistence(timeout: 5))
        let soundRow = app.buttons["notificationSoundRow"]
        if !soundRow.isHittable { app.swipeUp() }
        soundRow.tap()
        XCTAssertTrue(app.navigationBars["Benachrichtigungston"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["sound.naehe"].isSelected)
        snapshot("07-benachrichtigungston", appearance)
        app.navigationBars["Benachrichtigungston"].buttons.firstMatch.tap()
        XCTAssertTrue(app.navigationBars["Person bearbeiten"].waitForExistence(timeout: 5))
        app.navigationBars["Person bearbeiten"].buttons["Abbrechen"].tap()

        XCTAssertTrue(app.navigationBars["Lea Brunner"].waitForExistence(timeout: 5))
        app.tabBars.buttons["Heute"].tap()
        let settingsButton = app.buttons["Einstellungen"]
        XCTAssertTrue(settingsButton.waitForExistence(timeout: 5))
        settingsButton.tap()
        XCTAssertTrue(app.navigationBars["Einstellungen"].waitForExistence(timeout: 5))
        snapshot("08-einstellungen", appearance)
        app.navigationBars["Einstellungen"].buttons["Fertig"].tap()

        // Ideas come from fixed demo ideas, so the screenshots do not depend on Apple Intelligence.
        let ideasButton = app.buttons["partnerIdeasButton"]
        XCTAssertTrue(ideasButton.waitForExistence(timeout: 5))
        ideasButton.tap()
        XCTAssertTrue(app.navigationBars["Ideen"].waitForExistence(timeout: 5))
        app.buttons["findIdeasButton"].tap()
        XCTAssertTrue(app.staticTexts["Pasta-Abend wie in Rom"].waitForExistence(timeout: 10))
        snapshot("09-ideen", appearance)

        app.buttons["ideaPlacesButton"].firstMatch.tap()
        XCTAssertTrue(app.navigationBars["Pasta-Abend wie in Rom"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["placeCard"].firstMatch.waitForExistence(timeout: 10))
        // Map tiles load after the places; give them a moment more than other screens.
        Thread.sleep(forTimeInterval: 2)
        snapshot("10-orte", appearance)
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
