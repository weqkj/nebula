import SwiftUI
import UIKit

private func dyn(_ light: UInt, _ dark: UInt) -> Color {
    Color(UIColor { $0.userInterfaceStyle == .dark ? UIColor(hex: dark) : UIColor(hex: light) })
}
extension UIColor {
    convenience init(hex: UInt) {
        self.init(red: CGFloat((hex >> 16) & 0xFF) / 255, green: CGFloat((hex >> 8) & 0xFF) / 255,
                  blue: CGFloat(hex & 0xFF) / 255, alpha: 1)
    }
}

/// Material 3 baseline tonal scheme (light / dark)
enum M3 {
    static let primary            = dyn(0x6750A4, 0xD0BCFF)
    static let onPrimary          = dyn(0xFFFFFF, 0x381E72)
    static let primaryContainer   = dyn(0xEADDFF, 0x4F378B)
    static let onPrimaryContainer = dyn(0x21005D, 0xEADDFF)
    static let secondaryContainer = dyn(0xE8DEF8, 0x4A4458)
    static let onSecondaryContainer = dyn(0x1D192B, 0xE8DEF8)
    static let tertiaryContainer  = dyn(0xFFD8E4, 0x633B48)
    static let onTertiaryContainer = dyn(0x31111D, 0xFFD8E4)
    static let surface            = dyn(0xFEF7FF, 0x141218)
    static let surfaceContainer   = dyn(0xF3EDF7, 0x211F26)
    static let surfaceContainerHigh = dyn(0xECE6F0, 0x2B2930)
    static let onSurface          = dyn(0x1D1B20, 0xE6E0E9)
    static let onSurfaceVariant   = dyn(0x49454F, 0xCAC4D0)
    static let outline            = dyn(0x79747E, 0x938F99)
    static let success            = dyn(0x2E7D32, 0x81C995)
    static let error              = dyn(0xB3261E, 0xF2B8B5)
}

struct M3Card<Content: View>: View {
    var color: Color = M3.surfaceContainer
    var radius: CGFloat = 28
    @ViewBuilder var content: Content
    var body: some View {
        content.padding(20).frame(maxWidth: .infinity, alignment: .leading)
            .background(color, in: RoundedRectangle(cornerRadius: radius, style: .continuous))
    }
}

struct TonalButtonStyle: ButtonStyle {
    var filled = false
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 14, weight: .semibold))
            .padding(.horizontal, 24).frame(height: 40)
            .foregroundStyle(filled ? M3.onPrimary : M3.onSecondaryContainer)
            .background(filled ? M3.primary : M3.secondaryContainer, in: Capsule())
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
    }
}
