import SwiftUI
import AppKit

/// Wraps `NSVisualEffectView` for true window vibrancy where SwiftUI's
/// `.ultraThinMaterial` isn't enough (e.g. a sidebar that samples the desktop
/// behind the window). Use sparingly — `.ultraThinMaterial` covers most cases.
struct VisualEffectView: NSViewRepresentable {
    var material: NSVisualEffectView.Material = .sidebar
    var blendingMode: NSVisualEffectView.BlendingMode = .behindWindow

    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = .active
        return view
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
    }
}
