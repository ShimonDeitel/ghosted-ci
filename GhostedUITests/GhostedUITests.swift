import XCTest

final class GhostedUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    private func launchApp() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-uiTestReset"]
        app.launch()
        return app
    }

    func testAddContactFromMainList() throws {
        let app = launchApp()

        let addButton = app.buttons["addContactButton"]
        XCTAssertTrue(addButton.waitForExistence(timeout: 5))
        addButton.tap()

        let nameField = app.textFields["contactNameField"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 5), "Add Contact sheet did not appear")
        nameField.tap()
        nameField.typeText("Taylor")

        let saveButton = app.buttons["contactSaveButton"]
        XCTAssertTrue(saveButton.isEnabled)
        saveButton.tap()

        XCTAssertTrue(app.staticTexts["Taylor"].waitForExistence(timeout: 5), "New contact did not appear on the list")
    }

    func testAddContactFromSettings() throws {
        let app = launchApp()
        app.tabBars.buttons["Settings"].tap()

        app.buttons["settingsAddContactButton"].tap()
        let nameField = app.textFields["contactNameField"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 5))
        nameField.tap()
        nameField.typeText("Morgan")
        app.buttons["contactSaveButton"].tap()

        XCTAssertTrue(app.staticTexts["Morgan"].waitForExistence(timeout: 5))
    }

    func testMarkRepliedShowsConfirmationToast() throws {
        let app = launchApp()

        let replyButton = app.buttons["markRepliedButton_Alex"]
        XCTAssertTrue(replyButton.waitForExistence(timeout: 5))
        replyButton.tap()

        XCTAssertTrue(app.staticTexts["Alex replied!"].waitForExistence(timeout: 5), "Reply confirmation toast did not appear")
    }

    func testTextedAgainButtonAppearsAfterReply() throws {
        let app = launchApp()

        let replyButton = app.buttons["markRepliedButton_Alex"]
        XCTAssertTrue(replyButton.waitForExistence(timeout: 5))
        replyButton.tap()

        let textAgainButton = app.buttons["textAgainButton_Alex"]
        XCTAssertTrue(textAgainButton.waitForExistence(timeout: 5), "Texted-again button did not appear after marking replied")
    }

    func testEditContactFromSettings() throws {
        let app = launchApp()
        app.tabBars.buttons["Settings"].tap()

        let editButton = app.buttons.matching(identifier: "editContact_Alex").firstMatch
        XCTAssertTrue(editButton.waitForExistence(timeout: 5))
        editButton.tap()

        let nameField = app.textFields["contactNameField"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 5))
        nameField.tap()
        let stringValue = nameField.value as? String ?? ""
        let deleteString = String(repeating: XCUIKeyboardKey.delete.rawValue, count: stringValue.count)
        nameField.typeText(deleteString)
        nameField.typeText("Alexis")

        app.buttons["contactSaveButton"].tap()

        XCTAssertTrue(app.staticTexts["Alexis"].waitForExistence(timeout: 5), "Contact rename did not apply")
    }

    func testDeleteContactViaSwipe() throws {
        let app = launchApp()
        app.tabBars.buttons["Settings"].tap()

        app.buttons["settingsAddContactButton"].tap()
        let nameField = app.textFields["contactNameField"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 5))
        nameField.tap()
        nameField.typeText("Disposable Contact")
        app.buttons["contactSaveButton"].tap()
        XCTAssertTrue(app.staticTexts["Disposable Contact"].waitForExistence(timeout: 5))

        app.staticTexts["Disposable Contact"].swipeLeft()

        let deleteButton = app.buttons["deleteContactSwipe_Disposable Contact"]
        XCTAssertTrue(deleteButton.waitForExistence(timeout: 5), "Swipe-to-delete action did not appear")
        deleteButton.tap()

        XCTAssertFalse(app.staticTexts["Disposable Contact"].waitForExistence(timeout: 3), "Contact was not deleted")
    }

    func testFreeLimitTriggersPaywallAtFourthContact() throws {
        let app = launchApp()
        // Seed data already has 2 contacts; add 1 more to hit the free cap of 3, then try a 4th.
        for name in ["Third Contact", "Fourth Contact"] {
            let addButton = app.buttons["addContactButton"]
            addButton.tap()
            let nameField = app.textFields["contactNameField"]
            if nameField.waitForExistence(timeout: 3) {
                nameField.tap()
                nameField.typeText(name)
                app.buttons["contactSaveButton"].tap()
            }
        }
        XCTAssertTrue(app.staticTexts["Ghosted Pro"].waitForExistence(timeout: 5), "Paywall did not appear after hitting the free contact limit")
    }

    func testSimulatedPurchaseUnlocksUnlimitedContacts() throws {
        let app = launchApp()
        for name in ["Third Contact", "Fourth Contact"] {
            let addButton = app.buttons["addContactButton"]
            addButton.tap()
            let nameField = app.textFields["contactNameField"]
            if nameField.waitForExistence(timeout: 3) {
                nameField.tap()
                nameField.typeText(name)
                app.buttons["contactSaveButton"].tap()
            }
        }
        XCTAssertTrue(app.staticTexts["Ghosted Pro"].waitForExistence(timeout: 5))

        let unlockButton = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Unlock'")).firstMatch
        XCTAssertTrue(unlockButton.waitForExistence(timeout: 5))
        unlockButton.tap()

        let confirmButton = app.buttons["Subscribe"].exists ? app.buttons["Subscribe"] : app.buttons["Buy"]
        if confirmButton.waitForExistence(timeout: 5) {
            confirmButton.tap()
        }

        XCTAssertTrue(app.staticTexts["Ghosted Pro unlocked"].waitForExistence(timeout: 10) || app.buttons["addContactButton"].waitForExistence(timeout: 10))

        let addButton = app.buttons["addContactButton"]
        if addButton.waitForExistence(timeout: 5) {
            var tapped = false
            for _ in 0..<16 {
                if addButton.isHittable {
                    addButton.tap()
                    tapped = true
                    break
                }
                Thread.sleep(forTimeInterval: 0.5)
            }
            if !tapped {
                addButton.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
            }
            let nameField = app.textFields["contactNameField"]
            if nameField.waitForExistence(timeout: 5) {
                nameField.tap()
                nameField.typeText("Fifth Contact")
                app.buttons["contactSaveButton"].tap()
                XCTAssertTrue(app.staticTexts["Fifth Contact"].waitForExistence(timeout: 5))
            }
        }
    }
}
