import SwiftUI
import UIKit

struct Preset: Identifiable {
    let name: String
    let hue: Double
    var id: Double { hue }
}

/// Material You 3: палитра строится из одного "seed" цвета (hue), светлая и тёмная схемы.
final class Theme: ObservableObject {
    static let presets = [
        Preset(name: "Фиолетовый", hue: 0.74), Preset(name: "Синий", hue: 0.60),
        Preset(name: "Бирюза", hue: 0.48), Preset(name: "Зелёный", hue: 0.35),
        Preset(name: "Лимон", hue: 0.16), Preset(name: "Оранж", hue: 0.07),
        Preset(name: "Красный", hue: 0.0), Preset(name: "Розовый", hue: 0.90)
    ]

    @Published var hue: Double { didSet { UserDefaults.standard.set(hue, forKey: "hue") } }
    @Published var mode: Int { didSet { UserDefaults.standard.set(mode, forKey: "mode") } }   // 0 авто 1 светлая 2 тёмная
    @Published var userName: String { didSet { UserDefaults.standard.set(userName, forKey: "name") } }
    @Published var dim: Double { didSet { UserDefaults.standard.set(dim, forKey: "dim") } }
    @Published var onboarded: Bool { didSet { UserDefaults.standard.set(onboarded, forKey: "onb") } }
    @Published var wallpaper: UIImage?

    init() {
        let d = UserDefaults.standard
        hue = d.object(forKey: "hue") as? Double ?? 0.74
        mode = d.integer(forKey: "mode")
        userName = d.string(forKey: "name") ?? ""
        dim = d.object(forKey: "dim") as? Double ?? 0.25
        onboarded = d.bool(forKey: "onb")
        wallpaper = UIImage(contentsOfFile: Self.wallURL.path)
    }

    var scheme: ColorScheme? { mode == 1 ? .light : (mode == 2 ? .dark : nil) }

    static var wallURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("wall.jpg")
    }

    func setWallpaper(_ data: Data) {
        guard let src = UIImage(data: data) else { return }
        let maxSide: CGFloat = 1800
        let k = min(1, maxSide / max(src.size.width, src.size.height))
        let size = CGSize(width: src.size.width * k, height: src.size.height * k)
        let img = UIGraphicsImageRenderer(size: size).image { _ in src.draw(in: CGRect(origin: .zero, size: size)) }
        try? img.jpegData(compressionQuality: 0.85)?.write(to: Self.wallURL)
        wallpaper = img
    }
    func clearWallpaper() {
        try? FileManager.default.removeItem(at: Self.wallURL)
        wallpaper = nil
    }

    private func pair(_ l: (Double, Double), _ d: (Double, Double), dh: Double = 0) -> Color {
        let h0 = hue + dh
        let h = h0 - floor(h0)
        return Color(UIColor { tr in
            let v = tr.userInterfaceStyle == .dark ? d : l
            return UIColor(hue: h, saturation: v.0, brightness: v.1, alpha: 1)
        })
    }

    var primary: Color { pair((0.62, 0.65), (0.36, 1.0)) }
    var onPrimary: Color { pair((0.0, 1.0), (0.8, 0.28)) }
    var primaryContainer: Color { pair((0.13, 1.0), (0.62, 0.42)) }
    var onPrimaryContainer: Color { pair((0.95, 0.28), (0.16, 1.0)) }
    var secondaryContainer: Color { pair((0.10, 0.96), (0.28, 0.32)) }
    var onSecondaryContainer: Color { pair((0.60, 0.20), (0.10, 0.95)) }
    var tertiaryContainer: Color { pair((0.18, 1.0), (0.40, 0.38), dh: 0.12) }
    var onTertiaryContainer: Color { pair((0.85, 0.25), (0.16, 1.0), dh: 0.12) }
    var surface: Color { pair((0.03, 0.99), (0.22, 0.09)) }
    var surfaceContainer: Color { pair((0.07, 0.95), (0.22, 0.13)) }
    var surfaceHigh: Color { pair((0.09, 0.91), (0.22, 0.18)) }
    var onSurface: Color { pair((0.15, 0.12), (0.05, 0.93)) }
    var onSurfaceVariant: Color { pair((0.12, 0.36), (0.08, 0.80)) }
    var outline: Color { pair((0.08, 0.50), (0.06, 0.60)) }
    var good: Color { Color(UIColor { $0.userInterfaceStyle == .dark ? UIColor(red: 0.51, green: 0.79, blue: 0.58, alpha: 1) : UIColor(red: 0.18, green: 0.49, blue: 0.2, alpha: 1) }) }
    var bad: Color { Color(UIColor { $0.userInterfaceStyle == .dark ? UIColor(red: 0.95, green: 0.72, blue: 0.71, alpha: 1) : UIColor(red: 0.7, green: 0.15, blue: 0.12, alpha: 1) }) }
}

// MARK: Liquid Glass (iOS 26 — настоящий, ниже — стеклянный материал)
extension View {
    @ViewBuilder
    func glass(_ radius: CGFloat = 28) -> some View {
        #if compiler(>=6.2)
        if #available(iOS 26.0, *) {
            self.glassEffect(.regular, in: RoundedRectangle(cornerRadius: radius, style: .continuous))
        } else {
            self.glassFallback(radius)
        }
        #else
        self.glassFallback(radius)
        #endif
    }

    func glassFallback(_ r: CGFloat) -> some View {
        self.background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: r, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: r, style: .continuous)
                    .strokeBorder(LinearGradient(colors: [.white.opacity(0.55), .white.opacity(0.05)],
                                                 startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.12), radius: 18, y: 8)
    }

    func reveal(_ delay: Double = 0) -> some View { modifier(Reveal(delay: delay)) }
}

struct Reveal: ViewModifier {
    let delay: Double
    @State private var on = false
    func body(content: Content) -> some View {
        content
            .opacity(on ? 1 : 0)
            .offset(y: on ? 0 : 26)
            .scaleEffect(on ? 1 : 0.95)
            .onAppear { withAnimation(.spring(response: 0.65, dampingFraction: 0.8).delay(delay)) { on = true } }
    }
}

func tap(_ s: UIImpactFeedbackGenerator.FeedbackStyle = .light) {
    UIImpactFeedbackGenerator(style: s).impactOccurred()
}

struct PillButton: ButtonStyle {
    @EnvironmentObject var t: Theme
    var filled = true
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 15, weight: .semibold))
            .padding(.horizontal, 26).frame(height: 46)
            .foregroundStyle(filled ? t.onPrimary : t.onSecondaryContainer)
            .background(filled ? t.primary : t.secondaryContainer, in: Capsule())
            .scaleEffect(configuration.isPressed ? 0.94 : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}
