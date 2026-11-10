import Foundation

public enum SystemTerminationReason: String, Codable, Sendable {
    case ordinaryQuit, shutdown, restart, logout, systemQuitAll, relaunch

    public var canCreditPoweredOffRest: Bool { self == .shutdown || self == .restart }

    public func allowsTermination(hasUnfinishedBreak: Bool) -> Bool {
        self != .ordinaryQuit || !hasUnfinishedBreak
    }
}
