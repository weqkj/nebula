import Foundation
import NetworkExtension

enum TunnelState: Equatable {
    case disconnected
    case connecting
    case connected
}

final class VPNManager: ObservableObject {
    @Published var state: TunnelState = .disconnected
    @Published var nodes: [ProxyNode] = ProxyNode.defaults
    @Published var selectedNodeID: UUID?
    @Published var connectedSince: Date? = nil

    private var manager: NETunnelProviderManager?
    private let storageKey = "nebula_saved_nodes_v1"

    init() {
        loadNodes()
        selectedNodeID = nodes.first?.id
        loadTunnelConfiguration()
    }

    var activeNode: ProxyNode? {
        nodes.first(where: { $0.id == selectedNodeID }) ?? nodes.first
    }

    func toggle() {
        switch state {
        case .disconnected:
            connect()
        case .connecting, .connected:
            disconnect()
        }
    }

    private func connect() {
        guard let node = activeNode else { return }
        state = .connecting

        if let manager {
            let proto = NETunnelProviderProtocol()
            proto.providerBundleIdentifier = "com.nebula.xray.tunnel"
            proto.serverAddress = "Nebula Xray"
            proto.providerConfiguration = ["uri": node.rawURI]
            manager.protocolConfiguration = proto
            manager.isEnabled = true
            manager.saveToPreferences { [weak self] _ in
                try? manager.connection.startVPNTunnel()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.55) {
                    self?.state = .connected
                    self?.connectedSince = Date()
                }
            }
        } else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.55) {
                self.state = .connected
                self.connectedSince = Date()
            }
        }
    }

    private func disconnect() {
        manager?.connection.stopVPNTunnel()
        state = .disconnected
        connectedSince = nil
    }

    func importBulk(_ text: String) {
        let parsed = ProxyNode.parseBulk(text)
        guard !parsed.isEmpty else { return }
        nodes.insert(contentsOf: parsed, at: 0)
        selectedNodeID = nodes.first?.id
        saveNodes()
    }

    func removeNode(_ id: UUID) {
        nodes.removeAll { $0.id == id }
        if selectedNodeID == id { selectedNodeID = nodes.first?.id }
        saveNodes()
    }

    private func loadTunnelConfiguration() {
        NETunnelProviderManager.loadAllFromPreferences { [weak self] managers, _ in
            DispatchQueue.main.async {
                self?.manager = managers?.first ?? NETunnelProviderManager()
            }
        }
    }

    private func saveNodes() {
        if let data = try? JSONEncoder().encode(nodes) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }

    private func loadNodes() {
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode([ProxyNode].self, from: data),
           !decoded.isEmpty {
            nodes = decoded
        }
    }
}
