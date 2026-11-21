// Network Extension (Packet Tunnel). НЕ подключён в project.yml по умолчанию —
// нужен платный Apple Developer аккаунт (entitlement packet-tunnel-provider)
// и libXray.xcframework (https://github.com/XTLS/libXray, сборка через gomobile).
import NetworkExtension

class PacketTunnelProvider: NEPacketTunnelProvider {
    override func startTunnel(options: [String: NSObject]?, completionHandler: @escaping (Error?) -> Void) {
        let cfg = (protocolConfiguration as? NETunnelProviderProtocol)?.providerConfiguration?["config"] as? String ?? "{}"
        let settings = NEPacketTunnelNetworkSettings(tunnelRemoteAddress: "254.1.1.1")
        settings.mtu = 1500
        let v4 = NEIPv4Settings(addresses: ["198.18.0.1"], subnetMasks: ["255.255.0.0"])
        v4.includedRoutes = [NEIPv4Route.default()]
        settings.ipv4Settings = v4
        settings.dnsSettings = NEDNSSettings(servers: ["1.1.1.1", "8.8.8.8"])
        setTunnelNetworkSettings(settings) { err in
            if let err { return completionHandler(err) }
            // TODO: 1) LibXrayRunXray(cfg) -> SOCKS 127.0.0.1:10808
            //       2) прокинуть packetFlow в tun2socks (напр. Tun2SocksKit) -> 127.0.0.1:10808
            _ = cfg
            completionHandler(nil)
        }
    }
    override func stopTunnel(with reason: NEProviderStopReason, completionHandler: @escaping () -> Void) {
        // TODO: LibXrayStopXray()
        completionHandler()
    }
}
