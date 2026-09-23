// Renders the macOS app's views to PNG for the README.
// Usage (from repo root): scripts/screenshots.sh
import SwiftUI
import AppKit

@main struct Snapshot {
    @MainActor static func main() {
        _ = NSApplication.shared
        let out = CommandLine.arguments[1]
        let m = TimerModel.shared
        m.loadDemo()
        for scheme in [ColorScheme.light, .dark] {
            let name = scheme == .dark ? "dark" : "light"
            let appearance = NSAppearance(named: scheme == .dark ? .darkAqua : .aqua)!
            appearance.performAsCurrentDrawingAppearance {
                save(MainView(scrollingRail: false).environmentObject(m).frame(width: 1040, height: 720)
                        .environment(\.colorScheme, scheme), "\(out)/macos-\(name).png")
                save(MenuPanel().environmentObject(m).environment(\.colorScheme, scheme)
                        .clipShape(RoundedRectangle(cornerRadius: 14)), "\(out)/macos-menubar-\(name).png")
            }
        }
    }

    @MainActor static func save<V: View>(_ v: V, _ path: String) {
        let r = ImageRenderer(content: v)
        r.scale = 2
        guard let img = r.nsImage, let tiff = img.tiffRepresentation,
              let png = NSBitmapImageRep(data: tiff)?.representation(using: .png, properties: [:]) else { return }
        try! png.write(to: URL(fileURLWithPath: path))
        print("wrote \(path)")
    }
}
