import SwiftUI
import UIKit

enum AccentTone: String, CaseIterable, Identifiable {
// ... existing code ... -->
        let connection = NWConnection(
            host: NWEndpoint.Host(host),
            port: NWEndpoint.Port(rawValue: port) ?? .https,
            using: .tcp
        )
// ... existing code ... -->
struct WavyMusicBar: View {
    var active: Bool
    var color: Color

    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                let phase: CGFloat = active ? CGFloat(timeline.date.timeIntervalSinceReferenceDate * 4.2) : 0
                let midY = size.height / 2
                let splitX = size.width * (active ? 0.72 : 0.18)
                let amp: CGFloat = active ? 4.5 : 0
// ... existing code ... -->
                .onChange(of: photoItem) { item in
                    Task {
                        if let data = try? await item?.loadTransferable(type: Data.self),
                           let img = UIImage(data: data) {
                            await MainActor.run { theme.customWallpaper = img }
                        }
                    }
                }
            }
        }
    }
}
