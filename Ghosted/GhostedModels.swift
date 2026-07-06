import Foundation

struct Contact: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var note: String
    var lastTextedDate: Date
    var hasRepliedSinceLastText: Bool
    var createdDate: Date

    init(
        id: UUID = UUID(),
        name: String,
        note: String = "",
        lastTextedDate: Date = Date(),
        hasRepliedSinceLastText: Bool = false,
        createdDate: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.note = note
        self.lastTextedDate = lastTextedDate
        self.hasRepliedSinceLastText = hasRepliedSinceLastText
        self.createdDate = createdDate
    }

    var daysSinceTexted: Double {
        Date().timeIntervalSince(lastTextedDate) / 86400.0
    }

    /// 0 = just texted / already replied, 1 = fully "ghosted" (or past it).
    /// Drives the fading-ghost visual: more silence = more transparent/faded.
    var ghostLevel: Double {
        guard !hasRepliedSinceLastText else { return 0 }
        let threshold = 3.0 // days considered "fully ghosted"
        return min(1, max(0, daysSinceTexted / threshold))
    }

    var isGhosted: Bool { !hasRepliedSinceLastText && daysSinceTexted > 3 }

    mutating func markTextedAgain(now: Date = Date()) {
        lastTextedDate = now
        hasRepliedSinceLastText = false
    }

    mutating func markReplied() {
        hasRepliedSinceLastText = true
    }
}
