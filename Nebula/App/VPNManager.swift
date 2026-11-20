import Foundation
import Network
import NetworkExtension
import UIKit

enum TunnelState: Equatable {
    case disconnected, connecting, connected
}

final class VPNManager: ObservableObject {
    @Published var state: TunnelState = .disconnected
    @Published var nodes: [ProxyNode] = ProxyNode.defaults
    @Published var selectedNodeID: UUID? {
        didSet {
            if let id = selectedNodeID {
                UserDefaults.standard.set(id.uuidString, forKey: selectedKey)
            }
        }
    }
    @Published var pingingIDs: Set<UUID> = []

    private var manager: NETunnelProviderManager?
    private let storageKey = "nebula_nodes_v3"
    private let selectedKey = "nebula_selected_v3"

    init() {
        loadNodes()
        if let saved = UserDefaults.standard.string(forKey: selectedKey),
           let uuid = UUID(uuidString: saved),
           nodes.contains(where: { $0.id == uuid }) {
            selectedNodeID = uuid
        } else {
            selectedNodeID = nodes.first?.id
        }
        NETunnelProviderManager.loadAllFromPreferences { [weak self] managers, _ in
            DispatchQueue.main.async {
                self?.manager = managers?.first ?? NETunnelProviderManager()
            }
        }
    }

    var activeNode: ProxyNode? {
        nodes.first(where: { $0.id == selectedNodeID }) ?? nodes.first
    }

    func toggle() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        if state == .disconnected {
            state = .connecting
            if let manager, let node = activeNode {
                let proto = NETunnelProviderProtocol()
                proto.providerBundleIdentifier = "com.nebula.xray.tunnel"
                proto.serverAddress = "Nebula"
                proto.providerConfiguration = ["uri": node.rawURI]
                manager.protocolConfiguration = proto
                manager.isEnabled = true
                manager.saveToPreferences { _ in try? manager.connection.startVPNTunnel() }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.55) {
                self.state = .connected
                UINotificationFeedbackGenerator().notificationOccurred(.success)
            }
        } else {
            manager?.connection.stopVPNTunnel()
            state = .disconnected
        }
    }

    func importBulk(_ text: String) {
        let parsed = ProxyNode.parseBulk(text)
        guard !parsed.isEmpty else { return }
        nodes.insert(contentsOf: parsed, at: 0)
        selectedNodeID = nodes.first?.id
        saveNodes()
    }

    func deleteNode(_ node: ProxyNode) {
        nodes.removeAll { $0.id == node.id }
        if selectedNodeID == node.id {
            selectedNodeID = nodes.first?.id
        }
        saveNodes()
    }

    // Реальная проверка TCP-пинга по host:port из ссылки сервера
    func pingAll() {
        for node in nodes {
            pingNode(node)
        }
    }

    func pingNode(_ node: ProxyNode) {
        guard !pingingIDs.contains(node.id) else { return }
        pingingIDs.insert(node.id)

        let (host, port) = extractHostPort(from: node.rawURI)
        let start = Date()
        let connection = NWConnection(
            host: NWEndpoint.Host(host),
            port: NWEndpoint.Port(integerLiteral: port),
            using: .tcp
        )
        let queue = DispatchQueue(label: "nebula.ping.\(node.id.uuidString)")
        var finished = false

        let complete: (Int) -> Void = { [weak self] ms in
            guard !finished else { return }
            finished = true
            connection.cancel()
            DispatchQueue.main.async {
                self?.pingingIDs.remove(node.id)
                if let idx = self?.nodes.firstIndex(where: { $0.id == node.id }) {
                    self?.nodes[idx].pingMs = ms
                    self?.saveNodes()
                }
            }
        }

        connection.stateUpdateHandler = { state in
            switch state {
            case .ready:
                let ms = max(1, Int(Date().timeIntervalSince(start) * 1000))
                complete(ms)
            case .failed, .cancelled:
                complete(999)
            default:
                break
            }
        }
        connection.start(queue: queue)
        queue.asyncAfter(deadline: .now() + 2.5) { complete(999) }
    }

    private func extractHostPort(from uri: String) -> (String, UInt16) {
        if let url = URL(string: uri), let host = url.host, !host.isEmpty {
            let port = UInt16(url.port ?? (url.scheme == "http" ? 80 : 443))
            return (host, port)
        }
        return ("1.1.1.1", 443)
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
