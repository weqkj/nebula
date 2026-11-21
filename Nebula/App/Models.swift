import Foundation
import Network

struct Server: Identifiable, Codable, Hashable {
    var id = UUID()
    var sub: UUID? = nil
    var proto = "vless"        // vless | vmess | trojan | ss
    var name: String
    var address: String
    var port: Int
    var uuid: String           // id или пароль
    var method = ""            // ss
    var flow = ""
    var security = "none"      // none | tls | reality
    var network = "tcp"        // tcp | ws | grpc
    var sni = ""
    var fp = "chrome"
    var pbk = ""
    var sid = ""
    var path = ""
    var host = ""
    var ping: Int? = nil       // -1 = недоступен
}

struct Subscription: Identifiable, Codable, Hashable {
    var id = UUID()
    var name: String
    var url: String
    var updated: Date?
}

enum LinkParser {
    static func parse(_ raw: String) -> Server? {
        let t = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if t.hasPrefix("vless://") { return urlStyle(t, proto: "vless") }
        if t.hasPrefix("trojan://") { return urlStyle(t, proto: "trojan") }
        if t.hasPrefix("vmess://") { return vmess(t) }
        if t.hasPrefix("ss://") { return ss(t) }
        return nil
    }

    static func parseMany(_ text: String) -> [Server] {
        text.components(separatedBy: .newlines).compactMap { parse($0) }
    }

    static func b64(_ str: String) -> Data? {
        var s = str.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "-", with: "+").replacingOccurrences(of: "_", with: "/")
        while s.count % 4 != 0 { s += "=" }
        return Data(base64Encoded: s)
    }

    private static func urlStyle(_ t: String, proto: String) -> Server? {
        let parts = t.split(separator: "#", maxSplits: 1, omittingEmptySubsequences: false)
        let name = parts.count > 1 ? (String(parts[1]).removingPercentEncoding ?? String(parts[1])) : nil
        guard let c = URLComponents(string: String(parts[0])), let user = c.user, let host = c.host else { return nil }
        var q: [String: String] = [:]
        for i in c.queryItems ?? [] { q[i.name] = i.value ?? "" }
        var s = Server(name: name ?? host, address: host, port: c.port ?? 443, uuid: user.removingPercentEncoding ?? user)
        s.proto = proto
        s.flow = q["flow"] ?? ""
        s.security = q["security"] ?? (proto == "trojan" ? "tls" : "none")
        s.network = q["type"] ?? "tcp"
        s.sni = q["sni"] ?? q["peer"] ?? ""
        s.fp = q["fp"] ?? "chrome"
        s.pbk = q["pbk"] ?? ""
        s.sid = q["sid"] ?? ""
        s.path = q["path"] ?? q["serviceName"] ?? ""
        s.host = q["host"] ?? ""
        return s
    }

    private static func vmess(_ t: String) -> Server? {
        guard let data = b64(String(t.dropFirst(8))),
              let j = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return nil }
        func str(_ k: String) -> String {
            if let s = j[k] as? String { return s }
            if let n = j[k] as? NSNumber { return n.stringValue }
            return ""
        }
        guard let port = Int(str("port")), !str("add").isEmpty else { return nil }
        var s = Server(name: str("ps").isEmpty ? str("add") : str("ps"), address: str("add"), port: port, uuid: str("id"))
        s.proto = "vmess"
        s.network = str("net").isEmpty ? "tcp" : str("net")
        s.host = str("host"); s.path = str("path"); s.sni = str("sni")
        s.security = str("tls") == "tls" ? "tls" : "none"
        s.fp = str("fp").isEmpty ? "chrome" : str("fp")
        return s
    }

    private static func ss(_ t: String) -> Server? {
        let body = String(t.dropFirst(5))
        let parts = body.split(separator: "#", maxSplits: 1, omittingEmptySubsequences: false)
        let name = parts.count > 1 ? (String(parts[1]).removingPercentEncoding ?? String(parts[1])) : nil
        var main = String(parts[0])
        if let qi = main.firstIndex(of: "?") { main = String(main[..<qi]) }
        var userinfo = "", hostport = ""
        if let at = main.lastIndex(of: "@") {
            userinfo = String(main[..<at]); hostport = String(main[main.index(after: at)...])
            if let d = b64(userinfo), let s = String(data: d, encoding: .utf8), s.contains(":") { userinfo = s }
            else { userinfo = userinfo.removingPercentEncoding ?? userinfo }
        } else {
            guard let d = b64(main), let s = String(data: d, encoding: .utf8), let at = s.lastIndex(of: "@") else { return nil }
            userinfo = String(s[..<at]); hostport = String(s[s.index(after: at)...])
        }
        let up = userinfo.split(separator: ":", maxSplits: 1).map(String.init)
        guard up.count == 2, let colon = hostport.lastIndex(of: ":"),
              let port = Int(hostport[hostport.index(after: colon)...]) else { return nil }
        let host = String(hostport[..<colon])
        var s = Server(name: name ?? host, address: host, port: port, uuid: up[1])
        s.proto = "ss"; s.method = up[0]
        return s
    }

    static func fetch(_ url: String) async throws -> [Server] {
        guard let u = URL(string: url) else { throw URLError(.badURL) }
        var req = URLRequest(url: u)
        req.setValue("Nebula/2.0", forHTTPHeaderField: "User-Agent")
        req.timeoutInterval = 15
        let (data, _) = try await URLSession.shared.data(for: req)
        var text = String(data: data, encoding: .utf8) ?? ""
        if !text.contains("://"), let d = b64(text), let s = String(data: d, encoding: .utf8) { text = s }
        return parseMany(text)
    }
}

enum Ping {
    static func tcp(_ host: String, _ port: Int) async -> Int? {
        await withCheckedContinuation { (cont: CheckedContinuation<Int?, Never>) in
            let p = NWEndpoint.Port(rawValue: UInt16(clamping: port)) ?? 443
            let conn = NWConnection(host: NWEndpoint.Host(host), port: p, using: .tcp)
            let q = DispatchQueue(label: "nebula.ping")
            let start = Date()
            var done = false
            func finish(_ v: Int?) {
                if done { return }
                done = true; conn.cancel(); cont.resume(returning: v)
            }
            conn.stateUpdateHandler = { st in
                switch st {
                case .ready: finish(Int(Date().timeIntervalSince(start) * 1000))
                case .failed, .cancelled: finish(nil)
                default: break
                }
            }
            conn.start(queue: q)
            q.asyncAfter(deadline: .now() + 3) { finish(nil) }
        }
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
        var settings: [String: Any]
        var proto = s.proto
        switch s.proto {
        case "vmess":
            settings = ["vnext": [["address": s.address, "port": s.port,
                                   "users": [["id": s.uuid, "alterId": 0, "security": "auto"]]]]]
        case "trojan":
            settings = ["servers": [["address": s.address, "port": s.port, "password": s.uuid]]]
        case "ss":
            proto = "shadowsocks"
            settings = ["servers": [["address": s.address, "port": s.port, "method": s.method, "password": s.uuid]]]
        default:
            var user: [String: Any] = ["id": s.uuid, "encryption": "none"]
            if !s.flow.isEmpty { user["flow"] = s.flow }
            settings = ["vnext": [["address": s.address, "port": s.port, "users": [user]]]]
        }
        let cfg: [String: Any] = [
            "log": ["loglevel": "warning"],
            "inbounds": [["tag": "socks", "port": 10808, "listen": "127.0.0.1", "protocol": "socks",
                          "settings": ["udp": true],
                          "sniffing": ["enabled": true, "destOverride": ["http", "tls", "quic"]]]],
            "outbounds": [
                ["tag": "proxy", "protocol": proto, "settings": settings, "streamSettings": stream],
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
    @Published var subs: [Subscription] { didSet { save() } }
    @Published var selected: UUID? { didSet { UserDefaults.standard.set(selected?.uuidString, forKey: "sel") } }

    init() {
        let d = UserDefaults.standard
        servers = (d.data(forKey: "servers2").flatMap { try? JSONDecoder().decode([Server].self, from: $0) }) ?? []
        subs = (d.data(forKey: "subs2").flatMap { try? JSONDecoder().decode([Subscription].self, from: $0) }) ?? []
        selected = d.string(forKey: "sel").flatMap(UUID.init)
    }
    var current: Server? { servers.first { $0.id == selected } ?? servers.first }

    private func save() {
        UserDefaults.standard.set(try? JSONEncoder().encode(servers), forKey: "servers2")
        UserDefaults.standard.set(try? JSONEncoder().encode(subs), forKey: "subs2")
    }

    func servers(in sub: UUID?) -> [Server] { servers.filter { $0.sub == sub } }

    @discardableResult func addLinks(_ text: String) -> Int {
        let list = LinkParser.parseMany(text)
        servers.append(contentsOf: list)
        if selected == nil { selected = list.first?.id }
        return list.count
    }

    func addSubscription(name: String, url: String) async throws -> Int {
        let list = try await LinkParser.fetch(url)
        let sub = Subscription(name: name, url: url, updated: Date())
        subs.append(sub)
        var items = list
        for i in items.indices { items[i].sub = sub.id }
        servers.append(contentsOf: items)
        if selected == nil { selected = items.first?.id }
        return items.count
    }

    func refresh(_ sub: Subscription) async {
        guard let list = try? await LinkParser.fetch(sub.url) else { return }
        var items = list
        for i in items.indices { items[i].sub = sub.id }
        servers.removeAll { $0.sub == sub.id }
        servers.append(contentsOf: items)
        if let i = subs.firstIndex(where: { $0.id == sub.id }) { subs[i].updated = Date() }
    }

    func remove(_ s: Server) { servers.removeAll { $0.id == s.id } }
    func remove(_ sub: Subscription) {
        servers.removeAll { $0.sub == sub.id }
        subs.removeAll { $0.id == sub.id }
    }

    func pingAll() async {
        let list = servers
        await withTaskGroup(of: (UUID, Int?).self) { g in
            for s in list { g.addTask { (s.id, await Ping.tcp(s.address, s.port)) } }
            for await (id, p) in g {
                if let i = servers.firstIndex(where: { $0.id == id }) { servers[i].ping = p ?? -1 }
            }
        }
    }
}
