import Foundation

struct Server: Identifiable, Codable, Hashable {
    var id = UUID()
    var name: String
    var address: String
    var port: Int
    var uuid: String
    var flow = ""
    var security = "none"   // none | tls | reality
    var network = "tcp"     // tcp | ws | grpc
    var sni = ""
    var fp = "chrome"
    var pbk = ""
    var sid = ""
    var path = ""
    var host = ""
    var ping: Int? = nil
}

enum VlessParser {
    /// vless://UUID@host:port?type=tcp&security=reality&sni=..&pbk=..&sid=..&fp=chrome&flow=xtls-rprx-vision#Name
    static func parse(_ link: String) -> Server? {
        let t = link.trimmingCharacters(in: .whitespacesAndNewlines)
        guard t.hasPrefix("vless://") else { return nil }
        let parts = t.split(separator: "#", maxSplits: 1, omittingEmptySubsequences: false)
        let name = parts.count > 1 ? (String(parts[1]).removingPercentEncoding ?? String(parts[1])) : nil
        guard let c = URLComponents(string: String(parts[0])),
              let uuid = c.user, let host = c.host else { return nil }
        var q: [String: String] = [:]
        for i in c.queryItems ?? [] { q[i.name] = i.value ?? "" }
        return Server(name: name ?? host, address: host, port: c.port ?? 443, uuid: uuid,
                      flow: q["flow"] ?? "", security: q["security"] ?? "none",
                      network: q["type"] ?? "tcp", sni: q["sni"] ?? "", fp: q["fp"] ?? "chrome",
                      pbk: q["pbk"] ?? "", sid: q["sid"] ?? "",
                      path: q["path"] ?? "", host: q["host"] ?? "")
    }
}

enum XrayConfig {
    static func json(for s: Server) -> String {
        var stream: [String: Any] = ["network": s.network, "security": s.security]
        switch s.security {
        case "reality":
            stream["realitySettings"] = ["serverName": s.sni, "fingerprint": s.fp,
                                         "publicKey": s.pbk, "shortId": s.sid, "spiderX": "/"]
        case "tls":
            stream["tlsSettings"] = ["serverName": s.sni.isEmpty ? s.address : s.sni, "fingerprint": s.fp]
        default: break
        }
        if s.network == "ws" {
            stream["wsSettings"] = ["path": s.path.isEmpty ? "/" : s.path, "headers": ["Host": s.host]]
        } else if s.network == "grpc" {
            stream["grpcSettings"] = ["serviceName": s.path]
        }
        var user: [String: Any] = ["id": s.uuid, "encryption": "none"]
        if !s.flow.isEmpty { user["flow"] = s.flow }
        let cfg: [String: Any] = [
            "log": ["loglevel": "warning"],
            "inbounds": [["tag": "socks", "port": 10808, "listen": "127.0.0.1", "protocol": "socks",
                          "settings": ["udp": true],
                          "sniffing": ["enabled": true, "destOverride": ["http", "tls", "quic"]]]],
            "outbounds": [
                ["tag": "proxy", "protocol": "vless",
                 "settings": ["vnext": [["address": s.address, "port": s.port, "users": [user]]]],
                 "streamSettings": stream],
                ["tag": "direct", "protocol": "freedom"]
            ],
            "routing": ["domainStrategy": "IPIfNonMatch",
                        "rules": [["type": "field", "ip": ["geoip:private"], "outboundTag": "direct"]]]
        ]
        let d = try? JSONSerialization.data(withJSONObject: cfg, options: [.prettyPrinted, .sortedKeys])
        return d.flatMap { String(data: $0, encoding: .utf8) } ?? "{}"
    }
}

@MainActor
final class Store: ObservableObject {
    @Published var servers: [Server] { didSet { save() } }
    @Published var selected: UUID? { didSet { UserDefaults.standard.set(selected?.uuidString, forKey: "sel") } }

    init() {
        if let d = UserDefaults.standard.data(forKey: "servers"),
           let s = try? JSONDecoder().decode([Server].self, from: d) { servers = s } else { servers = [] }
        selected = UserDefaults.standard.string(forKey: "sel").flatMap(UUID.init)
    }
    var current: Server? { servers.first { $0.id == selected } ?? servers.first }
    private func save() {
        UserDefaults.standard.set(try? JSONEncoder().encode(servers), forKey: "servers")
    }
    @discardableResult func add(link: String) -> Bool {
        guard let s = VlessParser.parse(link) else { return false }
        servers.append(s); if selected == nil { selected = s.id }; return true
    }
    func remove(_ s: Server) { servers.removeAll { $0.id == s.id } }
}
