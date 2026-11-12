import Foundation
import Testing
@testable import Coordination
import Scheduling
import StandLockCore

@Suite("Multi-hour breaks")
@MainActor
struct ExtendedBreakTests {
    @Test func fifteenMinutesOfWorkStartsOneFiveHourOvernightBreak() async throws {
        let time = ManualCoordinatorClock()
        time.advance(12 * 3600 + 45 * 60) // Monday 22:45.
        var schedule = makeSchedule(breakInterval: 900, breakDuration: 18000)
        schedule.windows = [TimeWindow(startHour: 22, startMinute: 45, endHour: 4, endMinute: 0)]
        let locker = MockLocker()
        let coordinator = BreakCoordinator(scheduler: ScheduleEvaluator(), detector: MockDetector(),
                                           locker: locker, clock: time.clock)
        defer { coordinator.stop() }
        coordinator.start(with: [schedule], preferences: AppPreferences())

        #expect(coordinator.captureEnforcementState().pendingBreakDates[schedule.id]
            == time.clock.now().addingTimeInterval(900))
        time.advance(900)
        #expect(await waitUntil { locker.isShowing })
        #expect(locker.lastDuration == 18000)

        time.advance(17999)
        let state = coordinator.captureEnforcementState()
        #expect(locker.isShowing)
        #expect(coordinator.currentStatistics.breaksCompleted == 0)
        #expect(state.recovery?.breaks[schedule.id]?.remainingDuration == 1)

        time.advance(1)
        #expect(await waitUntil { coordinator.currentStatistics.breaksCompleted == 1 })
        #expect(!locker.isShowing)
        #expect(coordinator.captureEnforcementState().pendingBreakDates[schedule.id]
            == time.clock.now().addingTimeInterval(19 * 3600)) // Next evening at 23:00.
    }
}
