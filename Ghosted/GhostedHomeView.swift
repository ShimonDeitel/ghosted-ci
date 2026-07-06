import SwiftUI

struct GhostedHomeView: View {
    @EnvironmentObject private var store: GhostedStore
    @EnvironmentObject private var purchases: PurchaseManager

    @State private var sheetMode: GhostedSheetMode?
    @State private var deletingContact: Contact?
    @State private var repliedName: String?

    var body: some View {
        NavigationStack {
            ZStack {
                GHTheme.backdrop.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 22) {
                        HStack {
                            Text("Ghosted")
                                .font(GHTheme.titleFont)
                                .foregroundStyle(GHTheme.ink)
                            Spacer()
                            Button {
                                if store.canAddContact(isPro: purchases.isPro) {
                                    sheetMode = .add
                                } else {
                                    sheetMode = .paywall
                                }
                            } label: {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 24))
                                    .foregroundStyle(GHTheme.violetBright)
                            }
                            .accessibilityIdentifier("addContactButton")
                        }
                        .padding(.horizontal, 18)
                        .padding(.top, 8)

                        if store.contacts.isEmpty {
                            emptyState
                        } else {
                            VStack(spacing: 12) {
                                ForEach(store.contacts) { contact in
                                    ContactRow(
                                        contact: contact,
                                        onTextedAgain: {
                                            Haptics.medium()
                                            store.markTextedAgain(contact.id)
                                        },
                                        onReplied: {
                                            Haptics.success()
                                            store.markReplied(contact.id)
                                            repliedName = contact.name
                                            Task {
                                                try? await Task.sleep(nanoseconds: 1_800_000_000)
                                                if repliedName == contact.name { repliedName = nil }
                                            }
                                        },
                                        onEdit: { sheetMode = .edit(contact) },
                                        onDelete: {
                                            Haptics.warning()
                                            deletingContact = contact
                                        }
                                    )
                                }
                            }
                            .padding(.horizontal, 18)

                            if !purchases.isPro {
                                Text("Free plan: \(store.contacts.count)/\(GhostedStore.freeContactLimit) contacts tracked")
                                    .font(.caption)
                                    .foregroundStyle(GHTheme.inkFaded)
                                    .padding(.horizontal, 18)
                            }
                        }
                    }
                    .padding(.bottom, 24)
                }

                if let name = repliedName {
                    VStack {
                        Spacer()
                        Text("\(name) replied!")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .background(GHTheme.cyan)
                            .clipShape(Capsule())
                            .padding(.bottom, 20)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                    .allowsHitTesting(false)
                }
            }
            .navigationBarHidden(true)
            .sheet(item: $sheetMode) { mode in
                switch mode {
                case .paywall:
                    PaywallView().environmentObject(purchases)
                case .add, .edit:
                    ContactEditSheet(mode: mode) { name, note in
                        switch mode {
                        case .add:
                            store.addContact(name: name, note: note, isPro: purchases.isPro)
                        case .edit(let c):
                            store.updateContact(c.id, name: name, note: note)
                        case .paywall:
                            break
                        }
                    }
                }
            }
            .confirmationDialog(
                "Remove \(deletingContact?.name ?? "Contact")?",
                isPresented: Binding(
                    get: { deletingContact != nil },
                    set: { if !$0 { deletingContact = nil } }
                ),
                titleVisibility: .visible
            ) {
                Button("Remove", role: .destructive) {
                    if let deletingContact {
                        store.deleteContact(deletingContact.id)
                    }
                    deletingContact = nil
                }
                Button("Cancel", role: .cancel) { deletingContact = nil }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: "message")
                .font(.system(size: 34))
                .foregroundStyle(GHTheme.inkFaded)
            Text("No one tracked yet. Tap + to add someone you're waiting on.")
                .font(.subheadline)
                .foregroundStyle(GHTheme.inkFaded)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
}

/// The quirky signature feature: each contact shows a ghost-face avatar that
/// visibly fades (opacity drops) and drifts/wobbles more the longer they've
/// gone unanswered — a literal "ghosting" visual, distinct from a plain
/// list-and-form tracker.
private struct ContactRow: View {
    let contact: Contact
    let onTextedAgain: () -> Void
    let onReplied: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void

    @State private var wobble = false

    private var statusColor: Color {
        if contact.hasRepliedSinceLastText { return GHTheme.cyan }
        if contact.isGhosted { return GHTheme.danger }
        return GHTheme.violet
    }

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle().fill(GHTheme.surfaceRaised)
                Image(systemName: "figure.stand")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(GHTheme.violetBright.opacity(contact.hasRepliedSinceLastText ? 1 : max(0.18, 1 - contact.ghostLevel)))
                    .offset(y: wobble ? -3 : 3)
                    .animation(
                        contact.isGhosted
                            ? .easeInOut(duration: 1.4).repeatForever(autoreverses: true)
                            : .default,
                        value: wobble
                    )
            }
            .frame(width: 48, height: 48)
            .onAppear { if contact.isGhosted { wobble = true } }
            .accessibilityIdentifier("ghostAvatar_\(contact.name)")

            VStack(alignment: .leading, spacing: 3) {
                Text(contact.name)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(GHTheme.ink)
                Text(statusText)
                    .font(.caption)
                    .foregroundStyle(GHTheme.inkFaded)
            }

            Spacer()

            if contact.hasRepliedSinceLastText {
                Button(action: onTextedAgain) {
                    Image(systemName: "paperplane.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                        .padding(10)
                        .background(Circle().fill(GHTheme.violet))
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("textAgainButton_\(contact.name)")
            } else {
                Button(action: onReplied) {
                    Image(systemName: "checkmark")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                        .padding(10)
                        .background(Circle().fill(GHTheme.cyan))
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("markRepliedButton_\(contact.name)")
            }

            Menu {
                Button(action: onEdit) {
                    Label("Edit", systemImage: "pencil")
                }
                Button(role: .destructive, action: onDelete) {
                    Label("Remove", systemImage: "trash")
                }
            } label: {
                Image(systemName: "ellipsis")
                    .foregroundStyle(GHTheme.inkFaded)
                    .padding(8)
            }
            .accessibilityIdentifier("contactMenu_\(contact.name)")
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 16).fill(GHTheme.surface))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(statusColor.opacity(0.4), lineWidth: 1.5)
        )
    }

    private var statusText: String {
        if contact.hasRepliedSinceLastText { return "Replied" }
        if contact.isGhosted { return "Ghosted — no reply in \(Int(contact.daysSinceTexted))d" }
        return "Waiting on a reply"
    }
}

#Preview {
    GhostedHomeView()
        .environmentObject(GhostedStore())
        .environmentObject(PurchaseManager())
}
