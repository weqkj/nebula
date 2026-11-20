import SwiftUI
import UIKit

struct M3Palette: Identifiable, Equatable {
    let id: String
    let name: String
    let primary: Color
    let onPrimary: Color
    let primaryContainer: Color
    let onPrimaryContainer: Color
    let tertiary: Color
    let onTertiary: Color

    static let all: [M3Palette] = [
        M3Palette(id: "cobalt", name: "Кобальт",
                  primary: Color(red: 0.71, green: 0.78, blue: 1.00),
                  onPrimary: Color(red: 0.06, green: 0.15, blue: 0.34),
                  primaryContainer: Color(red: 0.15, green: 0.25, blue: 0.49),
                  onPrimaryContainer: Color(red: 0.86, green: 0.90, blue: 1.00),
                  tertiary: Color(red: 0.95, green: 0.75, blue: 0.47),
                  onTertiary: Color(red: 0.25, green: 0.16, blue: 0.00)),
        M3Palette(id: "sage", name: "Шалфей",
                  primary: Color(red: 0.65, green: 0.86, blue: 0.72),
                  onPrimary: Color(red: 0.04, green: 0.22, blue: 0.12),
                  primaryContainer: Color(red: 0.11, green: 0.31, blue: 0.20),
                  onPrimaryContainer: Color(red: 0.80, green: 0.95, blue: 0.85),
                  tertiary: Color(red: 0.68, green: 0.82, blue: 0.96),
                  onTertiary: Color(red: 0.05, green: 0.19, blue: 0.31)),
        M3Palette(id: "terracotta", name: "Терракот",
                  primary: Color(red: 1.00, green: 0.71, blue: 0.65),
                  onPrimary: Color(red: 0.36, green: 0.09, blue: 0.06),
                  primaryContainer: Color(red: 0.48, green: 0.18, blue: 0.14),
                  onPrimaryContainer: Color(red: 1.00, green: 0.85, blue: 0.82),
                  tertiary: Color(red: 0.96, green: 0.82, blue: 0.56),
                  onTertiary: Color(red: 0.26, green: 0.18, blue: 0.00)),
        M3Palette(id: "plum", name: "Слива",
                  primary: Color(red: 0.85, green: 0.73, blue: 1.00),
                  onPrimary: Color(red: 0.23, green: 0.11, blue: 0.38),
                  primaryContainer: Color(red: 0.32, green: 0.20, blue: 0.48),
                  onPrimaryContainer: Color(red: 0.93, green: 0.87, blue: 1.00),
                  tertiary: Color(red: 0.98, green: 0.71, blue: 0.80),
                  onTertiary: Color(red: 0.31, green: 0.08, blue: 0.17)),
        M3Palette(id: "sand", name: "Песок",
                  primary: Color(red: 0.93, green: 0.78, blue: 0.51),
                  onPrimary: Color(red: 0.26, green: 0.17, blue: 0.00),
                  primaryContainer: Color(red: 0.36, green: 0.26, blue: 0.07),
                  onPrimaryContainer: Color(red: 1.00, green: 0.89, blue: 0.71),
                  tertiary: Color(red: 0.72, green: 0.83, blue: 0.71),
                  onTertiary: Color(red: 0.12, green: 0.22, blue: 0.12))
    ]
}

final class ThemeEngine: ObservableObject {
    @Published var palette: M3Palette = M3Palette.all[0]
    @Published var isLightMode: Bool = false
    @Published var wallpaperImage: UIImage? = nil
    @Published var solidPresetIndex: Int = 0
    @Published var screenBlur: CGFloat = 0

    let solidPresets: [Color] = [
        Color(red: 0.07, green: 0.09, blue: 0.13),
        Color(red: 0.06, green: 0.11, blue: 0.09),
        Color(red: 0.13, green: 0.08, blue: 0.08),
        Color(red: 0.10, green: 0.08, blue: 0.15)
    ]

    var backgroundColor: Color {
        isLightMode ? Color(red: 0.96, green: 0.96, blue: 0.98) : solidPresets[solidPresetIndex]
    }
    var surfaceColor: Color {
        isLightMode ? Color.white.opacity(0.86) : Color(red: 0.11, green: 0.12, blue: 0.15).opacity(0.84)
    }
    var onSurface: Color {
        isLightMode ? Color(red: 0.11, green: 0.12, blue: 0.14) : Color(red: 0.95, green: 0.95, blue: 0.97)
    }
    var onSurfaceMuted: Color {
        onSurface.opacity(0.62)
    }
}
