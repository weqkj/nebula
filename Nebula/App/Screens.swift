import SwiftUI
import PhotosUI

// MARK: Style
struct StyleView: View {
    @EnvironmentObject var t: Theme
    @State private var item: PhotosPickerItem?

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 16) {
                Text("Стиль").font(bold(36)).foregroundStyle(t.onSurface).reveal(0)

                card("Имя", 0.05) {
                    TextField("Как вас зовут?", text: $t.userName).font(bold(17, .semibold)).foregroundStyle(t.onSurface)
                }
                card("Цвет", 0.1) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(Theme.presets) { p in
                                Circle().fill(Color(hue: p.hue, saturation: 0.6, brightness: 0.85))
                                    .frame(width: 46, height: 46)
                                    .overlay(Image(systemName: "checkmark").font(.system(size: 16, weight: .heavy)).foregroundStyle(.white)
                                        .scaleEffect(abs(t.hue - p.hue) < 0.005 ? 1 : 0.1)
                                        .opacity(abs(t.hue - p.hue) < 0.005 ? 1 : 0))
                                    .onTapGesture { tap(); withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) { t.hue = p.hue } }
                            }
                        }.padding(.vertical, 4)
                    }
                    ColorPicker("Свой цвет", selection: Binding(
                        get: { Color(hue: t.hue, saturation: 0.6, brightness: 0.85) },
                        set: { c in
                            var h: CGFloat = 0
                            UIColor(c).getHue(&h, saturation: nil, brightness: nil, alpha: nil)
                            t.hue = Double(h)
                        })).font(bold(15, .bold)).foregroundStyle(t.onSurface)
                }
                card("Тема", 0.15) {
                    Picker("", selection: $t.mode) {
                        Text("Авто").tag(0); Text("Светлая").tag(1); Text("Тёмная").tag(2)
                    }.pickerStyle(.segmented)
                }
                card("Обои", 0.2) {
                    HStack {
                        PhotosPicker(selection: $item, matching: .images) {
                            Label("Выбрать фото", systemImage: "photo.fill")
                                .font(bold(15)).padding(.horizontal, 20).frame(height: 44)
                                .foregroundStyle(t.onPrimary).background(t.primary, in: Capsule())
                        }
                        if t.wallpaper != nil {
                            Button("Убрать") { tap(); withAnimation { t.clearWallpaper() } }
                                .buttonStyle(PillButton(filled: false))
                        }
                    }
                    if t.wallpaper != nil {
                        Text("Затемнение").font(bold(13, .bold)).foregroundStyle(t.onSurfaceVariant)
                        Slider(value: $t.dim, in: 0...0.8)
                    }
                }
                Button("Показать приветствие") { tap(); withAnimation { t.onboarded = false } }
                    .buttonStyle(PillButton(filled: false)).reveal(0.25)
            }
            .padding(.horizontal, 20).padding(.top, 12).padding(.bottom, 120)
        }
        .onChange(of: item) { new in
            Task {
                if let d = try? await new?.loadTransferable(type: Data.self) {
                    withAnimation(.easeInOut(duration: 0.5)) { t.setWallpaper(d) }
                }
            }
        }
    }

    private func card<C: View>(_ title: String, _ d: Double, @ViewBuilder _ c: () -> C) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title).font(bold(14)).foregroundStyle(t.onSurfaceVariant)
            c()
        }
        .padding(18).frame(maxWidth: .infinity, alignment: .leading).glass(28).reveal(d)
    }
}

// MARK: Welcome
struct Blob: View {
    @EnvironmentObject var t: Theme
    let icon: String
    @State private var spin = false
    @State private var breathe = false
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 90, style: .continuous).fill(t.primaryContainer)
                .frame(width: 230, height: 230).rotationEffect(.degrees(spin ? 360 : 0))
            RoundedRectangle(cornerRadius: 70, style: .continuous).fill(t.tertiaryContainer)
                .frame(width: 175, height: 175).rotationEffect(.degrees(spin ? -360 : 0))
                .scaleEffect(breathe ? 1.08 : 0.94)
            Image(systemName: icon).font(.system(size: 66, weight: .heavy)).foregroundStyle(t.onPrimaryContainer)
                .scaleEffect(breathe ? 1.06 : 0.96)
        }
        .onAppear {
            withAnimation(.linear(duration: 22).repeatForever(autoreverses: false)) { spin = true }
            withAnimation(.easeInOut(duration: 2.4).repeatForever(autoreverses: true)) { breathe = true }
        }
    }
}

struct WelcomeView: View {
    @EnvironmentObject var t: Theme
    @State private var page = 0
    private let titles = ["Добро пожаловать", "Все подписки в одном месте", "Давайте знакомиться"]
    private let texts = ["Nebula — быстрый и красивый клиент на Xray.",
                         "VLESS, VMess, Trojan, Shadowsocks и подписки по ссылке.",
                         "Как к вам обращаться и какой цвет вам по душе?"]
    private let icons = ["sparkles", "tray.full.fill", "hand.wave.fill"]

    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $page) {
                ForEach(0..<3, id: \.self) { i in
                    VStack(spacing: 22) {
                        Spacer()
                        Blob(icon: icons[i])
                        Text(titles[i]).font(bold(32)).multilineTextAlignment(.center).foregroundStyle(t.onSurface)
                        Text(texts[i]).font(bold(16, .semibold)).multilineTextAlignment(.center).foregroundStyle(t.onSurfaceVariant)
                        if i == 2 {
                            TextField("Ваше имя", text: $t.userName).font(bold(18, .bold)).multilineTextAlignment(.center)
                                .padding(14).glass(22).padding(.horizontal, 40)
                            HStack(spacing: 10) {
                                ForEach(Theme.presets) { p in
                                    Circle().fill(Color(hue: p.hue, saturation: 0.6, brightness: 0.85))
                                        .frame(width: abs(t.hue - p.hue) < 0.005 ? 34 : 24, height: abs(t.hue - p.hue) < 0.005 ? 34 : 24)
                                        .onTapGesture { tap(); withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) { t.hue = p.hue } }
                                }
                            }
                        }
                        Spacer()
                    }.padding(.horizontal, 28).tag(i)
                }
            }.tabViewStyle(.page(indexDisplayMode: .never))

            HStack(spacing: 8) {
                ForEach(0..<3, id: \.self) { i in
                    Capsule().fill(i == page ? t.primary : t.outline.opacity(0.4))
                        .frame(width: i == page ? 28 : 10, height: 10)
                }
            }.animation(.spring(response: 0.4, dampingFraction: 0.7), value: page).padding(.bottom, 20)

            Button {
                tap(.medium)
                if page < 2 { withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) { page += 1 } }
                else { t.userName = t.userName.trimmingCharacters(in: .whitespaces); withAnimation { t.onboarded = true } }
            } label: {
                Text(page < 2 ? "Далее" : "Начать").frame(maxWidth: .infinity)
            }
            .buttonStyle(PillButton()).padding(.horizontal, 28).padding(.bottom, 30)
        }
    }
}
