import SwiftUI

enum AccentTone: String, CaseIterable, Identifiable {
    case cobalt = "Кобальт"
    case sage = "Шалфей"
    case lavender = "Лаванда"
    case terracotta = "Терракота"
    case sand = "Песок"

    var id: String { rawValue }

    var primary: Color {
        switch self {
        case .cobalt:     return Color(red: 0.71, green: 0.78, blue: 1.00)
        case .sage:       return Color(red: 0.56, green: 0.83, blue: 0.64)
        case .lavender:   return Color(red: 0.82, green: 0.74, blue: 1.00)
        case .terracotta: return Color(red: 0.95, green: 0.72, blue: 0.71)
        case .sand:       return Color(red: 0.92, green: 0.82, blue: 0.60)
        }
    }

    var onPrimary: Color {
        switch self {
        case .cobalt:     return Color(red: 0.06, green: 0.15, blue: 0.34)
        case .sage:       return Color(red: 0.02, green: 0.22, blue: 0.11)
        case .lavender:   return Color(red: 0.21, green: 0.11, blue: 0.44)
        case .terracotta: return Color(red: 0.36, green: 0.08, blue: 0.07)
        case .sand:       return Color(red: 0.24, green: 0.18, blue: 0.02)
        }
    }

    var container: Color {
        primary.opacity(0.24)
    }
}

final class ThemeManager: ObservableObject {
    @AppStorage("nebula_tone") var toneRaw: String = AccentTone.cobalt.rawValue
    @AppStorage("nebula_light") var isLight: Bool = false
    @AppStorage("nebula_screen_blur") var screenBlur: Double = 0
    @Published var customWallpaper: UIImage? = nil

    var tone: AccentTone {
        get { AccentTone(rawValue: toneRaw) ?? .cobalt }
        set {
            toneRaw = newValue.rawValue
            objectWillChange.send()
        }
    }

    static var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12:  return "Доброе\nутро"
        case 12..<18: return "Добрый\nдень"
        case 18..<23: return "Добрый\nвечер"
        default:      return "Доброй\nночи"
        }
    }
}
