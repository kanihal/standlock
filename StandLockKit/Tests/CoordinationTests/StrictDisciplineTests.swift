import Foundation
import Testing
@testable import Coordination
import Scheduling
import StandLockCore

@Suite("Strict discipline actions")
@MainActor
struct StrictDisciplineTests {
    private func start(_ time: ManualCoordinatorClock, _ locker: MockLocker, schedules: [Schedule]) -> BreakCoordinator {
        let coordinator = BreakCoordinator(scheduler: ScheduleEvaluator(), detector: MockDetector(),
                                           locker: locker, clock: time.clock)
        coordinator.start(with: schedules, preferences: AppPreferences())
        return coordinator
    }

    @Test func strictRejectsMenuSkipAndPauseBeforeTheBreakStarts() {
        let time = ManualCoordinatorClock()
        let schedule = makeSchedule(level: .strict, breakInterval: 100, breakDuration: 300)
        let coordinator = start(time, MockLocker(), schedules: [schedule])
        let slot = coordinator.pendingSlotID
        let dates = coordinator.captureEnforcementState().pendingBreakDates
        #expect(!coordinator.canSkipNextBreak)
        #expect(!coordinator.canPauseScheduling)
        coordinator.skipNextBreak(expectedSlotID: slot)
        coordinator.pause(for: 600)
        #expect(coordinator.pendingSlotID == slot)
        #expect(coordinator.captureEnforcementState().pendingBreakDates == dates)
        #expect(coordinator.captureEnforcementState().recovery?.pauseDeadline == nil)
        #expect(coordinator.currentStatistics.breaksSkipped == 0)
        coordinator.stop()
    }

    @Test func strictRejectsSkipPostponeAndPauseButAllowsEmergencyEscape() async {
        let time = ManualCoordinatorClock()
        let locker = MockLocker()
        let schedule = makeSchedule(level: .strict, breakInterval: 100, breakDuration: 300)
        let coordinator = start(time, locker, schedules: [schedule])
        time.advance(100)
        #expect(await waitUntil { locker.isShowing })
        let id = locker.lastBreakID
        #expect(!locker.lastAvailability.normalSkipAllowed)
        #expect(locker.lastAvailability.emergencyEscapeAllowed)
        #expect(locker.lastCanPostpone == false)
        coordinator.skipActiveBreak(expectedBreakID: id)
        coordinator.postponeActiveBreak(expectedBreakID: id)
        coordinator.pause(for: 600)
        #expect(locker.isShowing)
        #expect(coordinator.currentStatistics.breaksSkipped == 0)
        #expect(coordinator.currentStatistics.breaksDeferred == 0)
        #expect(coordinator.captureEnforcementState().recovery?.pauseDeadline == nil)
        coordinator.escapeActiveBreak(expectedBreakID: id)
        #expect(!locker.isShowing)
        #expect(coordinator.currentStatistics.breaksEscaped == 1)
        coordinator.stop()
    }

    @Test func anUpcomingStrictSchedulePreventsPausingUnrelatedSchedules() {
        let time = ManualCoordinatorClock()
        let strict = makeSchedule(level: .strict, breakInterval: 2700)
        let gentle = makeSchedule(breakInterval: 100)
        let coordinator = start(time, MockLocker(), schedules: [strict, gentle])
        #expect(!coordinator.canPauseScheduling)
        coordinator.pause(for: 600)
        #expect(coordinator.captureEnforcementState().recovery?.pauseDeadline == nil)
        coordinator.stop()
    }

    @Test func disabledOrOutOfHoursStrictSchedulesDoNotBlockUnrelatedPauses() {
        let time = ManualCoordinatorClock()
        var disabled = makeSchedule(level: .strict)
        disabled.isEnabled = false
        var outside = makeSchedule(level: .strict)
        outside.windows = [TimeWindow(startHour: 20, startMinute: 0, endHour: 21, endMinute: 0)]
        let coordinator = start(time, MockLocker(), schedules: [disabled, outside, makeSchedule(breakInterval: 100)])
        #expect(coordinator.canPauseScheduling)
        coordinator.pause(for: 600)
        #expect(coordinator.captureEnforcementState().recovery?.pauseDeadline != nil)
        coordinator.stop()
    }

    @Test func permissionFallbackPreservesChosenStrictRestrictions() async {
        let time = ManualCoordinatorClock()
        let locker = MockLocker()
        let fallback = makeSchedule(level: .firm, breakInterval: 100, breakDuration: 300)
        let coordinator = BreakCoordinator(scheduler: ScheduleEvaluator(), detector: MockDetector(),
                                           locker: locker, clock: time.clock)
        coordinator.start(with: [fallback], preferences: AppPreferences(), strictScheduleIDs: [fallback.id])
        #expect(!coordinator.canSkipNextBreak)
        #expect(!coordinator.canPauseScheduling)
        time.advance(100)
        #expect(await waitUntil { locker.isShowing })
        #expect(locker.lastLevel == .firm)
        #expect(!locker.lastAvailability.normalSkipAllowed)
        #expect(locker.lastAvailability.emergencyEscapeAllowed)
        #expect(locker.lastCanPostpone == false)
        coordinator.postponeActiveBreak(expectedBreakID: locker.lastBreakID)
        #expect(locker.isShowing)
        coordinator.stop()
    }

    @Test func changingTheChosenModeRefreshesSkipAndPauseRestrictions() {
        let time = ManualCoordinatorClock()
        let schedule = makeSchedule(level: .gentle, breakInterval: 100)
        let coordinator = start(time, MockLocker(), schedules: [schedule])
        #expect(coordinator.canSkipNextBreak && coordinator.canPauseScheduling)
        coordinator.changeDisciplineLevel(.strict)
        #expect(!coordinator.canSkipNextBreak && !coordinator.canPauseScheduling)
        coordinator.changeDisciplineLevel(.gentle)
        #expect(coordinator.canSkipNextBreak && coordinator.canPauseScheduling)
        coordinator.stop()
    }
}
