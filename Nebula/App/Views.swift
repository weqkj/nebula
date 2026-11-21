import SwiftUI
import PhotosUI

func fnt(_ s: CGFloat, _ w: Font.Weight = .heavy) -> Font { .system(size: s, weight: w, design: .rounded) }

enum Tab: String, CaseIterable {
    case home = "Главная", servers = "Серверы", style = "Стиль"
    var icon: String {
        switch self {
        case .home: return "shield.lefthalf.filled"
        case .servers: return "globe"
        case .style: return "paintpalette.fill"
        }
    }
}

struct RootView: View {
    @EnvironmentObject var t: Theme
    var body: some View {
        ZStack {
            AppBackground()
            if t.onboarded { MainView().transition(.opacity) }
            else { WelcomeView().transition(.opacity.combined(with: .scale(scale: 1.05))) }
        }
        .animation(.easeInOut(duration: 0.6), value: t.onboarded)
        .animation(.easeInOut(duration: 0.45), value: t.hue)
        .preferredColorScheme(t.scheme)
        .tint(t.primary)
    }
}

struct AppBackground: View {
    @EnvironmentObject var t: Theme
    @State private var go = false
    var body: some View {
        ZStack {
            t.surface
            if let w = t.wallpaper {
                Color.clear.overlay(Image(uiImage: w).resizable().scaledToFill()).clipped()
                Color.black.opacity(t.dim)
            } else {
                ZStack {
                    Circle().fill(t.primary.opacity(0.40)).frame(width: 380)
                        .offset(x: go ? -90 : 100, y: go ? -260 : -170)
                    Circle().fill(t.tertiaryContainer).frame(width: 340)
                        .offset(x: go ? 130 : -70, y: go ? 80 : 260)
                    Circle().fill(t.primaryContainer).frame(width: 300)
                        .offset(x: go ? -110 : 90, y: go ? 380 : 220)
                }.blur(radius: 70)
            }
        }
        .ignoresSafeArea()
        .onAppear { withAnimation(.easeInOut(duration: 9).repeatForever(autoreverses: true)) { go = true } }
    }
}

struct MainView: View {
    @State private var tab: Tab = .home
    @Namespace private var ns
    var body: some View {
        ZStack(alignment: .bottom) {
            Group {
                switch tab {
                case .home: HomeView()
                case .servers: ServersView()
                case .style: StyleView()
                }
            }
            .id(tab)
            .transition(.asymmetric(insertion: .opacity.combined(with: .offset(y: 16)), removal: .opacity))
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            NavBar(tab: $tab, ns: ns)
        }
        .animation(.easeInOut(duration: 0.3), value: tab)
    }
}

struct NavBar: View {
    @EnvironmentObject var t: Theme
    @Binding var tab: Tab
    var ns: Namespace.ID
    var body: some View {
        HStack(spacing: 4) {
            ForEach(Tab.allCases, id: \.self) { item in
                Button {
                    tap()
                    withAnimation(.spring(response: 0.45, dampingFraction: 0.75)) { tab = item }
                } label: {
                    VStack(spacing: 3) {
                        Image(systemName: item.icon).font(.system(size: 20, weight: .heavy))
                        Text(item.rawValue).font(fnt(11))
                    }
                    .foregroundStyle(tab == item ? t.onPrimaryContainer : t.onSurfaceVariant)
                    .frame(maxWidth: .infinity).frame(height: 56)
                    .background {
                        if tab == item {
                            Capsule().fill(t.primaryContainer).matchedGeometryEffect(id: "pill", in: ns)
                        }
                    }
                }.buttonStyle(.plain)
            }
        }
        .padding(8).glass(40).padding(.horizontal, 24).padding(.bottom, 8)
    }
}

// MARK: Home
struct HomeView: View {
    @EnvironmentObject var t: Theme
    @EnvironmentObject var store: Store
    @EnvironmentObject var vpn: VPNManager

    private var greeting: String {
        let h = Calendar.current.component(.hour, from: Date())
        switch h {
        case 5..<12: return "Доброе утро"
        case 12..<18: return "Добрый день"
        case 18..<23: return "Добрый вечер"
        default: return "Доброй ночи"
        }
    }
    private var title: String {
        switch vpn.state {
        case .disconnected: return "Отключено"
        case .connecting: return "Подключаюсь…"
        case .connected: return "Защищено"
        }
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 18) {
                header.reveal(0)
                connectCard.reveal(0.08)
                serverCard.reveal(0.16)
                HStack(spacing: 18) {
                    tile("Серверов", "\(store.servers.count)", "server.rack")
                    tile("Подписок", "\(store.subs.count)", "tray.full.fill")
                }.reveal(0.24)
                if let n = vpn.note {
                    Text(n).font(fnt(12, .semibold)).foregroundStyle(t.onSurfaceVariant)
                        .multilineTextAlignment(.center).padding(.horizontal, 12)
                }
            }
            .padding(.horizontal, 20).padding(.top, 12).padding(.bottom, 120)
        }
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(greeting).font(fnt(15, .bold)).foregroundStyle(t.onSurfaceVariant)
                Text(t.userName.isEmpty ? "Nebula" : t.userName)
                    .font(fnt(36)).foregroundStyle(t.onSurface)
            }
            Spacer()
            Text(String((t.userName.isEmpty ? "N" : t.userName).prefix(1)).uppercased())
                .font(fnt(22)).foregroundStyle(t.onTertiaryContainer)
                .frame(width: 52, height: 52).background(t.tertiaryContainer, in: Circle())
        }
    }

    private var connectCard: some View {
        VStack(spacing: 22) {
            ZStack {
                if vpn.state == .connected { ForEach(0..<3, id: \.self) { Ripple(delay: Double($0) * 0.9) } }
                if vpn.state == .connecting { Spinner() }
                Button { Task { await vpn.toggle(store.current) } } label: {
                    Image(systemName: "power").font(.system(size: 54, weight: .heavy))
                        .foregroundStyle(t.onPrimary)
                        .rotationEffect(.degrees(vpn.state == .connected ? 360 : 0))
                        .frame(width: 150, height: 150)
                        .background(t.primary, in: RoundedRectangle(
                            cornerRadius: vpn.state == .connected ? 75 : (vpn.state == .connecting ? 62 : 48),
                            style: .continuous))
                        .shadow(color: t.primary.opacity(0.45), radius: vpn.state == .connected ? 30 : 12, y: 10)
                }.buttonStyle(.plain)
            }
            .frame(height: 230)
            .animation(.spring(response: 0.7, dampingFraction: 0.6), value: vpn.state)

            VStack(spacing: 4) {
                Text(title).font(fnt(28)).foregroundStyle(t.onSurface)
                if let s = vpn.since {
                    TimelineView(.periodic(from: s, by: 1)) { ctx in
                        let n = Int(ctx.date.timeIntervalSince(s))
                        Text(String(format: "%02d:%02d:%02d", n / 3600, n / 60 % 60, n % 60))
                            .font(.system(size: 20, weight: .bold, design: .monospaced))
                            .foregroundStyle(t.primary)
                    }
                } else {
                    Text("Нажмите, чтобы подключиться").font(fnt(14, .semibold)).foregroundStyle(t.onSurfaceVariant)
                }
            }
        }
        .padding(.vertical, 26).frame(maxWidth: .infinity).glass(40)
    }

    private var serverCard: some View {
        HStack(spacing: 14) {
            Image(systemName: "bolt.horizontal.fill").font(.system(size: 22, weight: .heavy))
                .foregroundStyle(t.onTertiaryContainer)
                .frame(width: 52, height: 52).background(t.tertiaryContainer, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            VStack(alignment: .leading, spacing: 2) {
                Text(store.current?.name ?? "Сервер не выбран").font(fnt(17)).foregroundStyle(t.onSurface).lineLimit(1)
                Text(store.current.map { "\($0.proto.uppercased()) · \($0.network) · \($0.security)" } ?? "Добавьте во вкладке «Серверы»")
                    .font(fnt(12, .semibold)).foregroundStyle(t.onSurfaceVariant)
            }
            Spacer()
        }
        .padding(18).glass(30)
    }

    private func tile(_ label: String, _ value: String, _ icon: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Image(systemName: icon).font(.system(size: 18, weight: .heavy)).foregroundStyle(t.primary)
            Text(value).font(fnt(32)).foregroundStyle(t.onSurface).contentTransition(.numericText())
            Text(label).font(fnt(12, .semibold)).foregroundStyle(t.onSurfaceVariant)
        }
        .padding(18).frame(maxWidth: .infinity, alignment: .leading).glass(28)
    }
}

struct Ripple: View {
    @EnvironmentObject var t: Theme
    let delay: Double
    @State private var go = false
    var body: some View {
        Circle().stroke(t.primary.opacity(0.5), lineWidth: 3).frame(width: 150, height: 150)
            .scaleEffect(go ? 1.6 : 1).opacity(go ? 0 : 0.8)
            .onAppear { withAnimation(.easeOut(duration: 2.7).repeatForever(autoreverses: false).delay(delay)) { go = true } }
    }
}

struct Spinner: View {
    @EnvironmentObject var t: Theme
    @State private var go = false
    var body: some View {
        Circle().trim(from: 0, to: 0.28).stroke(t.primary, style: StrokeStyle(lineWidth: 8, lineCap: .round))
            .frame(width: 190, height: 190).rotationEffect(.degrees(go ? 360 : 0))
            .onAppear { withAnimation(.linear(duration: 1).repeatForever(autoreverses: false)) { go = true } }
    }
}

// MARK: Servers
struct ServersView: View {
    @EnvironmentObject var t: Theme
    @EnvironmentObject var store: Store
    @State private var showAdd = false
    @State private var pinging = false

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("Серверы").font(fnt(36)).foregroundStyle(t.onSurface)
                    Spacer()
                    Button { tap(); pinging = true; Task { await store.pingAll(); pinging = false } } label: {
                        Image(systemName: "speedometer").font(.system(size: 18, weight: .heavy))
                            .frame(width: 46, height: 46).glass(23)
                            .symbolRenderingMode(.hierarchical)
                            .opacity(pinging ? 0.4 : 1)
                    }.buttonStyle(.plain).foregroundStyle(t.onSurface)
                    Button { tap(); showAdd = true } label: {
                        Image(systemName: "plus").font(.system(size: 20, weight: .heavy)).foregroundStyle(t.onPrimary)
                            .frame(width: 46, height: 46).background(t.primary, in: Circle())
                    }.buttonStyle(.plain)
                }.reveal(0)

                if store.servers.isEmpty {
                    VStack(spacing: 10) {
                        Image(systemName: "tray").font(.system(size: 40, weight: .heavy)).foregroundStyle(t.primary)
                        Text("Пусто").font(fnt(20)).foregroundStyle(t.onSurface)
                        Text("Нажмите + и вставьте ссылки или адрес подписки").font(fnt(13, .semibold))
                            .foregroundStyle(t.onSurfaceVariant).multilineTextAlignment(.center)
                    }.padding(30).frame(maxWidth: .infinity).glass(32).reveal(0.1)
                }

                let manual = store.servers(in: nil)
                if !manual.isEmpty { group("Вручную", manual, nil, 0.1) }
                ForEach(Array(store.subs.enumerated()), id: \.element.id) { i, sub in
                    group(sub.name, store.servers(in: sub.id), sub, 0.15 + Double(i) * 0.05)
                }
            }
            .padding(.horizontal, 20).padding(.top, 12).padding(.bottom, 120)
        }
        .sheet(isPresented: $showAdd) { AddSheet().environmentObject(t).environmentObject(store) }
    }

    private func group(_ title: String, _ list: [Server], _ sub: Subscription?, _ d: Double) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title).font(fnt(16)).foregroundStyle(t.onSurfaceVariant)
                Spacer()
                if let sub {
                    Button { tap(); Task { await store.refresh(sub) } } label: { Image(systemName: "arrow.triangle.2.circlepath") }
                    Button { tap(); withAnimation { store.remove(sub) } } label: { Image(systemName: "trash") }
                }
            }
            .font(.system(size: 15, weight: .heavy)).foregroundStyle(t.onSurfaceVariant).padding(.horizontal, 6)
            ForEach(list) { s in row(s) }
        }.reveal(d)
    }

    private func row(_ s: Server) -> some View {
        let on = store.current?.id == s.id
        return Button { tap(); withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) { store.selected = s.id } } label: {
            HStack(spacing: 12) {
                Text(s.proto.uppercased().prefix(2)).font(fnt(13)).foregroundStyle(on ? t.onPrimary : t.onSecondaryContainer)
                    .frame(width: 40, height: 40)
                    .background(on ? t.primary : t.secondaryContainer, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                VStack(alignment: .leading, spacing: 2) {
                    Text(s.name).font(fnt(15)).foregroundStyle(t.onSurface).lineLimit(1)
                    Text("\(s.address):\(s.port) · \(s.network) · \(s.security)").font(fnt(11, .semibold))
                        .foregroundStyle(t.onSurfaceVariant).lineLimit(1)
                }
                Spacer()
                pingChip(s.ping)
                Button { tap(); withAnimation { store.remove(s) } } label: { Image(systemName: "xmark") }
                    .font(.system(size: 13, weight: .heavy)).foregroundStyle(t.onSurfaceVariant)
            }
            .padding(14)
            .background(on ? t.primaryContainer : Color.clear, in: RoundedRectangle(cornerRadius: 26, style: .continuous))
            .glass(26)
        }.buttonStyle(.plain)
    }

    @ViewBuilder private func pingChip(_ p: Int?) -> some View {
        if let p {
            Text(p < 0 ? "×" : "\(p) мс").font(fnt(12))
                .foregroundStyle(p < 0 ? t.bad : (p < 250 ? t.good : t.onSurfaceVariant))
        }
    }
}

struct AddSheet: View {
    @EnvironmentObject var t: Theme
    @EnvironmentObject var store: Store
    @Environment(\.dismiss) private var dismiss
    @State private var text = ""
    @State private var name = ""
    @State private var busy = false
    @State private var msg: String?

    private var trimmed: String { text.trimmingCharacters(in: .whitespacesAndNewlines) }
    private var isURL: Bool { trimmed.hasPrefix("http://") || trimmed.hasPrefix("https://") }

    var body: some View {
        ZStack {
            AppBackground()
            VStack(alignment: .leading, spacing: 16) {
                Text("Добавить").font(fnt(30)).foregroundStyle(t.onSurface)
                Text("Ссылки vless / vmess / trojan / ss (по одной в строке) или https-адрес подписки")
                    .font(fnt(13, .semibold)).foregroundStyle(t.onSurfaceVariant)
                TextEditor(text: $text).scrollContentBackground(.hidden)
                    .font(.system(size: 13, design: .monospaced)).foregroundStyle(t.onSurface)
                    .textInputAutocapitalization(.never).autocorrectionDisabled()
                    .padding(12).frame(height: 170).glass(22)
                if isURL {
                    TextField("Название подписки", text: $name).font(fnt(15, .semibold))
                        .padding(14).glass(18).transition(.move(edge: .top).combined(with: .opacity))
                }
                HStack {
                    Button("Из буфера") { text = UIPasteboard.general.string ?? ""; tap() }
                        .buttonStyle(PillButton(filled: false))
                    Button { add() } label: { Text(busy ? "Загрузка…" : "Добавить") }
                        .buttonStyle(PillButton()).disabled(busy || trimmed.isEmpty)
                }
                if let msg { Text(msg).font(fnt(13, .semibold)).foregroundStyle(t.bad) }
                Spacer()
            }
            .padding(24).animation(.spring(response: 0.4, dampingFraction: 0.8), value: isURL)
        }
        .presentationDetents([.large]).presentationDragIndicator(.visible)
    }

    private func add() {
        Task {
            busy = true; msg = nil
            defer { busy = false }
            if isURL {
                do {
                    let n = try await store.addSubscription(
                        name: name.isEmpty ? (URL(string: trimmed)?.host ?? "Подписка") : name, url: trimmed)
                    if n > 0 { dismiss() } else { msg = "В подписке не нашлось серверов" }
                } catch { msg = "Ошибка: \(error.localizedDescription)" }
            } else {
                if store.addLinks(text) > 0 { tap(.medium); dismiss() } else { msg = "Не нашёл ссылок vless / vmess / trojan / ss" }
            }
        }
    }
}
