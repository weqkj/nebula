import SwiftUI

enum Tab: String, CaseIterable {
    case home = "Главная", servers = "Серверы", about = "Ещё"
    var icon: String { switch self { case .home: "shield.lefthalf.filled"; case .servers: "globe"; case .about: "gearshape" } }
}

struct RootView: View {
    @State private var tab: Tab = .home
    var body: some View {
        ZStack(alignment: .bottom) {
            M3.surface.ignoresSafeArea()
            Group {
                switch tab {
                case .home: HomeView()
                case .servers: ServersView()
                case .about: AboutView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.bottom, 84)
            NavBar(tab: $tab)
        }
    }
}

struct NavBar: View {
    @Binding var tab: Tab
    var body: some View {
        HStack {
            ForEach(Tab.allCases, id: \.self) { t in
                Button { withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) { tab = t } } label: {
                    VStack(spacing: 4) {
                        Image(systemName: t.icon).font(.system(size: 20))
                            .frame(width: 64, height: 32)
                            .background(tab == t ? M3.secondaryContainer : .clear, in: Capsule())
                            .foregroundStyle(tab == t ? M3.onSecondaryContainer : M3.onSurfaceVariant)
                        Text(t.rawValue).font(.system(size: 12, weight: tab == t ? .bold : .medium))
                            .foregroundStyle(tab == t ? M3.onSurface : M3.onSurfaceVariant)
                    }.frame(maxWidth: .infinity)
                }.buttonStyle(.plain)
            }
        }
        .padding(.top, 12).padding(.bottom, 16)
        .background(M3.surfaceContainer.ignoresSafeArea(edges: .bottom))
    }
}

// MARK: Home
struct HomeView: View {
    @EnvironmentObject var store: Store
    @EnvironmentObject var vpn: VPNManager
    @State private var pulse = false

    private var title: String {
        switch vpn.state { case .disconnected: "Не защищено"; case .connecting: "Подключение…"; case .connected: "Защищено" }
    }
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                HStack {
                    Text("Nebula").font(.system(size: 32, weight: .bold)).foregroundStyle(M3.onSurface)
                    Spacer()
                    Image(systemName: "sparkles").font(.title2).foregroundStyle(M3.primary)
                }.padding(.top, 8)

                M3Card(color: vpn.state == .connected ? M3.primaryContainer : M3.surfaceContainerHigh, radius: 40) {
                    VStack(spacing: 22) {
                        ZStack {
                            Circle().fill(M3.primary.opacity(0.15)).frame(width: 220, height: 220)
                                .scaleEffect(pulse ? 1.08 : 0.92)
                            Circle().fill(M3.primary.opacity(0.25)).frame(width: 180, height: 180)
                                .scaleEffect(pulse ? 0.95 : 1.05)
                            Button { Task { await vpn.toggle(store.current) } } label: {
                                Image(systemName: "power").font(.system(size: 48, weight: .semibold))
                                    .foregroundStyle(M3.onPrimary)
                                    .frame(width: 140, height: 140)
                                    .background(M3.primary, in: RoundedRectangle(
                                        cornerRadius: vpn.state == .connected ? 70 : 44, style: .continuous))
                            }.buttonStyle(.plain)
                        }
                        .animation(vpn.state == .connecting ? .easeInOut(duration: 1).repeatForever() : .default, value: pulse)
                        .animation(.spring(response: 0.5, dampingFraction: 0.65), value: vpn.state == .connected)
                        VStack(spacing: 4) {
                            Text(title).font(.system(size: 24, weight: .bold))
                                .foregroundStyle(vpn.state == .connected ? M3.onPrimaryContainer : M3.onSurface)
                            if let s = vpn.since {
                                TimelineView(.periodic(from: s, by: 1)) { ctx in
                                    let t = Int(ctx.date.timeIntervalSince(s))
                                    Text(String(format: "%02d:%02d:%02d", t / 3600, t / 60 % 60, t % 60))
                                        .font(.system(size: 18, weight: .medium, design: .monospaced))
                                        .foregroundStyle(M3.onPrimaryContainer)
                                }
                            } else {
                                Text("Нажмите, чтобы подключиться").font(.subheadline).foregroundStyle(M3.onSurfaceVariant)
                            }
                        }
                    }.frame(maxWidth: .infinity)
                }
                .onAppear { pulse = true }

                M3Card(color: M3.surfaceContainer) {
                    HStack(spacing: 14) {
                        Image(systemName: "paperplane.fill").font(.title3).foregroundStyle(M3.onTertiaryContainer)
                            .frame(width: 48, height: 48)
                            .background(M3.tertiaryContainer, in: Circle())
                        VStack(alignment: .leading, spacing: 2) {
                            Text(store.current?.name ?? "Сервер не выбран").font(.headline).foregroundStyle(M3.onSurface)
                            Text(store.current.map { "VLESS · \($0.security.uppercased()) · \($0.address)" } ?? "Добавьте ссылку vless:// во вкладке «Серверы»")
                                .font(.caption).foregroundStyle(M3.onSurfaceVariant).lineLimit(1)
                        }
                    }
                }
                if let n = vpn.note {
                    Text(n).font(.caption).foregroundStyle(M3.onSurfaceVariant).padding(.horizontal, 8)
                }
            }.padding(20)
        }
    }
}

// MARK: Servers
struct ServersView: View {
    @EnvironmentObject var store: Store
    @State private var link = ""
    @State private var bad = false
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Серверы").font(.system(size: 32, weight: .bold)).foregroundStyle(M3.onSurface)
                M3Card(color: M3.surfaceContainerHigh) {
                    VStack(alignment: .leading, spacing: 12) {
                        TextField("vless://…", text: $link, axis: .vertical).lineLimit(1...4)
                            .textInputAutocapitalization(.never).autocorrectionDisabled()
                            .padding(14)
                            .background(M3.surface, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                            .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .stroke(bad ? M3.error : M3.outline, lineWidth: 1))
                        HStack {
                            Button("Из буфера") { link = UIPasteboard.general.string ?? "" }
                                .buttonStyle(TonalButtonStyle())
                            Button("Добавить") {
                                if store.add(link: link) { link = ""; bad = false } else { bad = true }
                            }.buttonStyle(TonalButtonStyle(filled: true))
                        }
                    }
                }
                ForEach(store.servers) { s in
                    Button { store.selected = s.id } label: {
                        M3Card(color: store.current?.id == s.id ? M3.primaryContainer : M3.surfaceContainer) {
                            HStack {
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(s.name).font(.headline).foregroundStyle(M3.onSurface)
                                    Text("\(s.address):\(s.port) · \(s.network) · \(s.security)")
                                        .font(.caption).foregroundStyle(M3.onSurfaceVariant)
                                }
                                Spacer()
                                if store.current?.id == s.id {
                                    Image(systemName: "checkmark.circle.fill").foregroundStyle(M3.primary)
                                }
                                Button { store.remove(s) } label: { Image(systemName: "trash") }
                                    .foregroundStyle(M3.onSurfaceVariant)
                            }
                        }
                    }.buttonStyle(.plain)
                }
            }.padding(20)
        }
    }
}

// MARK: About
struct AboutView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Ещё").font(.system(size: 32, weight: .bold)).foregroundStyle(M3.onSurface)
                M3Card(color: M3.secondaryContainer) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Nebula 1.0").font(.headline).foregroundStyle(M3.onSecondaryContainer)
                        Text("Клиент Xray (VLESS · Reality · TLS · WS · gRPC). Дизайн в духе Material You 3.")
                            .font(.subheadline).foregroundStyle(M3.onSecondaryContainer)
                    }
                }
            }.padding(20)
        }
    }
}
