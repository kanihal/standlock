import Foundation
import StandLockCore

/// Durations, rather than a process clock deadline, survive termination.
public struct InterruptedBreak: Codable, Sendable {
    public var event: BreakEvent
    public var remainingDuration: TimeInterval
    public var longestRestDuration: TimeInterval
    public var canPostpone: Bool
    public var exercise: Exercise?
    public var isPostponed: Bool

    public init(event: BreakEvent, remainingDuration: TimeInterval,
                longestRestDuration: TimeInterval = 0, canPostpone: Bool = true,
                exercise: Exercise? = nil, isPostponed: Bool = false) {
        self.event = event
        self.remainingDuration = min(event.duration, max(0, remainingDuration))
        self.longestRestDuration = max(0, longestRestDuration)
        self.canPostpone = canPostpone
        self.exercise = exercise
        self.isPostponed = isPostponed
    }
}
