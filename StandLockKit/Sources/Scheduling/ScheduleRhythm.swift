import Foundation
import StandLockCore

/// A single repeat of the configured work intervals and short/long break pattern.
public struct ScheduleRhythm: Equatable, Sendable {
    public struct Step: Equatable, Sendable {
        public let kind: DayTimeline.Kind
        public let duration: TimeInterval
        public let breakPosition: Int?
    }
    public let steps: [Step]
    public var duration: TimeInterval { steps.reduce(0) { $0 + $1.duration } }
    public var breakCount: Int { steps.count / 2 }

    public init(schedule: Schedule) {
        let work = schedule.intervalCycle.flatMap { $0.isEmpty ? nil : $0.map(\.duration) } ?? [schedule.breakInterval]
        let shorts = schedule.repetitionRule?.shortBreakCount ?? 0
        guard work.allSatisfy({ $0.isFinite && $0 > 0 }), shorts >= 0, shorts < Int.max else {
            steps = []
            return
        }
        let breakCycle = schedule.repetitionRule == nil ? 1 : shorts + 1
        let product = (work.count / Self.gcd(work.count, breakCycle)).multipliedReportingOverflow(by: breakCycle)
        // Malformed imported schedules must not allocate an unbounded diagram.
        guard !product.overflow, product.partialValue <= 1000 else { steps = []; return }
        let evaluator = ScheduleEvaluator()
        var result: [Step] = []
        for index in 0..<product.partialValue {
            let duration = evaluator.breakDuration(for: schedule, breakIndex: index)
            guard duration.isFinite, duration > 0 else { steps = []; return }
            result.append(Step(kind: .work, duration: work[index % work.count], breakPosition: nil))
            let kind: DayTimeline.Kind = schedule.repetitionRule != nil && index % breakCycle == shorts ? .longBreak : .shortBreak
            result.append(Step(kind: kind, duration: duration, breakPosition: index))
        }
        steps = result
    }

    private static func gcd(_ a: Int, _ b: Int) -> Int {
        var a = a, b = b
        while b != 0 { (a, b) = (b, a % b) }
        return a
    }
}
