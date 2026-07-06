import SwiftUI

struct RootTabView: View {
    var body: some View {
        TabView {
            GhostedHomeView()
                .tabItem {
                    Label("Tracked", systemImage: "figure.stand")
                }

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
        }
        .tint(GHTheme.violet)
        .onAppear {
            let appearance = UITabBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = UIColor(GHTheme.surface)
            UITabBar.appearance().standardAppearance = appearance
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
    }
}

#Preview {
    RootTabView()
        .environmentObject(GhostedStore())
        .environmentObject(PurchaseManager())
}
