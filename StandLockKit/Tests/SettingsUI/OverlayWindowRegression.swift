import AppKit
import CoreGraphics
import StandLockCore

/// Runs the real overlay controller on every connected display with isolated defaults.
@main
struct OverlayWindowRegression {
    private static func require(_ condition: @autoclosure () -> Bool, _ message: String = "Overlay regression check failed") {
        guard condition() else {
            FileHandle.standardError.write(Data((message + "\n").utf8))
            exit(EXIT_FAILURE)
        }
    }

    @MainActor private static func updateUI(for duration: TimeInterval = 0.4) {
        let deadline = Date().addingTimeInterval(duration)
        while Date() < deadline {
            if let event = NSApp.nextEvent(matching: .any, until: Date().addingTimeInterval(0.01), inMode: .default, dequeue: true) {
                NSApp.sendEvent(event)
            }
            RunLoop.current.run(until: Date().addingTimeInterval(0.01))
            NSApp.updateWindows()
        }
    }

    @MainActor private static func assertDisposed(_ windows: [BreakOverlayWindow], closedWindowNumbers: Set<Int>) {
        require(windows.allSatisfy { !$0.isVisible }, "Dismissal must hide every break window")
        require(windows.allSatisfy { closedWindowNumbers.contains($0.windowNumber) },
                     "Dismissal must close every break window, including secondary displays")
        require(windows.allSatisfy { !$0.canBecomeKey && !$0.canBecomeMain },
                     "An empty dismissed overlay must never be a key or main window candidate")
        require(windows.allSatisfy { $0.contentView == nil }, "Dismissal must release the break views")
    }

    @MainActor static func main() throws {
        let app = NSApplication.shared
        app.setActivationPolicy(.accessory)
        app.finishLaunching()
        let suite = "standlock.overlay-regression." + UUID().uuidString
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        let controller = OverlayWindowController(
            languageStore: LanguageStore(defaults: defaults), themeStore: ThemeStore(defaults: defaults)
        )
        defer { controller.dismissOverlay() }
        var closedWindowNumbers: Set<Int> = []
        let observer = NotificationCenter.default.addObserver(
            forName: NSWindow.willCloseNotification, object: nil, queue: .main
        ) { notification in
            MainActor.assumeIsolated {
                if let window = notification.object as? BreakOverlayWindow {
                    closedWindowNumbers.insert(window.windowNumber)
                }
            }
        }
        defer { NotificationCenter.default.removeObserver(observer) }
        var preferences = AppPreferences()
        preferences.pauseMediaDuringBreak = false
        let settings = NSWindow(contentRect: NSRect(x: 100, y: 100, width: 400, height: 300),
                                styleMask: [.titled], backing: .buffered, defer: false)
        settings.isReleasedWhenClosed = false
        defer { settings.close() }

        for policy in [NSApplication.ActivationPolicy.accessory, .regular] {
            app.setActivationPolicy(policy)
            for iteration in 0..<3 {
                settings.makeKeyAndOrderFront(nil)
                controller.showOverlay(
                    level: .gentle, duration: 30, exercise: nil, preferences: preferences,
                    statistics: BreakStatistics(), breakID: UUID(), dismissalAvailability: DismissalAvailability()
                )
                updateUI()
                var shownWindows = app.windows.compactMap { $0 as? BreakOverlayWindow }.filter(\.isVisible)
                require(shownWindows.count == NSScreen.screens.count, "Every display must have one break window")
                require(shownWindows.allSatisfy { $0.canBecomeKey && $0.canBecomeMain })
                if iteration == 0 {
                    // Activation can itself emit a screen-parameters notification;
                    // let the controller's display-change throttle settle first.
                    updateUI(for: 2.1)
                    NotificationCenter.default.post(name: NSApplication.didChangeScreenParametersNotification, object: nil)
                    updateUI()
                    assertDisposed(shownWindows, closedWindowNumbers: closedWindowNumbers)
                    shownWindows = app.windows.compactMap { $0 as? BreakOverlayWindow }.filter(\.isVisible)
                    require(shownWindows.count == NSScreen.screens.count,
                                 "A display change must replace the overlays on every display")
                }
                controller.dismissOverlay()
                updateUI()
                assertDisposed(shownWindows, closedWindowNumbers: closedWindowNumbers)
                require(!controller.isShowing)
                require(app.activationPolicy() == policy)
                let windows = CGWindowListCopyWindowInfo(.optionOnScreenOnly, kCGNullWindowID) as? [[String: Any]] ?? []
                require(!windows.contains {
                    ($0[kCGWindowOwnerPID as String] as? Int) == Int(ProcessInfo.processInfo.processIdentifier)
                        && ($0[kCGWindowLayer as String] as? Int) == Int(NSWindow.Level.screenSaver.rawValue)
                }, "WindowServer still has a visible break window after dismissal")

                NotificationCenter.default.post(name: NSApplication.didChangeScreenParametersNotification, object: nil)
                updateUI()
                require(app.windows.allSatisfy { !($0 is BreakOverlayWindow) || !$0.isVisible },
                             "A display change after dismissal must not bring back a blank break window")
            }
        }
        if CommandLine.arguments.count > 1 {
            try Data("passed".utf8).write(to: URL(fileURLWithPath: CommandLine.arguments[1]), options: .atomic)
        }
    }
}
