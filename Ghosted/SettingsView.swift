import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var store: GhostedStore
    @EnvironmentObject private var purchases: PurchaseManager
    @AppStorage("ghosted_haptics_enabled") private var hapticsEnabled: Bool = true
    @AppStorage("ghosted_ghost_threshold_days") private var ghostThresholdDays: Int = 3

    @State private var showingDeleteConfirm = false
    @State private var sheetMode: GhostedSheetMode?

    var body: some View {
        NavigationStack {
            ZStack {
                GHTheme.backdrop.ignoresSafeArea()

                Form {
                    Section {
                        if purchases.isPro {
                            HStack {
                                Image(systemName: "checkmark.seal.fill").foregroundStyle(GHTheme.violetBright)
                                Text("Ghosted Pro unlocked")
                                    .foregroundStyle(GHTheme.ink)
                            }
                        } else {
                            Button {
                                sheetMode = .paywall
                            } label: {
                                HStack {
                                    Image(systemName: "star.fill").foregroundStyle(GHTheme.violetBright)
                                    Text("Unlock Ghosted Pro")
                                        .foregroundStyle(GHTheme.ink)
                                    Spacer()
                                    Image(systemName: "chevron.right").foregroundStyle(GHTheme.inkFaded)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    Section("Ghost Threshold") {
                        Stepper("Consider ghosted after \(ghostThresholdDays) day\(ghostThresholdDays == 1 ? "" : "s")", value: $ghostThresholdDays, in: 1...14)
                            .accessibilityIdentifier("ghostThresholdStepper")
                    }

                    Section("Contacts") {
                        ForEach(store.contacts) { contact in
                            HStack {
                                Text(contact.name).foregroundStyle(GHTheme.ink)
                                Spacer()
                                Text(contact.hasRepliedSinceLastText ? "Replied" : "Waiting")
                                    .font(.caption)
                                    .foregroundStyle(GHTheme.inkFaded)
                                Button {
                                    sheetMode = .edit(contact)
                                } label: {
                                    Image(systemName: "pencil.circle").foregroundStyle(GHTheme.inkFaded)
                                }
                                .buttonStyle(.plain)
                                .accessibilityElement(children: .ignore)
                                .accessibilityIdentifier("editContact_\(contact.name)")
                                .accessibilityAddTraits(.isButton)
                            }
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    store.deleteContact(contact.id)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                                .accessibilityIdentifier("deleteContactSwipe_\(contact.name)")
                            }
                        }
                        .onMove { source, destination in
                            store.moveContacts(from: source, to: destination)
                        }

                        Button {
                            if store.canAddContact(isPro: purchases.isPro) {
                                sheetMode = .add
                            } else {
                                sheetMode = .paywall
                            }
                        } label: {
                            Label("Add Contact", systemImage: "plus.circle")
                                .foregroundStyle(GHTheme.violetBright)
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("settingsAddContactButton")

                        if !purchases.isPro {
                            Text("\(store.contacts.count)/\(GhostedStore.freeContactLimit) free contacts used")
                                .font(.caption)
                                .foregroundStyle(GHTheme.inkFaded)
                        }
                    }

                    Section("Preferences") {
                        Toggle(isOn: $hapticsEnabled) {
                            Label("Haptics", systemImage: "hand.tap.fill")
                                .foregroundStyle(GHTheme.ink)
                        }
                        .tint(GHTheme.violet)
                        .onChange(of: hapticsEnabled) { _, newValue in
                            Haptics.enabled = newValue
                        }

                        Button {
                            Task { await purchases.restore() }
                        } label: {
                            Label("Restore Purchases", systemImage: "arrow.clockwise")
                                .foregroundStyle(GHTheme.ink)
                        }
                        .buttonStyle(.plain)
                    }

                    Section("About") {
                        Link(destination: URL(string: "https://shimondeitel.github.io/ghosted-site/privacy.html")!) {
                            Label("Privacy Policy", systemImage: "hand.raised.fill")
                                .foregroundStyle(GHTheme.ink)
                        }
                        Link(destination: URL(string: "https://shimondeitel.github.io/ghosted-site/support.html")!) {
                            Label("Support", systemImage: "questionmark.circle")
                                .foregroundStyle(GHTheme.ink)
                        }
                        Link(destination: URL(string: "mailto:s0533495227@gmail.com")!) {
                            Label("Contact Support", systemImage: "envelope.fill")
                                .foregroundStyle(GHTheme.ink)
                        }
                        HStack {
                            Text("Version").foregroundStyle(GHTheme.ink)
                            Spacer()
                            Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")
                                .foregroundStyle(GHTheme.inkFaded)
                        }
                    }

                    Section {
                        Button(role: .destructive) {
                            showingDeleteConfirm = true
                        } label: {
                            Label("Delete All Data", systemImage: "trash.fill")
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .navigationTitle("Settings")
            .toolbar { EditButton() }
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
            .alert("Delete All Data?", isPresented: $showingDeleteConfirm) {
                Button("Cancel", role: .cancel) {}
                Button("Delete Everything", role: .destructive) {
                    store.deleteAllData()
                }
            } message: {
                Text("This permanently removes every tracked contact. This cannot be undone.")
            }
        }
        .dismissKeyboardOnTap()
    }
}

#Preview {
    SettingsView()
        .environmentObject(GhostedStore())
        .environmentObject(PurchaseManager())
}
