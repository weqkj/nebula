import SwiftUI

@main
struct NebulaApp: App {
    @AppStorage("nebula_onboarded") private var onboarded = false
    @StateObject private var theme = ThemeManager()
    @StateObject private var vpn = VPNManager()

    var body: some Scene {
        WindowGroup {
            RootView(onboarded: $onboarded)
                .environmentObject(theme)
                .environmentObject(vpn)
                .preferredColorScheme(theme.isLight ? .light : .dark)
        }
    }
}
