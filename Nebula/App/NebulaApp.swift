import SwiftUI

@main
struct NebulaApp: App {
    @StateObject private var theme = ThemeEngine()
    @StateObject private var manager = VPNManager()

    var body: some Scene {
        WindowGroup {
            RootContainerView()
                .environmentObject(theme)
                .environmentObject(manager)
        }
    }
}
