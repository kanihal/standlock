import AppKit
import SwiftUI
import WebKit
import StandLockCore

/// Exercises the actual window controller and view with an isolated preferences suite.
@main
struct MathChallengeWindowRegression {
    @MainActor private static func updateUI() {
        let deadline = Date().addingTimeInterval(0.2)
        while Date() < deadline {
            if let event = NSApp.nextEvent(matching: .any, until: Date().addingTimeInterval(0.02), inMode: .default, dequeue: true) {
                NSApp.sendEvent(event)
            }
            RunLoop.current.run(until: Date().addingTimeInterval(0.01))
            NSApp.updateWindows()
        }
    }

    @MainActor static func main() throws {
        let app = NSApplication.shared
        app.setActivationPolicy(.accessory)
        app.finishLaunching()
        let suite = "standlock.math-window-regression." + UUID().uuidString
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        let schedule = Schedule(name: "Math Window Regression", days: .weekdays, windows: [], breakInterval: 2400, breakDuration: 600)
        let initialQuestion = MathProblemCatalog.problem(topic: .linearAlgebra, index: 19,
            parameters: MathParameters([2,3,4,5,6,7,8,9]))
        var initialSession = MathUnlockSession(now: Date())
        initialSession.install(initialQuestion)
        var initialRecord = ScheduleEditLockRecord()
        initialRecord.session = initialSession
        defaults.set(try JSONEncoder().encode(initialRecord), forKey: "scheduleEditLock." + schedule.id.uuidString)
        let store = ScheduleEditLockStore(defaults: defaults)
        let language = LanguageStore(defaults: defaults)
        let controller = MathChallengeWindowController(store: store, languageStore: language)
        controller.open(schedule)
        updateUI()
        guard let window = app.windows.first(where: { $0.title.contains(schedule.name) }) else {
            fatalError("Challenge window did not open")
        }
        let activationDeadline = Date().addingTimeInterval(5)
        while !window.isKeyWindow && Date() < activationDeadline { updateUI() }
        precondition(window.isKeyWindow, "Challenge should receive focus (active=\(app.isActive), visible=\(window.isVisible), policy=\(app.activationPolicy().rawValue))")
        let original = store.records[schedule.id]?.session?.problem?.id
        precondition(original != nil)

        // Native notifications must pause for another window in the same app.
        let other = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 300, height: 200), styleMask: [.titled], backing: .buffered, defer: false)
        other.isReleasedWhenClosed = false
        other.makeKeyAndOrderFront(nil)
        updateUI()
        precondition(store.records[schedule.id]?.session?.isPaused == true)
        controller.open(schedule)
        updateUI()
        precondition(store.records[schedule.id]?.session?.problem?.id == original, "A short window switch must preserve the question")
        precondition(store.records[schedule.id]?.session?.isPaused == true, "Focus alone must not resume")

        // A real local input event resumes the focused window without Input Monitoring.
        guard let event = NSEvent.keyEvent(with: .keyDown, location: .zero, modifierFlags: [], timestamp: 0,
                                          windowNumber: window.windowNumber, context: nil,
                                          characters: "x", charactersIgnoringModifiers: "x", isARepeat: false, keyCode: 7) else {
            fatalError("Cannot create local event")
        }
        app.sendEvent(event)
        updateUI()
        precondition(store.records[schedule.id]?.session?.isPaused == false)

        // Verify actual native layout, not just that TeX-looking text reached a view.
        guard let webView = window.contentView.flatMap({ mathViews(in: $0).first }) else {
            fatalError("Missing native math view")
        }
        var metrics: [NSNumber]?
        var browserError: Error?
        let layoutDeadline = Date().addingTimeInterval(8)
        while metrics == nil && browserError == nil && Date() < layoutDeadline {
            updateUI()
            if webView.isLoading { continue }
            webView.evaluateJavaScript("[document.querySelectorAll('math').length,document.querySelectorAll('mfrac').length,document.querySelectorAll('mtable').length,Array.from(document.querySelectorAll('math')).some(x=>x.getBoundingClientRect().height>20)?1:0]") { value, error in
                metrics = value as? [NSNumber]
                browserError = error
            }
            updateUI()
        }
        precondition(browserError == nil, "Math document evaluation failed")
        guard let metrics, metrics.count == 4 else { fatalError("Math document did not load") }
        precondition(metrics.allSatisfy { $0.intValue > 0 }, "Fractions and matrices must be laid out as native MathML")
        var snapshot: NSImage?
        webView.takeSnapshot(with: nil) { image, _ in snapshot = image }
        let snapshotDeadline = Date().addingTimeInterval(5)
        while snapshot == nil && Date() < snapshotDeadline { updateUI() }
        if let data = snapshot?.tiffRepresentation, let bitmap = NSBitmapImageRep(data: data),
           let png = bitmap.representation(using: .png, properties: [:]) {
            try png.write(to: URL(fileURLWithPath: "/tmp/standlock-math-typeset.png"))
        } else { fatalError("Could not capture typeset question") }

        // Automatic relocking creates a fresh session without changing the key window.
        // Its first real input must establish focus rather than requiring a window switch.
        store.lock(schedule.id)
        store.begin(schedule.id)
        updateUI()
        app.sendEvent(event)
        updateUI()
        precondition(store.records[schedule.id]?.session?.isPaused == false, "A new challenge in the already-key window must resume on input")

        if let view = window.contentView, let bitmap = view.bitmapImageRepForCachingDisplay(in: view.bounds) {
            view.cacheDisplay(in: view.bounds, to: bitmap)
            if let data = bitmap.representation(using: .png, properties: [:]) {
                try data.write(to: URL(fileURLWithPath: "/tmp/standlock-math-challenge.png"))
            }
        }

        for count in 1...15 {
            guard let question = store.records[schedule.id]?.session?.problem else { fatalError("Missing question") }
            let result = store.submit(String(format: "%.17g", question.answer), questionID: question.id, scheduleID: schedule.id)
            precondition(result == (count == 15 ? .completed : .correct))
            updateUI()
        }
        precondition(!store.isLocked(schedule.id))
        guard let saved = defaults.data(forKey: "scheduleEditLock." + schedule.id.uuidString) else {
            fatalError("Unlock was not persisted")
        }
        let restored = ScheduleEditLockRecord.restore(saved, at: store.now)
        precondition(restored?.isLocked(at: store.now) == false)
        precondition(restored?.session == nil)
        window.close()
        other.close()
        if CommandLine.arguments.count > 1 {
            try Data("passed".utf8).write(to: URL(fileURLWithPath: CommandLine.arguments[1]), options: .atomic)
        }
    }

    @MainActor private static func mathViews(in view: NSView) -> [WKWebView] {
        if let webView = view as? WKWebView { return [webView] }
        return view.subviews.flatMap { mathViews(in: $0) }
    }
}
