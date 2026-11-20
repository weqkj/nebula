import SwiftUI
import PhotosUI

enum MaterialSeed: String, CaseIterable, Identifiable {
    case cobalt = "Cobalt"
    case sage = "Sage"
    case terracotta = "Terracotta"
    case sand = "Sand"
    case plum = "Plum"
    case slate = "Slate"

    var id: String { rawValue }

    var primary: Color {
        switch self {
        case .cobalt:     return Color(red: 0.54, green: 0.71, blue: 0.97)
        case .sage:       return Color(red: 0.51, green: 0.79, blue: 0.58)
        case .terracotta: return Color(red: 0.95, green: 0.72, blue: 0.71)
        case .sand:       return Color(red: 0.90, green: 0.76, blue: 0.52)
        case .plum:       return Color(red: 0.82, green: 0.74, blue: 1.00)
        case .slate:      return Color(red: 0.80, green: 0.84, blue: 0.88)
        }
    }

    var onPrimary: Color {
        switch self {
        case .cobalt:     return Color(red: 0.02, green: 0.18, blue: 0.44)
        case .sage:       return Color(red: 0.03, green: 0.23, blue: 0.11)
        case .terracotta: return Color(red: 0.38, green: 0.08, blue: 0.06)
        case .sand:       return Color(red: 0.26, green: 0.17, blue: 0.02)
        case .plum:       return Color(red: 0.22, green: 0.12, blue: 0.45)
        case .slate:      return Color(red: 0.12, green: 0.16, blue: 0.23)
        }
    }
}

final class ThemeManager: ObservableObject {
    @AppStorage("nebula_seed") var seedRaw: String = MaterialSeed.cobalt.rawValue
    @AppStorage("nebula_wallpaper_idx") var wallpaperIndex: Int = 0
    @Published var customWallpaper: UIImage? = nil

    var seed: MaterialSeed {
        get { MaterialSeed(rawValue: seedRaw) ?? .cobalt }
        set {
            seedRaw = newValue.rawValue
            objectWillChange.send()
        }
    }

    let presetWallpapers: [LinearGradient] = [
        LinearGradient(colors: [Color(red: 0.05, green: 0.06, blue: 0.09), Color(red: 0.12, green: 0.15, blue: 0.22)], startPoint: .topLeading, endPoint: .bottomTrailing),
        LinearGradient(colors: [Color(red: 0.04, green: 0.07, blue: 0.07), Color(red: 0.09, green: 0.19, blue: 0.17)], startPoint: .topLeading, endPoint: .bottomTrailing),
        LinearGradient(colors: [Color(red: 0.07, green: 0.05, blue: 0.05), Color(red: 0.21, green: 0.14, blue: 0.12)], startPoint: .topTrailing, endPoint: .bottomLeading),
        LinearGradient(colors: [Color(red: 0.05, green: 0.05, blue: 0.07), Color(red: 0.16, green: 0.13, blue: 0.21)], startPoint: .top, endPoint: .bottom)
    ]

    static var timeGreeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12:  return "Доброе утро"
        case 12..<18: return "Добрый день"
        case 18..<23: return "Добрый вечер"
        default:      return "Доброй ночи"
        }
    }
}
