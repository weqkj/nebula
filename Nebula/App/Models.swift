import Foundation

enum NodeProtocol: String, Codable, CaseIterable {
    case vless = "VLESS"
    case tcp = "TCP"
    case trojan = "TROJAN"
    case httpsSub = "HTTPS"
}

struct ServerNode: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var name: String
    var proto: NodeProtocol
    var uri: String
    var pingMs: Int
}

enum LinkParser {
    static func parseBulk(_ rawText: String) -> [ServerNode] {
        let lines = rawText.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        return lines.compactMap { line in
            let lower = line.lowercased()
            let proto: NodeProtocol
            if lower.hasPrefix("vless://") {
                proto = lower.contains("type=tcp") ? .tcp : .vless
            } else if lower.hasPrefix("tcp://") {
                proto = .tcp
            } else if lower.hasPrefix("trojan://") {
                proto = .trojan
            } else if lower.hasPrefix("https://") || lower.hasPrefix("http://") {
                proto = .httpsSub
            } else {
                return nil
            }

            let tag = line.components(separatedBy: "#").dropFirst().joined(separator: "#")
                .removingPercentEncoding?.trimmingCharacters(in: .whitespaces)
            let host = URL(string: line)?.host ?? "Узел"
            let title = (tag?.isEmpty == false) ? tag! : host

            return ServerNode(
                name: title,
                proto: proto,
                uri: line,
                pingMs: Int.random(in: 24...58)
            )
        }
    }
}
