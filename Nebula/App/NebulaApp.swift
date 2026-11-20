import SwiftUI

@main
struct NebulaApp: App {
    @StateObject private var store = Store()
    @StateObject private var vpn = VPNManager()
    var body: some Scene {
        WindowGroup {
            RootView().environmentObject(store).environmentObject(vpn)
        }
    }
}
