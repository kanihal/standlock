import StandLockCore

/// Preserves system-exit intent across a settings sheet without authorizing future quits.
public struct TerminationSession {
    public enum Decision: Equatable { case deny, wait, allow }
    public private(set) var pendingReason: SystemTerminationReason?

    public init() {}

    public mutating func request(_ reason: SystemTerminationReason, hasUnfinishedBreak: Bool,
                                 hasUnsavedEdits: Bool) -> Decision {
        if pendingReason != nil { return .wait }
        guard reason.allowsTermination(hasUnfinishedBreak: hasUnfinishedBreak) else { return .deny }
        if hasUnsavedEdits {
            pendingReason = reason
            return .wait
        }
        return .allow
    }

    public mutating func finish(confirmed: Bool) -> SystemTerminationReason? {
        defer { pendingReason = nil }
        return confirmed ? pendingReason : nil
    }
}
