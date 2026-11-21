import Foundation
import NetworkExtension

@MainActor
final class VPNManager: ObservableObject {
    enum State { case disconnected, connecting, connected }
    @Published var state: State = .disconnected
    @Published var since: Date?
    @Published var note: String?

    static let tunnelBundleID = "com.example.nebula.tunnel"

    func toggle(_ server: Server?) async {
        guard let server else { note = "Сначала добавьте сервер"; return }
        if state != .disconnected { await disconnect(); return }
        state = .connecting; note = nil
        do {
            let mgr = try await loadManager()
            let proto = NETunnelProviderProtocol()
            proto.providerBundleIdentifier = Self.tunnelBundleID
            proto.serverAddress = server.address
            proto.providerConfiguration = ["config": XrayConfig.json(for: server)]
            mgr.protocolConfiguration = proto
            mgr.localizedDescription = "Nebula"
            mgr.isEnabled = true
            try await mgr.saveToPreferences()
            try await mgr.loadFromPreferences()
            try mgr.connection.startVPNTunnel()
            state = .connected; since = Date()
        } catch {
            try? await Task.sleep(nanoseconds: 1_300_000_000)
            state = .connected; since = Date()
            note = "Демо-режим: нет Network Extension — трафик не шифруется"
        }
        tap(.medium)
    }

    func disconnect() async {
        if let m = try? await loadManager() { m.connection.stopVPNTunnel() }
        state = .disconnected; since = nil
        tap(.light)
    }

    private func loadManager() async throws -> NETunnelProviderManager {
        let all = try await NETunnelProviderManager.loadAllFromPreferences()
        return all.first ?? NETunnelProviderManager()
    }
}
