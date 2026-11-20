import SwiftUI

@main
struct NebulaApp: App {
    @AppStorage("nebula_has_onboarded") private var hasOnboarded = false
    @StateObject private var theme = ThemeManager()
    @StateObject private var vpn = VPNManager()

    var body: some Scene {
        WindowGroup {
            RootView(hasOnboarded: $hasOnboarded)
                .environmentObject(theme)
                .environmentObject(vpn)
                .preferredColorScheme(.dark)
        }
    }
}
