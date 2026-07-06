import XCTest
@testable import Ghosted

final class GhostedTests: XCTestCase {

    @MainActor
    private func freshStore() -> GhostedStore {
        let store = GhostedStore()
        for c in store.contacts { store.deleteContact(c.id) }
        return store
    }

    func testGhostLevelZeroRightAfterTexting() {
        let contact = Contact(name: "Test", lastTextedDate: Date())
        XCTAssertEqual(contact.ghostLevel, 0, accuracy: 0.01)
        XCTAssertFalse(contact.isGhosted)
    }

    func testGhostLevelAtHalfThreshold() {
        let texted = Calendar.current.date(byAdding: .hour, value: -36, to: Date())! // 1.5 days of 3
        let contact = Contact(name: "Test", lastTextedDate: texted)
        XCTAssertEqual(contact.ghostLevel, 0.5, accuracy: 0.05)
    }

    func testIsGhostedAfterThreshold() {
        let texted = Calendar.current.date(byAdding: .day, value: -5, to: Date())!
        let contact = Contact(name: "Test", lastTextedDate: texted)
        XCTAssertTrue(contact.isGhosted)
        XCTAssertEqual(contact.ghostLevel, 1.0, accuracy: 0.01)
    }

    func testMarkRepliedResetsGhostLevel() {
        var contact = Contact(name: "Test", lastTextedDate: Calendar.current.date(byAdding: .day, value: -5, to: Date())!)
        XCTAssertTrue(contact.isGhosted)
        contact.markReplied()
        XCTAssertEqual(contact.ghostLevel, 0, accuracy: 0.01)
        XCTAssertFalse(contact.isGhosted)
    }

    func testMarkTextedAgainResetsAndClearsReplyFlag() {
        var contact = Contact(name: "Test", lastTextedDate: Calendar.current.date(byAdding: .day, value: -5, to: Date())!)
        contact.markReplied()
        contact.markTextedAgain()
        XCTAssertFalse(contact.hasRepliedSinceLastText)
        XCTAssertEqual(contact.ghostLevel, 0, accuracy: 0.01)
    }

    @MainActor
    func testAddContactRespectsFreeLimit() {
        let store = freshStore()
        XCTAssertTrue(store.addContact(name: "A", note: "", isPro: false))
        XCTAssertTrue(store.addContact(name: "B", note: "", isPro: false))
        XCTAssertTrue(store.addContact(name: "C", note: "", isPro: false))
        XCTAssertFalse(store.addContact(name: "D", note: "", isPro: false))
        XCTAssertTrue(store.addContact(name: "D", note: "", isPro: true))
    }

    @MainActor
    func testDeleteContactRemovesIt() {
        let store = freshStore()
        store.addContact(name: "Removable", note: "", isPro: false)
        let contact = store.contacts[0]
        store.deleteContact(contact.id)
        XCTAssertTrue(store.contacts.isEmpty)
    }

    @MainActor
    func testMarkRepliedViaStore() {
        let store = freshStore()
        store.addContact(name: "Waiting", note: "", isPro: false)
        let contact = store.contacts[0]
        store.markReplied(contact.id)
        XCTAssertTrue(store.contact(contact.id)!.hasRepliedSinceLastText)
    }
}
