import AppKit
import Combine

final class EmergencyComboMonitor: ObservableObject, @unchecked Sendable {
    var onActivated: (@MainActor () -> Void)?
    var onDeactivated: (@MainActor () -> Void)?
    private var localToken: Any?
    private var globalToken: Any?

    func start() {
        guard localToken == nil else { return }
        let required: NSEvent.ModifierFlags = [.control, .option, .command]

        localToken = NSEvent.addLocalMonitorForEvents(matching: .flagsChanged) { [weak self] event in
            let matched = event.modifierFlags.intersection(required) == required
            Task { @MainActor [weak self] in
                matched ? self?.onActivated?() : self?.onDeactivated?()
            }
            return event
        }

        // Global monitor catches flagsChanged when the app isn't the active app.
        // flagsChanged does not require Input Monitoring permission.
        globalToken = NSEvent.addGlobalMonitorForEvents(matching: .flagsChanged) { [weak self] event in
            let matched = event.modifierFlags.intersection(required) == required
            DispatchQueue.main.async { [weak self] in
                matched ? self?.onActivated?() : self?.onDeactivated?()
            }
        }
    }

    func stop() {
        if let t = localToken { NSEvent.removeMonitor(t) }
        if let t = globalToken { NSEvent.removeMonitor(t) }
        localToken = nil
        globalToken = nil
    }

    deinit {
        if let t = localToken { NSEvent.removeMonitor(t) }
        if let t = globalToken { NSEvent.removeMonitor(t) }
    }
}
