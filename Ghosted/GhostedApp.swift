import SwiftUI

@main
struct GhostedApp: App {
    @StateObject private var store = GhostedStore()
    @StateObject private var purchases = PurchaseManager()
    @AppStorage("ghosted_haptics_enabled") private var hapticsEnabled: Bool = true

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .environmentObject(store)
                .environmentObject(purchases)
                .preferredColorScheme(.dark)
                .onAppear {
                    Haptics.enabled = hapticsEnabled
                }
        }
    }
}
