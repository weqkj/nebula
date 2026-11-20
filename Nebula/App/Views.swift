import SwiftUI
import PhotosUI

enum AppTab: Int {
    case home, nodes, style
}

struct RootView: View {
    @Binding var hasOnboarded: Bool
    @EnvironmentObject var theme: ThemeManager

    var body: some View {
        ZStack {
            WallpaperLayer()
            if hasOnboarded {
                MainShellView(hasOnboarded: $hasOnboarded)
                    .transition(.opacity.combined(with: .move(edge: .trailing)))
            } else {
                OnboardingView(hasOnboarded: $hasOnboarded)
                    .transition(.opacity)
            }
        }
        .animation(.spring(response: 0.5, dampingFraction: 0.85), value: hasOnboarded)
    }
}

struct WallpaperLayer: View {
    @EnvironmentObject var theme: ThemeManager

    var body: some View {
        Group {
            if let image = theme.customWallpaper {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .overlay(Color.black.opacity(0.32))
            } else {
                theme.presetWallpapers[theme.wallpaperIndex % theme.presetWallpapers.count]
            }
        }
        .ignoresSafeArea()
    }
}

struct OnboardingView: View {
    @Binding var hasOnboarded: Bool
    @EnvironmentObject var theme: ThemeManager

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Spacer()

            ZStack {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .frame(width: 68, height: 68)
                    .overlay(RoundedRectangle(cornerRadius: 18).stroke(.white.opacity(0.22), lineWidth: 1))
                Image(systemName: "waveform.path.ecg")
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundColor(theme.seed.primary)
            }

            Text("Спокойный\nи быстрый\nтуннель.")
                .font(.system(size: 36, weight: .bold, design: .rounded))
                .foregroundColor(.white)

            Text("Nebula — нативный клиент Xray на SwiftUI с поддержкой VLESS, TCP, Trojan и HTTPS-подписок.")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.68))

            Spacer()

            Button {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.82)) {
                    hasOnboarded = true
                }
            } label: {
                HStack {
                    Text("Продолжить")
                        .font(.headline)
                    Image(systemName: "arrow.right")
                }
                .foregroundColor(theme.seed.onPrimary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 17)
                .background(theme.seed.primary, in: Capsule())
            }
        }
        .padding(28)
    }
}

struct MainShellView: View {
    @Binding var hasOnboarded: Bool
    @State private var tab: AppTab = .home
    @State private var showImport = false
    @EnvironmentObject var theme: ThemeManager
    @EnvironmentObject var vpn: VPNManager

    var body: some View {
        ZStack(alignment: .bottom) {
            Group {
                switch tab {
                case .home:  HomeTabView(tab: $tab, hasOnboarded: $hasOnboarded)
                case .nodes: NodesTabView(showImport: $showImport)
                case .style: StyleTabView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            // Плавающий Liquid Glass Tab Bar
            HStack(spacing: 4) {
                tabButton(.home, title: "Туннель", icon: "power")
                tabButton(.nodes, title: "Узлы", icon: "line.3.horizontal")
                tabButton(.style, title: "Стиль", icon: "circle.lefthalf.filled")
            }
            .padding(6)
            .background(.ultraThinMaterial, in: Capsule())
            .overlay(Capsule().stroke(.white.opacity(0.18), lineWidth: 1))
            .shadow(color: .black.opacity(0.4), radius: 20, y: 10)
            .padding(.horizontal, 22)
            .padding(.bottom, 12)
        }
        .sheet(isPresented: $showImport) {
            ImportSheetView()
                .presentationDetents([.medium])
        }
    }

    private func tabButton(_ target: AppTab, title: String, icon: String) -> some View {
        let active = tab == target
        return Button {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) { tab = target }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: icon).font(.system(size: 13, weight: .semibold))
                Text(title).font(.system(size: 12, weight: .semibold))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 11)
            .foregroundColor(active ? theme.seed.onPrimary : .white.opacity(0.7))
            .background(active ? theme.seed.primary : Color.clear, in: Capsule())
        }
    }
}

struct HomeTabView: View {
    @Binding var tab: AppTab
    @Binding var hasOnboarded: Bool
    @EnvironmentObject var theme: ThemeManager
    @EnvironmentObject var vpn: VPNManager

    var body: some View {
        VStack(spacing: 24) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text(Date.now.formatted(.dateTime.weekday(.wide).day().month(.wide)))
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.55))
                        .textCase(.uppercase)
                    Text(ThemeManager.timeGreeting)
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                }
                Spacer()
                Button { hasOnboarded = false } label: {
                    Image(systemName: "info.circle")
                        .foregroundColor(.white.opacity(0.8))
                        .frame(width: 38, height: 38)
                        .background(.ultraThinMaterial, in: Circle())
                }
            }
            .padding(.horizontal, 22)
            .padding(.top, 12)

            Spacer()

            Button {
                withAnimation(.spring(response: 0.45, dampingFraction: 0.72)) {
                    vpn.toggle()
                }
            } label: {
                let connected = vpn.state == .connected
                ZStack {
                    RoundedRectangle(cornerRadius: connected ? 82 : 46, style: .continuous)
                        .fill(.ultraThinMaterial)
                        .frame(width: 164, height: 164)
                        .overlay(
                            RoundedRectangle(cornerRadius: connected ? 76 : 40, style: .continuous)
                                .fill(connected ? theme.seed.primary : Color.clear)
                                .padding(6)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: connected ? 82 : 46, style: .continuous)
                                .stroke(.white.opacity(0.24), lineWidth: 1.2)
                        )

                    VStack(spacing: 8) {
                        Image(systemName: vpn.state == .connecting ? "ellipsis" : "power")
                            .font(.system(size: 38, weight: .medium))
                        Text(connected ? "АКТИВНО" : (vpn.state == .connecting ? "СОЕДИНЕНИЕ" : "ПОДКЛЮЧИТЬ"))
                            .font(.system(size: 11, weight: .bold))
                            .tracking(0.8)
                    }
                    .foregroundColor(connected ? theme.seed.onPrimary : .white)
                }
            }
            .buttonStyle(.plain)

            if let node = vpn.activeNode {
                Text(node.name)
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.65))
            }

            Spacer()

            if let node = vpn.activeNode {
                Button { tab = .nodes } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: 8) {
                                Text(node.proto.rawValue)
                                    .font(.caption2.bold())
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background(theme.seed.primary, in: RoundedRectangle(cornerRadius: 6))
                                    .foregroundColor(theme.seed.onPrimary)
                                Text(node.name)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundColor(.white)
                                    .lineLimit(1)
                            }
                            Text("Пинг \(node.pingMs) ms • Нажмите для выбора")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.55))
                        }
                        Spacer()
                        Image(systemName: "chevron.right").foregroundColor(.white.opacity(0.5))
                    }
                    .padding(16)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 22).stroke(.white.opacity(0.14), lineWidth: 1))
                }
                .padding(.horizontal, 22)
                .padding(.bottom, 92)
            }
        }
    }
}

struct NodesTabView: View {
    @Binding var showImport: Bool
    @EnvironmentObject var theme: ThemeManager
    @EnvironmentObject var vpn: VPNManager

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Подписки").font(.title2.bold()).foregroundColor(.white)
                    Text("\(vpn.nodes.count) конфигураций").font(.caption).foregroundColor(.white.opacity(0.55))
                }
                Spacer()
                Button { showImport = true } label: {
                    Label("Импорт", systemImage: "plus")
                        .font(.caption.bold())
                        .foregroundColor(theme.seed.onPrimary)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(theme.seed.primary, in: Capsule())
                }
            }
            .padding(.horizontal, 22)
            .padding(.top, 12)

            ScrollView(showsIndicators: false) {
                LazyVStack(spacing: 10) {
                    ForEach(vpn.nodes) { node in
                        let selected = vpn.activeNode?.id == node.id
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                HStack(spacing: 6) {
                                    Text(node.proto.rawValue)
                                        .font(.caption2.bold())
                                        .padding(.horizontal, 7)
                                        .padding(.vertical, 2)
                                        .background(selected ? theme.seed.primary : .white.opacity(0.12), in: RoundedRectangle(cornerRadius: 6))
                                        .foregroundColor(selected ? theme.seed.onPrimary : .white)
                                    Text(node.name).font(.subheadline.weight(.semibold)).foregroundColor(.white).lineLimit(1)
                                }
                                Text(node.rawURI).font(.caption2.monospaced()).foregroundColor(.white.opacity(0.45)).lineLimit(1)
                            }
                            Spacer()
                            Text("\(node.pingMs)ms").font(.caption.monospaced()).foregroundColor(.green)
                        }
                        .padding(14)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: 20).stroke(selected ? theme.seed.primary : .white.opacity(0.12), lineWidth: selected ? 1.5 : 1))
                        .onTapGesture {
                            withAnimation(.spring()) { vpn.selectedNodeID = node.id }
                        }
                    }
                }
                .padding(.horizontal, 22)
                .padding(.bottom, 100)
            }
        }
    }
}

struct StyleTabView: View {
    @EnvironmentObject var theme: ThemeManager
    @State private var photoItem: PhotosPickerItem? = nil

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text("Оформление").font(.title2.bold()).foregroundColor(.white)

                VStack(alignment: .leading, spacing: 12) {
                    Text("Динамический цвет (Material You 3)").font(.subheadline.weight(.semibold)).foregroundColor(.white)
                    HStack(spacing: 14) {
                        ForEach(MaterialSeed.allCases) { seed in
                            Circle()
                                .fill(seed.primary)
                                .frame(width: 38, height: 38)
                                .overlay(Circle().stroke(.white, lineWidth: theme.seed == seed ? 2.5 : 0))
                                .onTapGesture { theme.seed = seed }
                        }
                    }
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 22))

                VStack(alignment: .leading, spacing: 12) {
                    Text("Обои").font(.subheadline.weight(.semibold)).foregroundColor(.white)
                    HStack(spacing: 10) {
                        ForEach(0..<theme.presetWallpapers.count, id: \.self) { idx in
                            RoundedRectangle(cornerRadius: 12)
                                .fill(theme.presetWallpapers[idx])
                                .frame(height: 54)
                                .overlay(RoundedRectangle(cornerRadius: 12).stroke(.white.opacity(0.2), lineWidth: 1))
                                .onTapGesture {
                                    theme.customWallpaper = nil
                                    theme.wallpaperIndex = idx
                                }
                        }
                    }
                    PhotosPicker(selection: $photoItem, matching: .images) {
                        Label("Выбрать свои обои из галереи", systemImage: "photo")
                            .font(.subheadline.weight(.semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(theme.seed.primary, in: RoundedRectangle(cornerRadius: 14))
                            .foregroundColor(theme.seed.onPrimary)
                    }
                    .onChange(of: photoItem) { item in
                        Task {
                            if let data = try? await item?.loadTransferable(type: Data.self),
                               let uiImg = UIImage(data: data) {
                                theme.customWallpaper = uiImg
                            }
                        }
                    }
                }
                .padding(16)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 22))
            }
            .padding(22)
            .padding(.bottom, 90)
        }
    }
}

struct ImportSheetView: View {
    @EnvironmentObject var vpn: VPNManager
    @Environment(\.dismiss) var dismiss
    @State private var text = ""

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 12) {
                Text("Вставьте VLESS, TCP, Trojan, VMess или HTTPS подписки (каждую с новой строки):")
                    .font(.footnote)
                    .foregroundColor(.secondary)

                TextEditor(text: $text)
                    .font(.caption.monospaced())
                    .frame(height: 160)
                    .padding(8)
                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.gray.opacity(0.25)))

                Button {
                    vpn.importBulk(text)
                    dismiss()
                } label: {
                    Text("Импортировать")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                }
                .buttonStyle(.borderedProminent)
                Spacer()
            }
            .padding()
            .navigationTitle("Импорт подписок")
            .toolbar { Button("Закрыть") { dismiss() } }
        }
    }
}
