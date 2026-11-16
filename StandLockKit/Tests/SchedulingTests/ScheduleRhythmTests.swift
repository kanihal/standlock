import Testing
@testable import Scheduling
import StandLockCore

@Suite("One repeating schedule rhythm")
struct ScheduleRhythmTests {
    private func schedule(rule: RepetitionRule? = nil, cycle: [IntervalStep]? = nil) -> Schedule {
        Schedule(name: "Work", days: .everyDay, windows: [.init(startHour: 9, startMinute: 0, endHour: 10, endMinute: 0)],
            breakInterval: 3300, breakDuration: 300, intervalCycle: cycle, repetitionRule: rule)
    }

    @Test func oneCycleEndsAtTheLongBreakEvenWhenTheDayWindowIsShorter() {
        let rhythm = ScheduleRhythm(schedule: schedule(rule: .init(shortBreakCount: 2, shortBreakDuration: 300, longBreakDuration: 900)))
        #expect(rhythm.steps.map(\.kind) == [.work, .shortBreak, .work, .shortBreak, .work, .longBreak])
        #expect(rhythm.steps.map(\.duration) == [3300, 300, 3300, 300, 3300, 900])
        #expect(rhythm.duration == 11400)
        #expect(rhythm.breakCount == 3)
    }

    @Test func withoutLongBreaksThereIsOnlyOneWorkAndOneBreak() {
        let rhythm = ScheduleRhythm(schedule: schedule())
        #expect(rhythm.steps.map(\.kind) == [.work, .shortBreak])
        #expect(rhythm.steps.map(\.duration) == [3300, 300])
    }

    @Test func varyingWorkIntervalsRepeatOnlyWhenBothSequencesReturnToTheirStart() {
        let rhythm = ScheduleRhythm(schedule: schedule(rule: .init(shortBreakCount: 2, shortBreakDuration: 300, longBreakDuration: 900),
            cycle: [.init(duration: 1200), .init(duration: 2400)]))
        #expect(rhythm.steps.filter { $0.kind == .work }.map(\.duration) == [1200, 2400, 1200, 2400, 1200, 2400])
        #expect(rhythm.steps.filter { $0.kind != .work }.map(\.kind) == [.shortBreak, .shortBreak, .longBreak, .shortBreak, .shortBreak, .longBreak])
        #expect(rhythm.breakCount == 6)
    }
}
