import Foundation
import Testing
@testable import Coordination
import Scheduling
import StandLockCore

@Suite("Zero skip hard block")
@MainActor
struct ZeroSkipLimitTests {
    @Test(arguments: DisciplineLevel.allCases)
    func zeroRejectsMenuSkipsPausesAndAllActiveDismissals(level: DisciplineLevel) async {
        let time = ManualCoordinatorClock()
        var schedule = makeSchedule(level: level, breakInterval: 100, breakDuration: 300)
        schedule.consecutiveSkipLimit = 0
        let locker = MockLocker()
        let coordinator = BreakCoordinator(scheduler: ScheduleEvaluator(), detector: MockDetector(),
                                           locker: locker, clock: time.clock)
        coordinator.start(with: [schedule], preferences: AppPreferences())
        let slot = coordinator.pendingSlotID
        let pending = coordinator.captureEnforcementState().pendingBreakDates
        coordinator.skipNextBreak(expectedSlotID: slot)
        coordinator.pause(for: 600)
        #expect(coordinator.pendingSlotID == slot)
        #expect(coordinator.captureEnforcementState().pendingBreakDates == pending)
        #expect(coordinator.captureEnforcementState().recovery?.pauseDeadline == nil)
        #expect(coordinator.currentStatistics.breaksSkipped == 0)
        time.advance(100)
        #expect(await waitUntil { locker.isShowing })
        let id = locker.lastBreakID
        coordinator.skipActiveBreak(expectedBreakID: id)
        coordinator.escapeActiveBreak(expectedBreakID: id)
        coordinator.postponeActiveBreak(expectedBreakID: id)
        coordinator.pause(for: 600)
        #expect(locker.isShowing)
        #expect(locker.lastBreakID == id)
        #expect(!locker.lastAvailability.normalSkipAllowed)
        #expect(!locker.lastAvailability.emergencyEscapeAllowed)
        #expect(coordinator.currentStatistics.breaksSkipped == 0)
        #expect(coordinator.currentStatistics.breaksEscaped == 0)
        #expect(coordinator.currentStatistics.breaksDeferred == 0)
        coordinator.stop()
    }

    @Test func liveZeroSettingAppliesImmediatelyAndCompletionDoesNotEnableDismissal() async {
        let time = ManualCoordinatorClock()
        var schedule = makeSchedule(breakInterval: 100, breakDuration: 300, progressiveEnforcement: true)
        schedule.consecutiveSkipLimit = 2
        let locker = MockLocker()
        let coordinator = BreakCoordinator(scheduler: ScheduleEvaluator(), detector: MockDetector(),
                                           locker: locker, clock: time.clock)
        coordinator.start(with: [schedule], preferences: AppPreferences())
        time.advance(100)
        #expect(await waitUntil { locker.isShowing })
        let id = locker.lastBreakID
        schedule.consecutiveSkipLimit = 0
        schedule.progressiveEnforcement = false
        coordinator.updateEnforcementSettings(for: schedule)
        #expect(!locker.lastAvailability.emergencyEscapeAllowed)
        coordinator.postponeActiveBreak(expectedBreakID: id)
        #expect(locker.isShowing)
        coordinator.completeActiveBreak(expectedBreakID: id)
        #expect(!coordinator.canSkipNextBreak)
        coordinator.stop()
    }

    @Test func onlyEnabledInHoursHardBlockSchedulesRestrictGlobalPause() {
        let time = ManualCoordinatorClock()
        var restricted = makeSchedule(breakInterval: 2700)
        restricted.consecutiveSkipLimit = 0
        restricted.windows = [TimeWindow(startHour: 20, startMinute: 0, endHour: 21, endMinute: 0)]
        let ordinary = makeSchedule(breakInterval: 100)
        let coordinator = BreakCoordinator(scheduler: ScheduleEvaluator(), detector: MockDetector(),
                                           locker: MockLocker(), clock: time.clock)
        coordinator.start(with: [restricted, ordinary], preferences: AppPreferences())
        #expect(coordinator.canPauseScheduling)
        coordinator.pause(for: 600)
        #expect(coordinator.captureEnforcementState().recovery?.pauseDeadline != nil)
        coordinator.stop()
    }
}
