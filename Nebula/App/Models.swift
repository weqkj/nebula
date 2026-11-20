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
        let lines = input
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        return lines.enumerated().map { idx, line in
            let proto = TunnelProtocol.detect(from: line)
            let name = extractRemark(from: line) ?? (proto == .httpsSub ? "Подписка #\(idx + 1)" : "Узел #\(idx + 1)")
            return ProxyNode(name: name, proto: proto, rawURI: line, pingMs: Int.random(in: 20...64))
        }
    }

    private static func extractRemark(from uri: String) -> String? {
        if let hashIdx = uri.firstIndex(of: "#") {
            let next = uri.index(after: hashIdx)
            let raw = String(uri[next...])
            return raw.removingPercentEncoding?.isEmpty == false ? raw.removingPercentEncoding : nil
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
