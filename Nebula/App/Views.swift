import SwiftUI
import PhotosUI

enum AppTab: Int, CaseIterable {
    case home, nodes, style
}

// MARK: - Волнистый индикатор как в плеере (без вертикальной палки)
struct WavyMusicBar: View {
    var active: Bool
    var color: Color

    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                let phase = active ? timeline.date.timeIntervalSinceReferenceDate * 4.2 : 0
                let midY = size.height / 2
                let splitX = size.width * (active ? 0.72 : 0.18)
                let amp: CGFloat = active ? 4.5 : 0

                // Правая спокойная часть
                var track = Path()
                track.move(to: CGPoint(x: splitX + 8, y: midY))
                track.addLine(to: CGPoint(x: size.width - 4, y: midY))
                context.stroke(track, with: .color(color.opacity(0.24)), style: StrokeStyle(lineWidth: 4, lineCap: .round))

                // Левая волнистая часть
                var wave = Path()
                var first = true
                for x in stride(from: CGFloat(4), through: splitX, by: 2) {
                    let y = midY + sin((x / 22) * .pi * 2 - phase) * amp
                    if first { wave.move(to: CGPoint(x: x, y: y)); first = false }
                    else { wave.addLine(to: CGPoint(x: x, y: y)) }
                }
                context.stroke(wave, with: .color(color), style: StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round))
            }
        }
        .frame(height: 28)
    }
}

struct RootView: View {
    @Binding var onboarded: Bool
    @EnvironmentObject var theme: ThemeManager

    var body: some View {
        ZStack {
            WallpaperLayer()
            if onboarded {
                MainShellView(onboarded: $onboarded)
                    .transition(.opacity)
            } else {
                OnboardingView(onboarded: $onboarded)
                    .transition(.opacity)
            }
        }
        .animation(.interactiveSpring(response: 0.48, dampingFraction: 0.84), value: onboarded)
    }
}

struct WallpaperLayer: View {
    @EnvironmentObject var theme: ThemeManager

    var body: some View {
        ZStack {
            if let image = theme.customWallpaper {
                Image(uiImage: image).resizable().scaledToFill()
                    .overlay(Color.black.opacity(theme.isLight ? 0.15 : 0.35))
            } else {
                (theme.isLight ? Color(red: 0.96, green: 0.97, blue: 0.99) : Color(red: 0.07, green: 0.08, blue: 0.10))
            }
        }
        .scaleEffect(theme.screenBlur > 0 ? 1.0 + theme.screenBlur * 0.004 : 1.0)
        .blur(radius: theme.screenBlur)
        .ignoresSafeArea()
        .animation(.easeInOut(duration: 0.45), value: theme.screenBlur)
    }
}

struct OnboardingView: View {
    @Binding var onboarded: Bool
    @EnvironmentObject var theme: ThemeManager

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Spacer()
            Text("Добро\nпожаловать")
                .font(.system(size: 38, weight: .heavy, design: .rounded))
            Text("Ваш личный Xray-клиент. Подписки, ключи и оформление в одном касании.")
                .font(.subheadline)
                .foregroundColor(.secondary)
            Spacer()
            Button {
                onboarded = true
            } label: {
                HStack {
                    Text("Открыть Nebula").font(.headline)
                    Spacer()
                    Image(systemName: "arrow.right")
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 18)
                .background(theme.tone.primary, in: Capsule())
                .foregroundColor(theme.tone.onPrimary)
            }
        }
        .padding(28)
    }
}

struct MainShellView: View {
    @Binding var onboarded: Bool
    @State private var tab: AppTab = .home
    @State private var showImport = false
    @EnvironmentObject var theme: ThemeManager
    @EnvironmentObject var vpn: VPNManager

    var body: some View {
        ZStack(alignment: .bottom) {
            Group {
                switch tab {
                case .home:  HomeTabView(tab: $tab, onboarded: $onboarded, showImport: $showImport)
                case .nodes: NodesTabView(tab: $tab, showImport: $showImport)
                case .style: StyleTabView(tab: $tab)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .blur(radius: showImport ? 7 : 0)
            .scaleEffect(showImport ? 0.96 : 1.0)
            .animation(.interactiveSpring(response: 0.44, dampingFraction: 0.85), value: showImport)

            // Нижняя навигация Material You 3
            HStack(spacing: 6) {
                navItem(.home, title: "Туннель", icon: "power")
                navItem(.nodes, title: "Узлы", icon: "line.3.horizontal")
                navItem(.style, title: "Стиль", icon: "paintpalette")
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 30, style: .continuous))
            .padding(.horizontal, 18)
            .padding(.bottom, 10)
        }
        .sheet(isPresented: $showImport) {
            ImportSheetView().presentationDetents([.medium])
        }
    }

    private func navItem(_ target: AppTab, title: String, icon: String) -> some View {
        let active = tab == target
        return Button {
            withAnimation(.interactiveSpring(response: 0.36, dampingFraction: 0.8)) { tab = target }
        } label: {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .frame(width: 56, height: 32)
                    .background(active ? theme.tone.primary : .clear, in: Capsule())
                    .foregroundColor(active ? theme.tone.onPrimary : .secondary)
                Text(title).font(.caption2.weight(.semibold))
                    .foregroundColor(active ? .primary : .secondary)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }
}

struct HomeTabView: View {
    @Binding var tab: AppTab
    @Binding var onboarded: Bool
    @Binding var showImport: Bool
    @EnvironmentObject var theme: ThemeManager
    @EnvironmentObject var vpn: VPNManager

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                Button { onboarded = false } label: {
                    Image(systemName: "chevron.left")
                        .frame(width: 38, height: 38)
                        .background(.ultraThinMaterial, in: Circle())
                }
                Spacer()
                Button { theme.isLight.toggle() } label: {
                    Image(systemName: theme.isLight ? "moon.fill" : "sun.max.fill")
                        .frame(width: 38, height: 38)
                        .background(.ultraThinMaterial, in: Circle())
                }
            }

            Text(ThemeManager.greeting)
                .font(.system(size: 34, weight: .heavy, design: .rounded))

            if let node = vpn.activeNode {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text(node.proto.rawValue)
                            .font(.caption2.bold())
                            .padding(.horizontal, 10).padding(.vertical, 4)
                            .background(theme.tone.container, in: Capsule())
                        Spacer()
                        Button { vpn.pingNode(node) } label: {
                            Text(vpn.pingingIDs.contains(node.id) ? "..." : "\(node.pingMs) ms")
                                .font(.caption.monospaced())
                                .padding(.horizontal, 10).padding(.vertical, 4)
                                .background(theme.tone.container, in: Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                    Text(node.name).font(.headline)
                    WavyMusicBar(active: vpn.state == .connected, color: theme.tone.primary)
                }
                .padding(18)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
            }

            Spacer()

            // Кнопка включения внизу под большой палец
            HStack(spacing: 10) {
                Button {
                    withAnimation(.interactiveSpring(response: 0.45, dampingFraction: 0.76)) { vpn.toggle() }
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "power").font(.title3.bold())
                        Text(vpn.state == .connected ? "Отключить" : "Подключить").font(.headline)
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .frame(height: 62)
                    .background(theme.tone.primary, in: RoundedRectangle(cornerRadius: vpn.state == .connected ? 22 : 31, style: .continuous))
                    .foregroundColor(theme.tone.onPrimary)
                }

                Button { showImport = true } label: {
                    Image(systemName: "plus")
                        .font(.title2.weight(.semibold))
                        .frame(width: 62, height: 62)
                        .background(theme.tone.container, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
                }
            }
            .padding(.bottom, 96)
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
    }
}

struct NodesTabView: View {
    @Binding var tab: AppTab
    @Binding var showImport: Bool
    @EnvironmentObject var theme: ThemeManager
    @EnvironmentObject var vpn: VPNManager

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Button { tab = .home } label: {
                    Image(systemName: "chevron.left")
                        .frame(width: 38, height: 38)
                        .background(.ultraThinMaterial, in: Circle())
                }
                Text("Узлы").font(.title2.bold())
                Spacer()
                Button { vpn.pingAll() } label: {
                    Label("Пинг", systemImage: "bolt.fill")
                        .font(.caption.bold())
                        .padding(.horizontal, 12).padding(.vertical, 8)
                        .background(theme.tone.container, in: Capsule())
                }
                Button { showImport = true } label: {
                    Label("Добавить", systemImage: "plus")
                        .font(.caption.bold())
                        .padding(.horizontal, 14).padding(.vertical, 8)
                        .background(theme.tone.primary, in: Capsule())
                        .foregroundColor(theme.tone.onPrimary)
                }
            }
            ScrollView {
                LazyVStack(spacing: 10) {
                    ForEach(vpn.nodes) { node in
                        let selected = vpn.activeNode?.id == node.id
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(node.name).font(.subheadline.bold())
                                Text(node.rawURI).font(.caption2.monospaced()).foregroundColor(.secondary).lineLimit(1)
                            }
                            Spacer()
                            Button { vpn.pingNode(node) } label: {
                                Text(vpn.pingingIDs.contains(node.id) ? "..." : "\(node.pingMs)ms")
                                    .font(.caption.monospaced())
                                    .foregroundColor(node.pingMs < 80 ? .green : (node.pingMs < 180 ? .yellow : .red))
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(14)
                        .background(selected ? theme.tone.container : Color.primary.opacity(0.06), in: RoundedRectangle(cornerRadius: 22))
                        .onTapGesture { vpn.selectedNodeID = node.id }
                    }
                }
                .padding(.bottom, 100)
            }
        }
        .padding(.horizontal, 20).padding(.top, 8)
    }
}

struct StyleTabView: View {
    @Binding var tab: AppTab
    @EnvironmentObject var theme: ThemeManager
    @State private var photoItem: PhotosPickerItem? = nil

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Button { tab = .home } label: {
                        Image(systemName: "chevron.left")
                            .frame(width: 38, height: 38)
                            .background(.ultraThinMaterial, in: Circle())
                    }
                    Text("Стиль").font(.title2.bold())
                }

                Toggle("Светлая тема", isOn: $theme.isLight)
                    .padding(16)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24))

                HStack(spacing: 14) {
                    ForEach(AccentTone.allCases) { item in
                        Circle().fill(item.primary).frame(width: 38, height: 38)
                            .onTapGesture { theme.tone = item }
                    }
                }
                .padding(16).frame(maxWidth: .infinity, alignment: .leading)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24))

                VStack(alignment: .leading, spacing: 8) {
                    Text("Размытие экрана: \(Int(theme.screenBlur)) px").font(.subheadline.bold())
                    Slider(value: $theme.screenBlur, in: 0...28, step: 1).tint(theme.tone.primary)
                }
                .padding(16)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24))

                PhotosPicker(selection: $photoItem, matching: .images) {
                    Label("Выбрать свои обои", systemImage: "photo")
                        .frame(maxWidth: .infinity).padding(.vertical, 14)
                        .background(theme.tone.primary, in: Capsule())
                        .foregroundColor(theme.tone.onPrimary)
                }
                .onChange(of: photoItem) { item in
                    Task {
                        if let data = try? await item?.loadTransferable(type: Data.self),
                           let img = UIImage(data: data) { theme.customWallpaper = img }
                    }
                }
            }
            .padding(20).padding(.bottom, 96)
        }
    }
}

struct ImportSheetView: View {
    @EnvironmentObject var vpn: VPNManager
    @Environment(\.dismiss) var dismiss
    @State private var text = ""

    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                TextEditor(text: $text)
                    .font(.caption.monospaced())
                    .frame(height: 160)
                    .padding(8)
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.gray.opacity(0.25)))
                Button("Добавить") { vpn.importBulk(text); dismiss() }
                    .buttonStyle(.borderedProminent)
                Spacer()
            }
            .padding()
            .navigationTitle("Импорт")
            .toolbar { Button("Назад") { dismiss() } }
        }
    }
}
