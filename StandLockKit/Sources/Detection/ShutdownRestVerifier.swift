import Foundation
import StandLockCore

public enum ShutdownRestVerifier {
    /// Accounting order, oldest first: sorting by dates would conceal clock changes.
    public static func duration(after exit: SystemExitRecord, currentBoot: SystemBoot,
                                history: [SystemLifecycleEvent]) -> TimeInterval? {
        guard exit.reason.canCreditPoweredOffRest, exit.boot.id != currentBoot.id,
              exit.boot.startedAt <= exit.requestedAt, exit.requestedAt < currentBoot.startedAt,
              let previousBoot = history.lastIndex(where: {
                  $0.kind == .boot && abs($0.date.timeIntervalSince(exit.boot.startedAt)) <= 120
                    && $0.date <= exit.requestedAt
              }) else { return nil }
        let following = history.suffix(from: previousBoot + 1)
        guard let nextBoot = following.firstIndex(where: { $0.kind == .boot }) else { return nil }
        let ending = history[nextBoot].date
        let between = history[(previousBoot + 1)..<nextBoot]
        guard !between.contains(where: { $0.kind == .clockChange }),
              let shutdown = between.last(where: { $0.kind == .shutdown }),
              exit.requestedAt <= shutdown.date, shutdown.date < ending,
              ending <= currentBoot.startedAt.addingTimeInterval(120) else { return nil }
        return ending.timeIntervalSince(shutdown.date)
    }
}
