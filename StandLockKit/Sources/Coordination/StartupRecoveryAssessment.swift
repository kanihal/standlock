import Foundation
import StandLockCore
import Detection

public enum StartupRecoveryAssessment: Equatable, Sendable {
    case preserveProgress
    case verifiedRest(TimeInterval)
    case inferredInterruption(TimeInterval)

    public static func assess(checkpoint: CoordinatorCheckpoint, current: BootObservation?,
                              now: Date, history: [SystemLifecycleEvent]) -> Self {
        guard let current, valid(current, at: now),
              checkpoint.savedAt.timeIntervalSinceReferenceDate.isFinite,
              checkpoint.observation?.boot.id != current.boot.id else { return .preserveProgress }
        if let exit = checkpoint.exit,
           let duration = ShutdownRestVerifier.duration(after: exit, currentBoot: current.boot, history: history) {
            return .verifiedRest(duration)
        }
        guard let previous = checkpoint.observation, valid(previous, at: checkpoint.savedAt),
              previous.boot.startedAt < current.boot.startedAt,
              checkpoint.savedAt < current.boot.startedAt,
              history.allSatisfy({ $0.date.timeIntervalSinceReferenceDate.isFinite }) else { return .preserveProgress }
        let relevant = history.filter { $0.date >= previous.boot.startedAt
            && $0.date <= current.boot.startedAt.addingTimeInterval(120) }
        guard !relevant.contains(where: { $0.kind == .clockChange }),
              zip(relevant, relevant.dropFirst()).allSatisfy({ $0.date <= $1.date }) else { return .preserveProgress }
        // Stop at the first subsequent boot, even if StandLock was not launched until much later.
        let firstBoot = relevant.first { $0.kind == .boot && $0.date > checkpoint.savedAt }?.date
            ?? current.boot.startedAt
        let duration = firstBoot.timeIntervalSince(checkpoint.savedAt) - ActivityCheckpointCadence.interval
        return duration > 0 ? .inferredInterruption(duration) : .preserveProgress
    }

    public func applying(to state: EnforcementState, schedules: [Schedule]) -> EnforcementState {
        guard case .inferredInterruption(let duration) = self, duration.isFinite, duration > 0,
              state.runtime == nil else { return state }
        var result = state
        for schedule in schedules {
            guard let rule = schedule.repetitionRule, rule.longBreakDuration.isFinite,
                  rule.longBreakDuration > 0, duration >= rule.longBreakDuration else { continue }
            result.repetitionIndices[schedule.id] = 0
            result.cycleIndices[schedule.id] = 0
            result.pendingBreakDates.removeValue(forKey: schedule.id)
            result.recovery?.remainingWork.removeValue(forKey: schedule.id)
        }
        return result
    }

    private static func valid(_ observation: BootObservation, at date: Date) -> Bool {
        let wallElapsed = date.timeIntervalSince(observation.boot.startedAt)
        return !observation.boot.id.isEmpty && wallElapsed.isFinite && wallElapsed >= 0
            && observation.continuousTime.isFinite && observation.continuousTime >= 0
            && abs(wallElapsed - observation.continuousTime) <= 120
    }
}
