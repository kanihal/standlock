import AppKit
import SwiftUI

final class BreakOverlayWindow: NSWindow {
    private var isClosing = false

    convenience init(screen: NSScreen, palette: BreakPalette, appearance: NSAppearance.Name) {
        self.init(
            contentRect: screen.frame,
            styleMask: [.borderless, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        level = .screenSaver
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]
        isOpaque = true
        // Leaving a white default here is what flashed a white frame before a dark
        // overlay drew.
        backgroundColor = NSColor(palette.paper)
        hasShadow = false
        isMovable = false
        hidesOnDeactivate = false
        // ARC owns these windows; close must not schedule an extra AppKit release.
        isReleasedWhenClosed = false
        self.appearance = NSAppearance(named: appearance)
    }

    override var canBecomeKey: Bool { !isClosing }
    override var canBecomeMain: Bool { !isClosing }

    override func close() {
        // AppKit can retain a hidden overlay and choose it as the main window again
        // during display changes. A retired overlay must never receive focus.
        isClosing = true
        super.close()
    }

    func setContent(_ view: some View) {
        let hostingView = NSHostingView(rootView: view)
        hostingView.frame = contentRect(forFrameRect: frame)
        contentView = hostingView
    }
}
