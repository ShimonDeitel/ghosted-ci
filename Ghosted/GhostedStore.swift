import Foundation
import Combine

@MainActor
final class GhostedStore: ObservableObject {
    @Published private(set) var contacts: [Contact] = []

    static let freeContactLimit = 3

    private let fileURL: URL

    init() {
        let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        self.fileURL = dir.appendingPathComponent("ghosted_data.json")
        if ProcessInfo.processInfo.arguments.contains("-uiTestReset") {
            try? FileManager.default.removeItem(at: fileURL)
        }
        load()
        if contacts.isEmpty {
            seedDefaults()
        }
    }

    private func seedDefaults() {
        contacts = [
            Contact(name: "Alex", note: "About the weekend plans",
                    lastTextedDate: Calendar.current.date(byAdding: .day, value: -4, to: Date())!,
                    hasRepliedSinceLastText: false),
            Contact(name: "Jamie", note: "Following up on the job lead",
                    lastTextedDate: Calendar.current.date(byAdding: .hour, value: -6, to: Date())!,
                    hasRepliedSinceLastText: false)
        ]
        save()
    }

    func canAddContact(isPro: Bool) -> Bool {
        isPro || contacts.count < Self.freeContactLimit
    }

    @discardableResult
    func addContact(name: String, note: String, isPro: Bool) -> Bool {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, canAddContact(isPro: isPro) else { return false }
        contacts.append(Contact(name: trimmed, note: note.trimmingCharacters(in: .whitespacesAndNewlines)))
        save()
        return true
    }

    func updateContact(_ id: UUID, name: String, note: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, let idx = contacts.firstIndex(where: { $0.id == id }) else { return }
        contacts[idx].name = trimmed
        contacts[idx].note = note.trimmingCharacters(in: .whitespacesAndNewlines)
        save()
    }

    func deleteContact(_ id: UUID) {
        contacts.removeAll { $0.id == id }
        save()
    }

    func moveContacts(from source: IndexSet, to destination: Int) {
        contacts.move(fromOffsets: source, toOffset: destination)
        save()
    }

    /// The quirky signature feature: marking "texted again" resets the ghost
    /// fade back to fully solid, restarting the silence countdown.
    func markTextedAgain(_ id: UUID) {
        guard let idx = contacts.firstIndex(where: { $0.id == id }) else { return }
        contacts[idx].markTextedAgain()
        save()
    }

    func markReplied(_ id: UUID) {
        guard let idx = contacts.firstIndex(where: { $0.id == id }) else { return }
        contacts[idx].markReplied()
        save()
    }

    func contact(_ id: UUID) -> Contact? {
        contacts.first { $0.id == id }
    }

    func deleteAllData() {
        contacts = []
        seedDefaults()
    }

    var anyGhosted: Bool {
        contacts.contains { $0.isGhosted }
    }

    // MARK: - Persistence

    private struct Snapshot: Codable {
        var contacts: [Contact]
    }

    private func load() {
        guard let data = try? Data(contentsOf: fileURL) else { return }
        if let decoded = try? JSONDecoder().decode(Snapshot.self, from: data) {
            contacts = decoded.contacts
        }
    }

    private func save() {
        let snapshot = Snapshot(contacts: contacts)
        guard let data = try? JSONEncoder().encode(snapshot) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }
}
