import Foundation

enum TunnelProtocol: String, Codable, CaseIterable {
    case vless = "VLESS"
    case tcp = "TCP"
    case trojan = "TROJAN"
    case vmess = "VMESS"
    case httpsSub = "HTTPS"
    case xray = "XRAY"

    static func detect(from link: String) -> TunnelProtocol {
        let lower = link.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if lower.hasPrefix("https://") || lower.hasPrefix("http://") { return .httpsSub }
        if lower.contains("type=tcp") || lower.hasPrefix("tcp://") { return .tcp }
        if lower.hasPrefix("vless://") { return .vless }
        if lower.hasPrefix("trojan://") { return .trojan }
        if lower.hasPrefix("vmess://") { return .vmess }
        return .xray
    }
}

struct ProxyNode: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var name: String
    var proto: TunnelProtocol
    var rawURI: String
    var pingMs: Int

    static func parseBulk(_ input: String) -> [ProxyNode] {
        input
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .enumerated()
            .map { idx, line in
                let proto = TunnelProtocol.detect(from: line)
                let title = extractRemark(from: line) ?? (proto == .httpsSub ? "Подписка #\(idx + 1)" : "Маршрут #\(idx + 1)")
                return ProxyNode(name: title, proto: proto, rawURI: line, pingMs: Int.random(in: 18...60))
            }
    }

    private static func extractRemark(from uri: String) -> String? {
        if let hash = uri.firstIndex(of: "#") {
            let raw = String(uri[uri.index(after: hash)...])
            if let decoded = raw.removingPercentEncoding, !decoded.isEmpty { return decoded }
        }
        if let url = URL(string: uri), let host = url.host, uri.hasPrefix("http") {
            return "Подписка • \(host)"
        }
        return nil
    }

    static let defaults: [ProxyNode] = [
        ProxyNode(name: "Нидерланды • Xray Reality", proto: .vless, rawURI: "vless://uuid@nl.nebula.io:443?security=reality", pingMs: 28),
        ProxyNode(name: "Германия • Fast TCP", proto: .tcp, rawURI: "vless://uuid@de.nebula.io:8443?type=tcp", pingMs: 36),
        ProxyNode(name: "Основная подписка", proto: .httpsSub, rawURI: "https://sub.nebula.io/api/v1/subscribe?token=demo", pingMs: 24)
    ]
}
