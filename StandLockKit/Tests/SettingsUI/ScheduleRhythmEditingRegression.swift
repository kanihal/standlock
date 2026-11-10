import AppKit
import SwiftUI
import StandLockCore

/// Runs against the app's actual controls. Use `bash StandLockKit/Tests/SettingsUI/run.sh`.
@main
struct ScheduleRhythmEditingRegression {
    @MainActor
    private final class Model: ObservableObject {
        @Published var draft: ScheduleDraft = {
            var draft = ScheduleDraft(schedule: nil)
            draft.name = "Regression"
            draft.useRepetition = true
            draft.shortBreakMinutes = 5
            draft.longBreakMinutes = 30
            return draft
        }()
    }

    private struct Root: View {
        @ObservedObject var model: Model

        var body: some View {
            ScheduleRhythmSection(draft: $model.draft)
                .padding()
                .frame(width: 900)
        }
    }

    @MainActor
    private static func updateUI() {
        RunLoop.current.run(until: Date().addingTimeInterval(0.15))
    }

    @MainActor
    private static func fields(in view: NSView) -> [NSTextField] {
        (view as? NSTextField).map { [$0] } ?? view.subviews.flatMap { fields(in: $0) }
    }

    @MainActor
    private static func replace(_ text: String, in editor: NSTextView) {
        editor.selectAll(nil)
        editor.insertText(text, replacementRange: editor.selectedRange())
        updateUI()
    }

    @MainActor
    static func main() {
        let app = NSApplication.shared
        app.setActivationPolicy(.accessory)
        let model = Model()
        let host = NSHostingView(rootView: Root(model: model))
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 920, height: 400),
            styleMask: [.titled], backing: .buffered, defer: false
        )
        window.contentView = host
        window.makeKeyAndOrderFront(nil)
        app.activate(ignoringOtherApps: true)
        updateUI()
        host.layoutSubtreeIfNeeded()

        // Each numeric control has a distinct value in this fixture.
        let controls = fields(in: host)
        guard let longerBreak = controls.first(where: { $0.stringValue == "30" }),
              let shortBreak = controls.first(where: { $0.stringValue == "5" }),
              let work = controls.first(where: { $0.stringValue == "40" }),
              let count = controls.first(where: { $0.stringValue == "3" })
        else { fatalError("Missing rhythm controls") }

        window.makeFirstResponder(longerBreak)
        updateUI()
        guard let editor = longerBreak.currentEditor() as? NSTextView else { fatalError("Missing editor") }
        replace("1", in: editor)
        precondition(editor.string == "1", "Do not replace the first digit of 15 with the minimum of 5")
        editor.insertText("5", replacementRange: editor.selectedRange())
        updateUI()
        precondition(editor.string == "15")
        window.makeFirstResponder(shortBreak)
        updateUI()
        precondition(model.draft.longBreakMinutes == 15)

        guard let shortEditor = shortBreak.currentEditor() as? NSTextView else { fatalError("Missing short-break editor") }
        replace("0", in: shortEditor)
        precondition(shortEditor.string == "0", "Allow the leading zero of a fractional minute")
        shortEditor.insertText(".5", replacementRange: shortEditor.selectedRange())
        updateUI()
        window.makeFirstResponder(work)
        updateUI()
        precondition(model.draft.rhythmBreakMinutes == 0.5)

        guard let workEditor = work.currentEditor() as? NSTextView else { fatalError("Missing work editor") }
        replace("999", in: workEditor)
        precondition(workEditor.string == "999", "Do not correct an unfinished integer")
        window.makeFirstResponder(count)
        updateUI()
        precondition(model.draft.intervalRows[0].minutes == 180, "Clamp on focus loss")

        guard let countEditor = count.currentEditor() as? NSTextView else { fatalError("Missing count editor") }
        replace("0", in: countEditor)
        precondition(countEditor.string == "0")
        countEditor.doCommand(by: #selector(NSResponder.insertNewline(_:)))
        updateUI()
        precondition(model.draft.shortBreakCount == 1, "Clamp integers on Return")

        window.makeFirstResponder(longerBreak)
        updateUI()
        guard let finalEditor = longerBreak.currentEditor() as? NSTextView else { fatalError("Missing final editor") }
        replace("1", in: finalEditor)
        finalEditor.doCommand(by: #selector(NSResponder.insertNewline(_:)))
        updateUI()
        precondition(model.draft.longBreakMinutes == 5, "Clamp minutes on Return")
        window.close()
    }
}
