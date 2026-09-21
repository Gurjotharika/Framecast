import AppKit
import SwiftUI

/// Keeps the access window sized to its content, then opens the workspace to a real editor size.
struct AccessWindowFit: NSViewRepresentable {
    var isCompact: Bool

    func makeNSView(context: Context) -> NSView {
        NSView()
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        DispatchQueue.main.async {
            Self.apply(isCompact: isCompact, to: nsView.window)
        }
    }

    static func apply(isCompact: Bool, to window: NSWindow?) {
        guard let window else { return }

        if isCompact {
            window.styleMask.remove(.resizable)
            let fitting = window.contentView?.fittingSize ?? .zero
            let size = NSSize(
                width: max(fitting.width, 420),
                height: max(fitting.height, 360)
            )
            window.contentMinSize = size
            window.contentMaxSize = size
            let current = window.contentRect(forFrameRect: window.frame).size
            if abs(current.width - size.width) > 2 || abs(current.height - size.height) > 2 {
                window.setContentSize(size)
            }
            return
        }

        window.styleMask.insert(.resizable)
        window.contentMinSize = NSSize(width: 1100, height: 720)
        window.contentMaxSize = NSSize(
            width: CGFloat.greatestFiniteMagnitude,
            height: CGFloat.greatestFiniteMagnitude
        )
        if window.frame.width < 1100 || window.frame.height < 720 {
            window.setContentSize(NSSize(width: 1440, height: 900))
            window.center()
        }
    }
}
