import SwiftUI

/// One unified sheet enum per screen — stacking multiple `.sheet(item:)` or
/// `.alert(...)` modifiers on the same view is a known SwiftUI bug (only the
/// last-declared one reliably fires). Route every sheet through this enum.
enum GhostedSheetMode: Identifiable {
    case add
    case edit(Contact)
    case paywall

    var id: String {
        switch self {
        case .add: return "add"
        case .edit(let c): return c.id.uuidString
        case .paywall: return "paywall"
        }
    }
}

struct ContactEditSheet: View {
    let mode: GhostedSheetMode
    let onSave: (String, String) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var name: String
    @State private var note: String

    init(mode: GhostedSheetMode, onSave: @escaping (String, String) -> Void) {
        self.mode = mode
        self.onSave = onSave
        if case .edit(let c) = mode {
            _name = State(initialValue: c.name)
            _note = State(initialValue: c.note)
        } else {
            _name = State(initialValue: "")
            _note = State(initialValue: "")
        }
    }

    private var title: String {
        if case .edit = mode { return "Edit Contact" }
        return "New Contact"
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Contact") {
                    TextField("Name", text: $name)
                        .accessibilityIdentifier("contactNameField")
                }
                Section("What did you text about?") {
                    TextField("e.g. About the weekend plans", text: $note, axis: .vertical)
                        .lineLimit(1...4)
                        .accessibilityIdentifier("contactNoteField")
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave(name, note)
                        dismiss()
                    }
                    .accessibilityIdentifier("contactSaveButton")
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
        .dismissKeyboardOnTap()
    }
}
