import Foundation

/// Saved work and break durations exclude all unobserved time between processes.
public struct BreakRecoveryState: Codable, Sendable {
    public var breaks: [UUID: InterruptedBreak]
    public var remainingWork: [UUID: TimeInterval]
    public var ownerScheduleID: UUID?
    public var pauseDeadline: Date?

    public init(breaks: [UUID: InterruptedBreak] = [:], remainingWork: [UUID: TimeInterval] = [:],
                ownerScheduleID: UUID? = nil, pauseDeadline: Date? = nil) {
        self.breaks = breaks
        self.remainingWork = remainingWork
        self.ownerScheduleID = ownerScheduleID
        self.pauseDeadline = pauseDeadline
    }
}
