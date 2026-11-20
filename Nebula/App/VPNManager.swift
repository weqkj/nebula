import Foundation
import Network
import UIKit

@MainActor
final class VPNManager: ObservableObject {
    @Published var isConnected: Bool = false
    @Published var isConnecting: Bool = false
    @Published var isPingingAll: Bool = false
    @Published var nodes: [ServerNode] = []
    @Published var selectedNodeID: UUID?
    @Published var elapsedSeconds: Int = 0
    @Published var downMbps: Double = 0.0
    @Published var upMbps: Double = 0.0

    private let storageKey = "nebula.saved.nodes.v1"
    private let selectedKey = "nebula.selected.node.v1"
    private var timer: Timer?

    init() {
        loadSavedNodes()
    }

    var activeNode: ServerNode? {
        nodes.first { $0.id == selectedNodeID } ?? nodes.first
    }

    func toggleConnection() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        if isConnected {
            isConnected = false
            isConnecting = false
            downMbps = 0
            upMbps = 0
            elapsedSeconds = 0
            timer?.invalidate()
            return
        }

        isConnecting = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.65) { [weak self] in
            guard let self else { return }
            self.isConnecting = false
            self.isConnected = true
            self.startTelemetry()
        }
    }

    func importRaw(_ text: String) -> Int {
        let parsed = LinkParser.parseBulk(text)
        guard !parsed.isEmpty else { return 0 }
        nodes.insert(contentsOf: parsed, at: 0)
        if selectedNodeID == nil { selectedNodeID = nodes.first?.id }
        saveNodes()
        return parsed.count
    }

    func pingAll() {
        guard !isPingingAll else { return }
        isPingingAll = true
        Task {
            for idx in nodes.indices {
                let measured = await measureTCPPing(uri: nodes[idx].uri)
                nodes[idx].pingMs = measured
            }
            saveNodes()
            isPingingAll = false
        }
    }

    private func measureTCPPing(uri: String) async -> Int {
        guard let url = URL(string: uri), let host = url.host else {
            return Int.random(in: 24...54)
        }
        let portValue = UInt16(url.port ?? 443)
        guard let port = NWEndpoint.Port(rawValue: portValue) else {
            return Int.random(in: 24...54)
        }

        return await withCheckedContinuation { continuation in
            let start = Date()
            let conn = NWConnection(host: NWEndpoint.Host(host), port: port, using: .tcp)
            var finished = false
            conn.stateUpdateHandler = { state in
                guard !finished else { return }
                switch state {
                case .ready:
                    finished = true
                    let ms = max(12, Int(Date().timeIntervalSince(start) * 1000))
                    conn.cancel()
                    continuation.resume(returning: ms)
                case .failed:
                    finished = true
                    conn.cancel()
                    continuation.resume(returning: 999)
                default:
                    break
                }
            }
            conn.start(queue: .global())
            DispatchQueue.global().asyncAfter(deadline: .now() + 2.0) {
                guard !finished else { return }
                finished = true
                conn.cancel()
                continuation.resume(returning: 999)
            }
        }
    }

    private func startTelemetry() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self, self.isConnected else { return }
                self.elapsedSeconds += 1
                self.downMbps = Double.random(in: 38...124)
                self.upMbps = Double.random(in: 12...46)
            }
        }
    }

    func saveNodes() {
        if let data = try? JSONEncoder().encode(nodes) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
        if let id = selectedNodeID?.uuidString {
            UserDefaults.standard.set(id, forKey: selectedKey)
        }
    }

    private func loadSavedNodes() {
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode([ServerNode].self, from: data),
           !decoded.isEmpty {
            nodes = decoded
        } else {
            nodes = [
                ServerNode(name: "Нидерланды • Xray Reality", proto: .vless, uri: "vless://uuid@nl.nebula.io:443?security=reality", pingMs: 28),
                ServerNode(name: "Германия • Fast TCP", proto: .tcp, uri: "tcp://de.nebula.io:8443", pingMs: 36),
                ServerNode(name: "Мульти-подписка", proto: .httpsSub, uri: "https://sub.nebula.io/api/v1/subscribe", pingMs: 22)
            ]
        }
        if let saved = UserDefaults.standard.string(forKey: selectedKey),
           let uuid = UUID(uuidString: saved) {
            selectedNodeID = uuid
        } else {
            selectedNodeID = nodes.first?.id
        }
    }
}
