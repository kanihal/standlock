import AppKit
import SwiftUI
import StandLockCore

/// One reusable native window; key-window state, rather than app activation alone,
/// distinguishes solving from switching to Settings or another StandLock window.
@MainActor
final class MathChallengeWindowController: NSObject, NSWindowDelegate {
    private let store: ScheduleEditLockStore
    private let languageStore: LanguageStore
    private var window: NSWindow?
    private var scheduleID: UUID?
    private var eventMonitor: Any?
    private var observers: [NSObjectProtocol] = []
    private var suspendedReasons: Set<String> = []

    init(store: ScheduleEditLockStore, languageStore: LanguageStore) {
        self.store = store
        self.languageStore = languageStore
        super.init()
    }

    func open(_ schedule: Schedule) {
        if let previous = scheduleID, previous != schedule.id { store.focus(false, scheduleID: previous) }
        let changedSchedule = scheduleID != schedule.id
        scheduleID = schedule.id
        store.begin(schedule.id)
        if window == nil {
            let created = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 720, height: 740),
                styleMask: [.titled, .closable, .miniaturizable, .resizable],
                backing: .buffered, defer: false
            )
            created.contentMinSize = NSSize(width: 580, height: 620)
            created.isReleasedWhenClosed = false
            created.acceptsMouseMovedEvents = true
            created.delegate = self
            created.center()
            window = created
            observeActivity()
        }
        if changedSchedule || window?.contentView == nil {
            window?.contentView = NSHostingView(rootView: LocalizedRoot(store: languageStore) {
                MathChallengeView(scheduleID: schedule.id, scheduleName: schedule.name, store: self.store)
            })
        }
        window?.title = languageStore.string("Unlock Schedule") + " — " + schedule.name
        window?.deminiaturize(nil)
        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        refreshFocus()
    }

    func windowDidBecomeKey(_ notification: Notification) { refreshFocus() }
    func windowDidResignKey(_ notification: Notification) { refreshFocus() }
    func windowDidMiniaturize(_ notification: Notification) { refreshFocus() }
    func windowWillClose(_ notification: Notification) {
        if let scheduleID { store.focus(false, scheduleID: scheduleID) }
    }

    private var hasFocus: Bool {
        suspendedReasons.isEmpty && NSApp.isActive && window?.isKeyWindow == true
            && window?.isVisible == true && window?.isMiniaturized == false
    }

    private func refreshFocus() {
        if let scheduleID { store.focus(hasFocus, scheduleID: scheduleID) }
    }

    private func observeActivity() {
        eventMonitor = NSEvent.addLocalMonitorForEvents(matching: [
            .keyDown, .leftMouseDown, .rightMouseDown, .otherMouseDown, .scrollWheel,
            .mouseMoved, .leftMouseDragged, .rightMouseDragged, .otherMouseDragged
        ]) { [weak self] event in
            guard let self, event.window === self.window, self.hasFocus, let id = self.scheduleID else { return event }
            // Expiry may have created a session while this window stayed key, so there
            // was no new windowDidBecomeKey notification to initialize its focus.
            if self.store.records[id]?.session?.isFocused == false {
                self.store.focus(true, scheduleID: id)
            }
            // Submit itself reconciles the break against its captured question ID. Do not
            // replace that question before Return's action has inspected the old input.
            if event.type != .keyDown || ![36, 76].contains(event.keyCode) {
                self.store.interact(scheduleID: id)
            }
            return event
        }
        let center = NotificationCenter.default
        for name in [NSApplication.didResignActiveNotification, NSApplication.didBecomeActiveNotification] {
            observers.append(center.addObserver(forName: name, object: nil, queue: .main) { [weak self] _ in
                MainActor.assumeIsolated { self?.refreshFocus() }
            })
        }
        observers.append(center.addObserver(forName: NSApplication.willTerminateNotification, object: nil, queue: .main) { [weak self] _ in
            MainActor.assumeIsolated { self?.store.pauseAll() }
        })
        observeSuspension(NSWorkspace.shared.notificationCenter, name: NSWorkspace.willSleepNotification, reason: "sleep", suspended: true)
        observeSuspension(NSWorkspace.shared.notificationCenter, name: NSWorkspace.didWakeNotification, reason: "sleep", suspended: false)
        observeSuspension(DistributedNotificationCenter.default(), name: .init("com.apple.screenIsLocked"), reason: "screen", suspended: true)
        observeSuspension(DistributedNotificationCenter.default(), name: .init("com.apple.screenIsUnlocked"), reason: "screen", suspended: false)
    }

    private func observeSuspension(_ center: NotificationCenter, name: Notification.Name, reason: String, suspended: Bool) {
        observers.append(center.addObserver(forName: name, object: nil, queue: .main) { [weak self] _ in
            MainActor.assumeIsolated {
                guard let self else { return }
                if suspended { self.suspendedReasons.insert(reason) }
                else { self.suspendedReasons.remove(reason) }
                self.refreshFocus()
            }
        })
    }
}
