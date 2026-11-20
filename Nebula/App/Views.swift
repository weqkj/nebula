import SwiftUI
import PhotosUI

enum AppTab: Hashable {
    case home, nodes, style
}

struct RootContainerView: View {
    @AppStorage("nebula.welcomed") private var hasWelcomed = false
    @EnvironmentObject var theme: ThemeEngine

    var body: some View {
        ZStack {
            theme.backgroundColor.ignoresSafeArea()
            if let img = theme.wallpaperImage {
                Image(uiImage: img)
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()
            }
            Color.clear
                .background(.ultraThinMaterial.opacity(theme.screenBlur > 0 ? 0.6 : 0))
                .blur(radius: theme.screenBlur)
                .ignoresSafeArea()

            if hasWelcomed {
                MainShellView(hasWelcomed: $hasWelcomed)
                    .transition(.opacity)
            } else {
                WelcomeScreen(hasWelcomed: $hasWelcomed)
                    .transition(.opacity)
            }
        }
        .animation(.spring(response: 0.45, dampingFraction: 0.85), value: hasWelcomed)
    }
}

struct WelcomeScreen: View {
    @Binding var hasWelcomed: Bool
    @EnvironmentObject var theme: ThemeEngine
    @State private var spin = false

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Text("Nebula 1.0")
                    .font(.caption.bold())
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(theme.palette.primaryContainer, in: Capsule())
                    .foregroundColor(theme.palette.onPrimaryContainer)
                Spacer()
            }

            Spacer()

            ZStack {
                ScallopBadgeShape()
                    .fill(theme.palette.primaryContainer)
                    .frame(width: 108, height: 108)
                    .rotationEffect(.degrees(spin ? 360 : 0))
                    .animation(.linear(duration: 18).repeatForever(autoreverses: false), value: spin)
                Image(systemName: "power")
                    .font(.system(size: 38, weight: .semibold))
                    .foregroundColor(theme.palette.onPrimaryContainer)
            }
            .onAppear { spin = true }

            Text("Добро\nпожаловать")
                .font(.system(size: 36, weight: .heavy, design: .rounded))
                .foregroundColor(theme.onSurface)

            Text("Ваш личный Xray-клиент. Подписки, ключи и оформление в одном касании.")
                .font(.subheadline)
                .foregroundColor(theme.onSurfaceMuted)

            Spacer()

            Button {
                hasWelcomed = true
            } label: {
                HStack {
                    Text("Открыть Nebula")
                        .font(.headline)
                    Spacer()
                    Image(systemName: "arrow.right")
                        .padding(8)
                        .background(Color.black.opacity(0.12), in: Circle())
                }
                .padding(.horizontal, 22)
                .padding(.vertical, 16)
                .background(theme.palette.primary, in: Capsule())
                .foregroundColor(theme.palette.onPrimary)
            }
        }
        .padding(24)
    }
}

struct MainShellView: View {
    @Binding var hasWelcomed: Bool
    @EnvironmentObject var theme: ThemeEngine
    @EnvironmentObject var manager: VPNManager
    @State private var tab: AppTab = .home
    @State private var showImport = false

    var body: some View {
        ZStack(alignment: .bottom) {
            Group {
                switch tab {
                case .home:
                    HomeTabView(hasWelcomed: $hasWelcomed, tab: $tab, showImport: $showImport)
                case .nodes:
                    NodesTabView(tab: $tab, showImport: $showImport)
                case .style:
                    StyleTabView(tab: $tab)
                }
            }
            .padding(.bottom, 86)

            // Нижняя панель Material You 3
            HStack(spacing: 8) {
                navItem(title: "Туннель", icon: "power", target: .home)
                navItem(title: "Узлы", icon: "line.3.horizontal", target: .nodes)
                navItem(title: "Стиль", icon: "paintpalette", target: .style)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(.ultraThinMaterial, in: Capsule())
            .overlay(Capsule().stroke(theme.onSurface.opacity(0.12), lineWidth: 1))
            .padding(.horizontal, 18)
            .padding(.bottom, 10)
        }
        .sheet(isPresented: $showImport) {
            ImportSheetView()
        }
    }

    private func navItem(title: String, icon: String, target: AppTab) -> some View {
        let active = tab == target
        return Button {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) { tab = target }
        } label: {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .frame(width: 54, height: 30)
                    .background(active ? theme.palette.primaryContainer : Color.clear, in: Capsule())
                    .foregroundColor(active ? theme.palette.onPrimaryContainer : theme.onSurfaceMuted)
                Text(title)
                    .font(.caption2.bold())
                    .foregroundColor(active ? theme.onSurface : theme.onSurfaceMuted)
            }
            .frame(maxWidth: .infinity)
        }
    }
}

struct HomeTabView: View {
    @Binding var hasWelcomed: Bool
    @Binding var tab: AppTab
    @Binding var showImport: Bool
    @EnvironmentObject var theme: ThemeEngine
    @EnvironmentObject var manager: VPNManager

    private var greeting: String {
        let h = Calendar.current.component(.hour, from: Date())
        if h < 6 { return "Доброй\nночи" }
        if h < 12 { return "Доброе\nутро" }
        if h < 18 { return "Добрый\nдень" }
        return "Добрый\nвечер"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Button { hasWelcomed = false } label: {
                    Image(systemName: "chevron.left")
                        .frame(width: 36, height: 36)
                        .background(theme.surfaceColor, in: Circle())
                }
                Spacer()
                Button { theme.isLightMode.toggle() } label: {
                    Image(systemName: theme.isLightMode ? "moon.fill" : "sun.max.fill")
                        .frame(width: 36, height: 36)
                        .background(theme.surfaceColor, in: Circle())
                }
            }
            .foregroundColor(theme.onSurface)

            HStack {
                Text(greeting)
                    .font(.system(size: 30, weight: .heavy, design: .rounded))
                    .foregroundColor(theme.onSurface)
                Spacer()
                ZStack {
                    ScallopBadgeShape()
                        .fill(manager.isConnected ? theme.palette.primaryContainer : theme.surfaceColor)
                        .frame(width: 68, height: 68)
                    Text(manager.isConnected ? "ON" : "OFF")
                        .font(.caption2.bold())
                        .foregroundColor(theme.onSurface)
                }
            }

            Spacer()

            // Карточка активного узла + волнистая линия M3 без вертикальной палки
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(manager.activeNode?.proto.rawValue ?? "VLESS")
                            .font(.caption2.bold())
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(theme.palette.primaryContainer, in: Capsule())
                            .foregroundColor(theme.palette.onPrimaryContainer)
                        Text(manager.activeNode?.name ?? "Сервер не выбран")
                            .font(.headline)
                            .foregroundColor(theme.onSurface)
                    }
                    Spacer()
                    Button { tab = .nodes } label: {
                        Image(systemName: "arrow.left.arrow.right")
                            .frame(width: 36, height: 36)
                            .background(theme.onSurface.opacity(0.08), in: Circle())
                            .foregroundColor(theme.onSurface)
                    }
                }

                WavyMusicBar(active: manager.isConnected, accent: theme.palette.primary)
                    .frame(height: 22)

                HStack {
                    Text(String(format: "%02d:%02d:%02d", manager.elapsedSeconds / 3600, (manager.elapsedSeconds % 3600) / 60, manager.elapsedSeconds % 60))
                    Spacer()
                    Text("\(manager.activeNode?.pingMs ?? 28) ms")
                }
                .font(.caption.monospacedDigit())
                .foregroundColor(theme.onSurfaceMuted)
            }
            .padding(16)
            .background(theme.surfaceColor, in: RoundedRectangle(cornerRadius: 28, style: .continuous))

            HStack(spacing: 10) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Приём").font(.caption2).opacity(0.75)
                    Text(String(format: "%.1f MB/s", manager.downMbps)).font(.headline.monospacedDigit())
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(14)
                .background(theme.palette.primaryContainer, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
                .foregroundColor(theme.palette.onPrimaryContainer)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Отдача").font(.caption2).opacity(0.75)
                    Text(String(format: "%.1f MB/s", manager.upMbps)).font(.headline.monospacedDigit())
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(14)
                .background(theme.palette.tertiary, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
                .foregroundColor(theme.palette.onTertiary)
            }

            // Нижняя кнопка включения под большой палец + кнопка «+»
            HStack(spacing: 10) {
                Button {
                    manager.toggleConnection()
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "power")
                            .font(.headline)
                            .frame(width: 38, height: 38)
                            .background(Color.black.opacity(0.14), in: Circle())
                        Text(manager.isConnected ? "Отключить" : "Подключить")
                            .font(.headline)
                        Spacer()
                    }
                    .padding(.horizontal, 14)
                    .frame(height: 60)
                    .background(
                        manager.isConnected ? theme.palette.primaryContainer : theme.palette.primary,
                        in: RoundedRectangle(cornerRadius: manager.isConnected ? 20 : 30, style: .continuous)
                    )
                    .foregroundColor(manager.isConnected ? theme.palette.onPrimaryContainer : theme.palette.onPrimary)
                }

                Button { showImport = true } label: {
                    Image(systemName: "plus")
                        .font(.title3.bold())
                        .frame(width: 60, height: 60)
                        .background(theme.palette.primaryContainer, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
                        .foregroundColor(theme.palette.onPrimaryContainer)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
    }
}

struct NodesTabView: View {
    @Binding var tab: AppTab
    @Binding var showImport: Bool
    @EnvironmentObject var theme: ThemeEngine
    @EnvironmentObject var manager: VPNManager

    var body: some View {
        VStack(spacing: 14) {
            HStack {
                Button { tab = .home } label: {
                    Image(systemName: "chevron.left")
                        .frame(width: 36, height: 36)
                        .background(theme.surfaceColor, in: Circle())
                        .foregroundColor(theme.onSurface)
                }
                Text("Узлы")
                    .font(.title3.bold())
                    .foregroundColor(theme.onSurface)
                Spacer()
                Button("Пинг") { manager.pingAll() }
                    .font(.caption.bold())
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(theme.surfaceColor, in: Capsule())
                    .foregroundColor(theme.onSurface)
                Button("+") { showImport = true }
                    .font(.headline)
                    .frame(width: 34, height: 34)
                    .background(theme.palette.primary, in: Circle())
                    .foregroundColor(theme.palette.onPrimary)
            }

            ScrollView {
                VStack(spacing: 10) {
                    ForEach(manager.nodes) { node in
                        let selected = manager.activeNode?.id == node.id
                        HStack {
                            VStack(alignment: .leading, spacing: 3) {
                                Text(node.name)
                                    .font(.subheadline.bold())
                                    .foregroundColor(selected ? theme.palette.onPrimaryContainer : theme.onSurface)
                                Text("\(node.proto.rawValue) • \(node.pingMs) ms")
                                    .font(.caption.monospacedDigit())
                                    .foregroundColor(selected ? theme.palette.onPrimaryContainer.opacity(0.8) : theme.onSurfaceMuted)
                            }
                            Spacer()
                            if selected {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(theme.palette.onPrimaryContainer)
                            }
                        }
                        .padding(14)
                        .background(selected ? theme.palette.primaryContainer : theme.surfaceColor, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
                        .onTapGesture {
                            manager.selectedNodeID = node.id
                            manager.saveNodes()
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
    }
}

struct StyleTabView: View {
    @Binding var tab: AppTab
    @EnvironmentObject var theme: ThemeEngine
    @State private var pickerItem: PhotosPickerItem?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Button { tab = .home } label: {
                        Image(systemName: "chevron.left")
                            .frame(width: 36, height: 36)
                            .background(theme.surfaceColor, in: Circle())
                            .foregroundColor(theme.onSurface)
                    }
                    Text("Стиль")
                        .font(.title3.bold())
                        .foregroundColor(theme.onSurface)
                    Spacer()
                }

                Toggle("Светлая тема", isOn: $theme.isLightMode)
                    .tint(theme.palette.primary)
                    .padding(16)
                    .background(theme.surfaceColor, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
                    .foregroundColor(theme.onSurface)

                VStack(alignment: .leading, spacing: 10) {
                    Text("Цветовая схема").font(.subheadline.bold()).foregroundColor(theme.onSurface)
                    HStack(spacing: 12) {
                        ForEach(M3Palette.all) { item in
                            Circle()
                                .fill(item.primary)
                                .frame(width: 38, height: 38)
                                .overlay(Circle().stroke(theme.onSurface, lineWidth: theme.palette.id == item.id ? 2.5 : 0))
                                .onTapGesture { theme.palette = item }
                        }
                    }
                }
                .padding(16)
                .background(theme.surfaceColor, in: RoundedRectangle(cornerRadius: 24, style: .continuous))

                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("Обои экрана").font(.subheadline.bold()).foregroundColor(theme.onSurface)
                        Spacer()
                        PhotosPicker(selection: $pickerItem, matching: .images) {
                            Text("Выбрать фото")
                                .font(.caption.bold())
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(theme.palette.primaryContainer, in: Capsule())
                                .foregroundColor(theme.palette.onPrimaryContainer)
                        }
                    }
                    HStack(spacing: 10) {
                        ForEach(0..<theme.solidPresets.count, id: \.self) { idx in
                            RoundedRectangle(cornerRadius: 14)
                                .fill(theme.solidPresets[idx])
                                .frame(height: 42)
                                .onTapGesture {
                                    theme.wallpaperImage = nil
                                    theme.solidPresetIndex = idx
                                }
                        }
                    }
                }
                .padding(16)
                .background(theme.surfaceColor, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
                .onChange(of: pickerItem) { newItem in
                    Task {
                        if let data = try? await newItem?.loadTransferable(type: Data.self),
                           let uiImg = UIImage(data: data) {
                            theme.wallpaperImage = uiImg
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Размытие экрана: \(Int(theme.screenBlur)) px")
                        .font(.subheadline.bold())
                        .foregroundColor(theme.onSurface)
                    Slider(value: $theme.screenBlur, in: 0...28)
                        .tint(theme.palette.primary)
                }
                .padding(16)
                .background(theme.surfaceColor, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
        }
    }
}

struct ImportSheetView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var manager: VPNManager
    @EnvironmentObject var theme: ThemeEngine
    @State private var raw = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Button { dismiss() } label: {
                    Image(systemName: "chevron.left")
                        .frame(width: 34, height: 34)
                        .background(theme.surfaceColor, in: Circle())
                }
                Text("Импорт ссылок").font(.headline)
                Spacer()
            }
            TextEditor(text: $raw)
                .font(.caption.monospaced())
                .frame(height: 150)
                .padding(8)
                .background(theme.surfaceColor, in: RoundedRectangle(cornerRadius: 18))
            Button("Добавить в список") {
                _ = manager.importRaw(raw)
                dismiss()
            }
            .font(.headline)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(theme.palette.primary, in: Capsule())
            .foregroundColor(theme.palette.onPrimary)
            Spacer()
        }
        .padding(20)
    }
}

// Волнистая линия M3 без вертикальной палки
struct WavyMusicBar: View {
    let active: Bool
    let accent: Color

    var body: some View {
        TimelineView(.animation) { timeline in
            let phase = timeline.date.timeIntervalSinceReferenceDate * 4.5
            Canvas { ctx, size in
                let midY = size.height / 2
                let activeW = size.width * (active ? 0.56 : 0.25)

                var bg = Path()
                bg.move(to: CGPoint(x: activeW + 6, y: midY))
                bg.addLine(to: CGPoint(x: size.width, y: midY))
                ctx.stroke(bg, with: .color(accent.opacity(0.24)), style: StrokeStyle(lineWidth: 3.5, lineCap: .round))

                var wave = Path()
                let amp: CGFloat = active ? 4.2 : 0
                var x: CGFloat = 0
                while x <= activeW {
                    let y = midY + sin(Double(x) * 0.22 - phase) * amp
                    if x == 0 { wave.move(to: CGPoint(x: x, y: y)) }
                    else { wave.addLine(to: CGPoint(x: x, y: y)) }
                    x += 2
                }
                ctx.stroke(wave, with: .color(accent), style: StrokeStyle(lineWidth: 3.5, lineCap: .round))
            }
        }
    }
}

struct ScallopBadgeShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let r = min(rect.width, rect.height) * 0.44
        let lobes = 10.0
        for i in 0...360 {
            let rad = Double(i) * .pi / 180.0
            let mod = 1.0 + 0.09 * cos(lobes * rad)
            let pt = CGPoint(x: center.x + CGFloat(cos(rad) * mod) * r,
                             y: center.y + CGFloat(sin(rad) * mod) * r)
            if i == 0 { path.move(to: pt) } else { path.addLine(to: pt) }
        }
        path.closeSubpath()
        return path
    }
}
