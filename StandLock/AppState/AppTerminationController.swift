import AppKit
import Detection
import Coordination
import StandLockCore

/// Owns an asynchronous quit confirmation so its original system-exit reason is not lost.
@MainActor
final class AppTerminationController {
    static let shared = AppTerminationController()
    weak var coordinator: AppCoordinator?
    private var session = TerminationSession()

    func shouldTerminate(_ application: NSApplication) -> NSApplication.TerminateReply {
        if session.pendingReason != nil { return .terminateLater }
        let reason: SystemTerminationReason = PermissionChecker.isRelaunching ? .relaunch : QuitReasonReader.currentReason
        guard reason.allowsTermination(hasUnfinishedBreak: coordinator?.hasUnfinishedBreak == true) else {
            return .terminateCancel
        }
        if reason == .relaunch {
            coordinator?.prepareForTermination(reason: reason)
            return .terminateNow
        }
        coordinator?.suspendForTerminationPrompt()
        for window in application.windows {
            guard let delegate = window.delegate as? SettingsWindowDelegate else { continue }
            if !delegate.navigation.shouldQuit(window) {
                _ = session.request(reason, hasUnfinishedBreak: coordinator?.hasUnfinishedBreak == true,
                                    hasUnsavedEdits: true)
                return .terminateLater
            }
        }
        coordinator?.prepareForTermination(reason: reason)
        return .terminateNow
    }

    func confirmQuit() {
        guard let reason = session.finish(confirmed: true) else { return }
        coordinator?.prepareForTermination(reason: reason)
        NSApp.reply(toApplicationShouldTerminate: true)
    }

    func cancelQuit() {
        guard session.pendingReason != nil else { return }
        _ = session.finish(confirmed: false)
        NSApp.reply(toApplicationShouldTerminate: false)
        DispatchQueue.main.async { [weak self] in self?.coordinator?.resumeAfterTerminationPrompt() }
    }
}
