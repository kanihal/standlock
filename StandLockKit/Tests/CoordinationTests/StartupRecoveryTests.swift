import Foundation
import Testing
@testable import Coordination
import Detection
import Scheduling
import StandLockCore

@Suite("Boot-aware startup recovery")
@MainActor
struct StartupRecoveryTests {
    private let origin = Date(timeIntervalSince1970: 1_800_000_000)
    private func date(_ seconds: Double) -> Date { origin.addingTimeInterval(seconds) }
    private func observation(_ id: String, boot: Double, elapsed: Double) -> BootObservation {
        BootObservation(boot: SystemBoot(id: id, startedAt: date(boot)), continuousTime: elapsed)
    }
    private func checkpoint() -> CoordinatorCheckpoint {
        CoordinatorCheckpoint(enforcement: EnforcementState(), statistics: BreakStatistics(),
            savedAt: date(10_000), observation: observation("old", boot: 0, elapsed: 10_000))
    }
    private func assess(_ checkpoint: CoordinatorCheckpoint, boot: Double = 17_200,
                        now: Double? = nil, history: [SystemLifecycleEvent] = []) -> StartupRecoveryAssessment {
        let now = now ?? boot + 100
        return StartupRecoveryAssessment.assess(checkpoint: checkpoint,
            current: observation("new", boot: boot, elapsed: now - boot), now: date(now), history: history)
    }

    @Test func twoHoursWithoutShutdownHistorySchedulesAShortBreak() async throws {
        let time = ManualCoordinatorClock()
        let schedule = makeSchedule(breakInterval: 100, intervalCycle: [.init(duration: 100), .init(duration: 200)],
            repetitionRule: .init(shortBreakCount: 2, shortBreakDuration: 300, longBreakDuration: 900))
        var saved = checkpoint()
        saved.enforcement = EnforcementState(dailyBreakCounts: [schedule.id: 4], cycleIndices: [schedule.id: 1],
            repetitionIndices: [schedule.id: 2], pendingBreakDates: [schedule.id: time.clock.now().addingTimeInterval(30)],
            consecutiveDismissalCounts: [schedule.id: 2],
            recovery: BreakRecoveryState(remainingWork: [schedule.id: 30], ownerScheduleID: schedule.id))
        let locker = MockLocker()
        let coordinator = BreakCoordinator(scheduler: ScheduleEvaluator(), detector: MockDetector(), locker: locker, clock: time.clock)
        coordinator.start(with: [schedule], preferences: AppPreferences(), restoring: saved.enforcement,
                          startupRecovery: assess(saved))
        let state = coordinator.captureEnforcementState()
        #expect(state.repetitionIndices[schedule.id] == 0)
        #expect(state.cycleIndices[schedule.id] == 0)
        #expect(state.pendingBreakDates[schedule.id] == time.clock.now().addingTimeInterval(100))
        #expect(state.dailyBreakCounts[schedule.id] == 4)
        #expect(state.consecutiveDismissalCounts[schedule.id] == 2)
        #expect(coordinator.currentStatistics.breaksCompleted == 0)
        time.advance(100)
        #expect(await waitUntil { locker.isShowing })
        #expect(locker.lastDuration == 300)
        coordinator.stop()
    }

    @Test(arguments: [1199.0, 1200.0, 1201.0])
    func fiveMinuteAllowanceIsAppliedBeforeTheLongBreakThreshold(gap: Double) {
        let schedule = makeSchedule(repetitionRule: .init(shortBreakCount: 2, shortBreakDuration: 300, longBreakDuration: 900))
        var saved = checkpoint()
        saved.enforcement.repetitionIndices[schedule.id] = 2
        let result = assess(saved, boot: 10_000 + gap).applying(to: saved.enforcement, schedules: [schedule])
        #expect(result.repetitionIndices[schedule.id] == (gap >= 1200 ? 0 : 2))
    }

    @Test func quickRestartAndDelayedAppLaunchDoNotCreateRest() {
        #expect(assess(checkpoint(), boot: 10_030, now: 30_000) == .preserveProgress)
    }

    @Test func earliestBootBoundsTheGapAcrossMultipleReboots() {
        let history: [SystemLifecycleEvent] = [.init(kind: .boot, date: date(0)),
            .init(kind: .boot, date: date(10_030)), .init(kind: .boot, date: date(17_200))]
        #expect(assess(checkpoint(), history: history) == .preserveProgress)
    }

    @Test func sameBootRelaunchPreservesProgressEvenAfterHours() {
        #expect(StartupRecoveryAssessment.assess(checkpoint: checkpoint(),
            current: observation("old", boot: 0, elapsed: 20_000), now: date(20_000), history: []) == .preserveProgress)
    }

    @Test func missingObservationAndInvalidTimesPreserveProgress() {
        var saved = checkpoint()
        saved.observation = nil
        #expect(assess(saved) == .preserveProgress)
        saved = checkpoint()
        saved.observation?.continuousTime = .infinity
        #expect(assess(saved) == .preserveProgress)
        saved = checkpoint()
        saved.savedAt = date(20_000)
        #expect(assess(saved) == .preserveProgress)
        #expect(StartupRecoveryAssessment.assess(checkpoint: checkpoint(), current: nil,
            now: date(20_000), history: []) == .preserveProgress)
    }

    @Test func clockChangesAndInconsistentMonotonicTimePreventInference() {
        #expect(assess(checkpoint(), history: [.init(kind: .clockChange, date: date(10_001))]) == .preserveProgress)
        var saved = checkpoint()
        saved.observation?.continuousTime = 100
        #expect(assess(saved) == .preserveProgress)
    }

    @Test func verifiedHistoryTakesPriorityAndSupportsLegacyCheckpoints() {
        var saved = checkpoint()
        saved.observation = nil
        saved.exit = SystemExitRecord(reason: .shutdown, requestedAt: date(10_000),
                                     boot: SystemBoot(id: "old", startedAt: date(0)))
        let history: [SystemLifecycleEvent] = [.init(kind: .boot, date: date(0)),
            .init(kind: .shutdown, date: date(10_030)), .init(kind: .boot, date: date(17_200))]
        #expect(assess(saved, history: history) == .verifiedRest(7170))
    }

    @Test(arguments: [false, true])
    func inferenceKeepsOwedBreakIdentityAndRemainingDuration(postponed: Bool) {
        let time = ManualCoordinatorClock()
        let schedule = makeSchedule(repetitionRule: .init(shortBreakCount: 2, shortBreakDuration: 300, longBreakDuration: 900))
        let event = BreakEvent(scheduledAt: time.clock.now(), duration: 900, level: .gentle, scheduleId: schedule.id)
        let state = EnforcementState(repetitionIndices: [schedule.id: 2],
            postponedScheduleID: postponed ? schedule.id : nil,
            recovery: BreakRecoveryState(breaks: [schedule.id: InterruptedBreak(event: event,
                remainingDuration: 600, isPostponed: postponed)], ownerScheduleID: schedule.id))
        let result = assess(checkpoint()).applying(to: state, schedules: [schedule])
        #expect(result.recovery?.breaks[schedule.id]?.event.id == event.id)
        #expect(result.recovery?.breaks[schedule.id]?.remainingDuration == 600)
        #expect(result.postponedScheduleID == state.postponedScheduleID)
    }

    @Test func thresholdsArePerScheduleIncludingDisabledSchedules() {
        let a = makeSchedule(repetitionRule: .init(shortBreakCount: 2, shortBreakDuration: 300, longBreakDuration: 600))
        var b = makeSchedule(repetitionRule: .init(shortBreakCount: 2, shortBreakDuration: 300, longBreakDuration: 1800))
        b.isEnabled = false
        let state = EnforcementState(repetitionIndices: [a.id: 2, b.id: 2])
        let result = assess(checkpoint(), boot: 11_200).applying(to: state, schedules: [a, b])
        #expect(result.repetitionIndices[a.id] == 0)
        #expect(result.repetitionIndices[b.id] == 2)
    }

    @Test func currentBootObservationConsumesInferenceOnTheNextLaunch() throws {
        var saved = checkpoint()
        let assessment = assess(saved)
        #expect(assessment == .inferredInterruption(6900))
        saved.savedAt = date(17_300)
        saved.observation = observation("new", boot: 17_200, elapsed: 100)
        let decoded = try JSONDecoder().decode(CoordinatorCheckpoint.self, from: JSONEncoder().encode(saved))
        #expect(assess(decoded, now: 20_000) == .preserveProgress)
    }
}
