import Foundation
import Testing
@testable import Coordination
import Scheduling
import StandLockCore

@Suite("Interrupted break recovery")
@MainActor
struct BreakRecoveryTests {
    private func start(_ time: ManualCoordinatorClock, _ locker: MockLocker, schedule: Schedule,
                       state: EnforcementState = EnforcementState(), rest: TimeInterval = 0,
                       initiallyAway: Set<AwaySessionTracker.Reason> = []) -> BreakCoordinator {
        let coordinator = BreakCoordinator(scheduler: ScheduleEvaluator(), detector: MockDetector(),
                                           locker: locker, clock: time.clock)
        coordinator.start(with: [schedule], preferences: AppPreferences(), restoring: state,
                          verifiedRestDuration: rest, initiallyAway: initiallyAway)
        return coordinator
    }

    private func persisted(_ coordinator: BreakCoordinator) throws -> EnforcementState {
        try JSONDecoder().decode(EnforcementState.self,
            from: JSONEncoder().encode(coordinator.captureEnforcementState()))
    }

    @Test func crashRestoresSameBreakWithoutCreditingAppClosedTime() async throws {
        let time = ManualCoordinatorClock()
        let schedule = makeSchedule(breakInterval: 100, breakDuration: 300)
        let locker = MockLocker()
        let first = start(time, locker, schedule: schedule)
        time.advance(100)
        #expect(await waitUntil { locker.isShowing })
        let id = locker.lastBreakID
        time.advance(120)
        let state = try persisted(first)
        first.stop()
        time.advance(3600)

        let restoredLocker = MockLocker()
        let restored = start(time, restoredLocker, schedule: schedule, state: state)
        #expect(restoredLocker.isShowing)
        #expect(restoredLocker.lastBreakID == id)
        #expect(restoredLocker.lastDuration == 180)
        #expect(restored.captureEnforcementState().cycleIndices[schedule.id] == 1)
        #expect(restored.captureEnforcementState().dailyBreakCounts[schedule.id] == 1)
        restored.stop()
    }

    @Test func postponedBreakRemainsOwedAfterJSONRelaunch() async throws {
        let time = ManualCoordinatorClock()
        let schedule = makeSchedule(breakInterval: 100, breakDuration: 300)
        let locker = MockLocker()
        let first = start(time, locker, schedule: schedule)
        time.advance(100)
        #expect(await waitUntil { locker.isShowing })
        first.postponeActiveBreak()
        let state = try persisted(first)
        first.stop()
        let restored = start(time, MockLocker(), schedule: schedule, state: state)
        #expect(restored.captureEnforcementState().postponedScheduleID == schedule.id)
        #expect(restored.captureEnforcementState().dailyBreakCounts[schedule.id] == 1)
        restored.stop()
    }

    @Test func unexpiredManualPauseSurvivesJSONRelaunch() throws {
        let time = ManualCoordinatorClock()
        let schedule = makeSchedule(breakInterval: 100)
        let first = start(time, MockLocker(), schedule: schedule)
        first.pause(for: 600)
        let state = try persisted(first)
        first.stop()
        time.advance(100)
        let restored = start(time, MockLocker(), schedule: schedule, state: state)
        #expect(!restored.canSkipNextBreak)
        restored.stop()
    }

    @Test(arguments: [30.0, 180.0, 300.0, 600.0])
    func poweredOffTimeCompletesOrResumesExactlyOnce(rest: TimeInterval) async throws {
        let time = ManualCoordinatorClock()
        var schedule = makeSchedule(breakInterval: 100, breakDuration: 300, progressiveEnforcement: true)
        schedule.consecutiveSkipLimit = 2
        let locker = MockLocker()
        let first = start(time, locker, schedule: schedule,
                          state: EnforcementState(consecutiveDismissalCounts: [schedule.id: 2]))
        time.advance(100)
        #expect(await waitUntil { locker.isShowing })
        let id = locker.lastBreakID
        time.advance(120)
        let state = try persisted(first)
        first.stop()
        time.advance(3600)
        let restoredLocker = MockLocker()
        let restored = start(time, restoredLocker, schedule: schedule, state: state, rest: rest)
        if rest == 30 {
            #expect(restoredLocker.lastBreakID == id)
            #expect(restoredLocker.lastDuration == 150)
            #expect(!restoredLocker.lastAvailability.emergencyEscapeAllowed)
        } else {
            #expect(!restoredLocker.isShowing)
            #expect(restored.captureEnforcementState().recovery?.breaks.isEmpty == true)
            #expect(restored.captureEnforcementState().consecutiveDismissalCounts[schedule.id, default: 0] == 0)
        }
        let again = try persisted(restored)
        restored.stop()
        let repeated = start(time, MockLocker(), schedule: schedule, state: again)
        #expect(repeated.captureEnforcementState().recovery?.breaks.count == (rest == 30 ? 1 : 0))
        repeated.stop()
    }

    @Test func startupWhileLockedDoesNotFlashRestoredOverlay() async throws {
        let time = ManualCoordinatorClock()
        let schedule = makeSchedule(breakInterval: 100, breakDuration: 300)
        let locker = MockLocker()
        let first = start(time, locker, schedule: schedule)
        time.advance(100)
        #expect(await waitUntil { locker.isShowing })
        time.advance(120)
        let state = try persisted(first)
        first.stop()
        let restoredLocker = MockLocker()
        let restored = start(time, restoredLocker, schedule: schedule, state: state, initiallyAway: [.locked])
        #expect(!restoredLocker.isShowing)
        time.advance(30)
        restored.handleScreenUnlock()
        #expect(restoredLocker.lastDuration == 150)
        restored.stop()
    }

    @Test func offlineAndEarlierBreakSegmentsDoNotCombineIntoALongRest() async throws {
        let time = ManualCoordinatorClock()
        let schedule = makeSchedule(breakInterval: 100, repetitionRule: RepetitionRule(
            shortBreakCount: 3, shortBreakDuration: 300, longBreakDuration: 1200))
        let locker = MockLocker()
        let first = start(time, locker, schedule: schedule,
                          state: EnforcementState(repetitionIndices: [schedule.id: 2]))
        time.advance(100)
        #expect(await waitUntil { locker.isShowing })
        time.advance(180)
        let state = try persisted(first)
        first.stop()
        let restored = start(time, MockLocker(), schedule: schedule, state: state, rest: 1020)
        #expect(restored.captureEnforcementState().repetitionIndices[schedule.id] == 3)
        restored.stop()
    }

    @Test func disabledOwedBreakDoesNotPreventOtherSchedulesAndResumesWhenEnabled() async throws {
        let time = ManualCoordinatorClock()
        var schedule = makeSchedule(breakInterval: 100, breakDuration: 300)
        let locker = MockLocker()
        let first = start(time, locker, schedule: schedule)
        time.advance(100)
        #expect(await waitUntil { locker.isShowing })
        let id = locker.lastBreakID
        time.advance(120)
        let state = try persisted(first)
        first.stop()
        schedule.isEnabled = false
        let other = makeSchedule(breakInterval: 600)
        let disabled = BreakCoordinator(scheduler: ScheduleEvaluator(), detector: MockDetector(),
                                        locker: MockLocker(), clock: time.clock)
        disabled.start(with: [schedule, other], preferences: AppPreferences(), restoring: state)
        #expect(disabled.canSkipNextBreak)
        #expect(disabled.captureEnforcementState().recovery?.breaks[schedule.id]?.event.id == id)
        let carried = try persisted(disabled)
        disabled.stop()
        schedule.isEnabled = true
        let restoredLocker = MockLocker()
        let restored = start(time, restoredLocker, schedule: schedule, state: carried)
        #expect(restoredLocker.lastBreakID == id)
        #expect(restoredLocker.lastDuration == 180)
        restored.stop()
    }

    @Test func checkpointIsWrittenBeforeOverlayAndCompletionNotification() async {
        let time = ManualCoordinatorClock()
        let locker = MockLocker()
        let coordinator = BreakCoordinator(scheduler: ScheduleEvaluator(), detector: MockDetector(),
                                           locker: locker, clock: time.clock)
        var saved: (EnforcementState, BreakStatistics)?
        var firstSaveWasBeforeOverlay = false
        coordinator.onCheckpoint = { state, stats in
            if saved?.0.recovery?.breaks.isEmpty != false, state.recovery?.breaks.isEmpty == false {
                firstSaveWasBeforeOverlay = !locker.isShowing
            }
            saved = (state, stats)
            return true
        }
        let schedule = makeSchedule(breakInterval: 100, breakDuration: 300)
        coordinator.start(with: [schedule], preferences: AppPreferences())
        time.advance(100)
        #expect(await waitUntil { locker.isShowing })
        #expect(firstSaveWasBeforeOverlay)
        coordinator.completeActiveBreak()
        #expect(saved?.0.recovery?.breaks.isEmpty == true)
        #expect(saved?.1.breaksCompleted == 1)
        coordinator.stop()
    }

    @Test func terminationPromptPreservesTheOwedBreakWithoutCreditingPromptTime() async throws {
        let time = ManualCoordinatorClock()
        let schedule = makeSchedule(level: .strict, breakInterval: 100, breakDuration: 300)
        let locker = MockLocker()
        let coordinator = start(time, locker, schedule: schedule)
        time.advance(100)
        #expect(await waitUntil { locker.isShowing })
        let id = locker.lastBreakID
        time.advance(120)
        coordinator.suspendForTerminationPrompt()
        #expect(!locker.isShowing)
        #expect(coordinator.hasUnfinishedBreak)
        time.advance(600)
        coordinator.resumeAfterTerminationPrompt()
        #expect(locker.isShowing)
        #expect(locker.lastBreakID == id)
        #expect(locker.lastDuration == 180)
        coordinator.stop()
    }

    @Test func restoredPausedBreakCanBeSatisfiedByObservedSleepWithoutEndingManualPause() {
        let time = ManualCoordinatorClock()
        let schedule = makeSchedule(breakInterval: 100, breakDuration: 300)
        let event = BreakEvent(scheduledAt: time.clock.now(), duration: 300, level: .gentle, scheduleId: schedule.id)
        let state = EnforcementState(dailyBreakCounts: [schedule.id: 1], recovery: BreakRecoveryState(
            breaks: [schedule.id: InterruptedBreak(event: event, remainingDuration: 30)],
            ownerScheduleID: schedule.id, pauseDeadline: time.clock.now().addingTimeInterval(600)))
        let coordinator = start(time, MockLocker(), schedule: schedule, state: state)
        coordinator.handleScreenLock()
        time.advance(30)
        coordinator.handleScreenUnlock()
        #expect(coordinator.currentStatistics.breaksCompleted == 1)
        #expect(coordinator.captureEnforcementState().recovery?.breaks.isEmpty == true)
        #expect(!coordinator.canSkipNextBreak)
        coordinator.stop()
    }

    @Test func outsideHoursBreakWaitsAndResumesWithoutLosingItsRemainingTime() async {
        let time = ManualCoordinatorClock()
        var schedule = makeSchedule(breakInterval: 100, breakDuration: 300)
        schedule.windows = [TimeWindow(startHour: 11, startMinute: 0, endHour: 12, endMinute: 0)]
        let event = BreakEvent(scheduledAt: time.clock.now(), duration: 300, level: .gentle, scheduleId: schedule.id)
        let state = EnforcementState(recovery: BreakRecoveryState(
            breaks: [schedule.id: InterruptedBreak(event: event, remainingDuration: 180)]))
        let locker = MockLocker()
        let coordinator = start(time, locker, schedule: schedule, state: state)
        #expect(!locker.isShowing)
        time.advance(3600)
        #expect(await waitUntil { locker.isShowing })
        #expect(locker.lastBreakID == event.id)
        #expect(locker.lastDuration == 180)
        coordinator.stop()
    }

    @Test func checkpointRefreshBoundsLostProgressToFiveSeconds() async {
        let time = ManualCoordinatorClock()
        let locker = MockLocker()
        let coordinator = BreakCoordinator(scheduler: ScheduleEvaluator(), detector: MockDetector(),
                                           locker: locker, clock: time.clock)
        var remaining: TimeInterval?
        let schedule = makeSchedule(breakInterval: 100, breakDuration: 300)
        coordinator.onCheckpoint = { state, _ in
            remaining = state.recovery?.breaks[schedule.id]?.remainingDuration
            return true
        }
        coordinator.start(with: [schedule], preferences: AppPreferences())
        time.advance(100)
        #expect(await waitUntil { locker.isShowing })
        time.advance(5)
        #expect(await waitUntil { remaining == 295 })
        coordinator.stop()
    }

    @Test func qualifyingOfflineRestResetsDisabledSchedulesWithoutExtraCompletions() {
        let time = ManualCoordinatorClock()
        let a = makeSchedule(breakInterval: 100, repetitionRule: RepetitionRule(
            shortBreakCount: 3, shortBreakDuration: 300, longBreakDuration: 1200))
        var b = makeSchedule(breakInterval: 100, repetitionRule: RepetitionRule(
            shortBreakCount: 3, shortBreakDuration: 300, longBreakDuration: 600))
        b.isEnabled = false
        let state = EnforcementState(repetitionIndices: [a.id: 2, b.id: 2],
            consecutiveDismissalCounts: [a.id: 2, b.id: 2], recovery: BreakRecoveryState(ownerScheduleID: a.id))
        let coordinator = BreakCoordinator(scheduler: ScheduleEvaluator(), detector: MockDetector(),
                                           locker: MockLocker(), clock: time.clock)
        coordinator.start(with: [a, b], preferences: AppPreferences(), restoring: state, verifiedRestDuration: 600)
        let snapshot = coordinator.captureEnforcementState()
        #expect(snapshot.repetitionIndices[a.id] == 3)
        #expect(snapshot.repetitionIndices[b.id] == 0)
        #expect(snapshot.consecutiveDismissalCounts.isEmpty || snapshot.consecutiveDismissalCounts[a.id] == 0)
        #expect(coordinator.currentStatistics.breaksCompleted == 1)
        coordinator.stop()
    }

    @Test func restoredActiveIdentityHasPriorityOverOlderDormantDebt() {
        let time = ManualCoordinatorClock()
        let older = makeSchedule(breakInterval: 100)
        let active = makeSchedule(breakInterval: 100)
        let oldEvent = BreakEvent(scheduledAt: time.clock.now().addingTimeInterval(-600), duration: 300,
                                  level: .gentle, scheduleId: older.id)
        let activeEvent = BreakEvent(scheduledAt: time.clock.now(), duration: 300, level: .gentle, scheduleId: active.id)
        let state = EnforcementState(recovery: BreakRecoveryState(breaks: [
            older.id: InterruptedBreak(event: oldEvent, remainingDuration: 100),
            active.id: InterruptedBreak(event: activeEvent, remainingDuration: 180)], ownerScheduleID: active.id))
        let locker = MockLocker()
        let coordinator = BreakCoordinator(scheduler: ScheduleEvaluator(), detector: MockDetector(),
                                           locker: locker, clock: time.clock)
        coordinator.start(with: [older, active], preferences: AppPreferences(), restoring: state)
        #expect(locker.lastBreakID == activeEvent.id)
        #expect(locker.lastDuration == 180)
        coordinator.stop()
    }

    @Test func restoredWorkCountdownWaitsForUnlockAfterAnInsufficientAbsence() throws {
        let time = ManualCoordinatorClock()
        let schedule = makeSchedule(breakInterval: 2700)
        let first = start(time, MockLocker(), schedule: schedule)
        time.advance(1200)
        let state = first.captureEnforcementState()
        let encoded = try JSONEncoder().encode(state)
        let persisted = try JSONDecoder().decode(EnforcementState.self, from: encoded)
        first.stop()
        let restored = start(time, MockLocker(), schedule: schedule, state: persisted, initiallyAway: [.locked])
        time.advance(30)
        restored.handleScreenUnlock()
        #expect(restored.captureEnforcementState().pendingBreakDates[schedule.id] == time.clock.now().addingTimeInterval(1500))
        restored.stop()
    }

    @Test(arguments: [299.0, 300.0])
    func configuredThresholdCanSatisfyAnUnfinishedLongerBreak(rest: TimeInterval) {
        let time = ManualCoordinatorClock()
        let schedule = makeSchedule(breakInterval: 100, breakDuration: 900)
        let event = BreakEvent(scheduledAt: time.clock.now(), duration: 900, level: .gentle, scheduleId: schedule.id)
        let state = EnforcementState(recovery: BreakRecoveryState(breaks: [
            schedule.id: InterruptedBreak(event: event, remainingDuration: 780)], ownerScheduleID: schedule.id))
        let locker = MockLocker()
        let coordinator = start(time, locker, schedule: schedule, state: state, rest: rest)
        #expect(coordinator.currentStatistics.breaksCompleted == (rest == 300 ? 1 : 0))
        #expect(locker.isShowing == (rest == 299))
        if rest == 299 { #expect(locker.lastDuration == 481) }
        coordinator.stop()
    }

    @Test func overnightCrashKeepsBreakIdentityShortProgressAndExhaustedAllowance() async throws {
        let time = ManualCoordinatorClock()
        var schedule = makeSchedule(breakInterval: 100, repetitionRule: RepetitionRule(
            shortBreakCount: 3, shortBreakDuration: 300, longBreakDuration: 1200), progressiveEnforcement: true)
        schedule.consecutiveSkipLimit = 2
        let locker = MockLocker()
        let first = start(time, locker, schedule: schedule, state: EnforcementState(
            repetitionIndices: [schedule.id: 2], consecutiveDismissalCounts: [schedule.id: 2]))
        time.advance(100)
        #expect(await waitUntil { locker.isShowing })
        let id = locker.lastBreakID
        time.advance(120)
        var state = try persisted(first)
        state.resetDailyCounters()
        first.stop()
        time.advance(86400)
        let restoredLocker = MockLocker()
        let restored = start(time, restoredLocker, schedule: schedule, state: state)
        #expect(restoredLocker.lastBreakID == id)
        #expect(restoredLocker.lastDuration == 180)
        #expect(!restoredLocker.lastAvailability.emergencyEscapeAllowed)
        #expect(restored.captureEnforcementState().repetitionIndices[schedule.id] == 2)
        #expect(restored.currentStatistics.breaksCompleted == 0)
        restored.stop()
    }

    @Test func dormantDebtDoesNotKeepPushingAnotherSchedulesDeadline() async {
        let time = ManualCoordinatorClock()
        var disabled = makeSchedule(breakInterval: 100)
        disabled.isEnabled = false
        let working = makeSchedule(breakInterval: 30, breakDuration: 300)
        let debt = BreakEvent(scheduledAt: time.clock.now(), duration: 300, level: .gentle, scheduleId: disabled.id)
        let state = EnforcementState(recovery: BreakRecoveryState(breaks: [
            disabled.id: InterruptedBreak(event: debt, remainingDuration: 180)]))
        let locker = MockLocker()
        let coordinator = BreakCoordinator(scheduler: ScheduleEvaluator(), detector: MockDetector(),
                                           locker: locker, clock: time.clock)
        coordinator.start(with: [disabled, working], preferences: AppPreferences(), restoring: state)
        for _ in 0..<6 {
            time.advance(5)
            for _ in 0..<20 { await Task.yield() }
        }
        #expect(locker.isShowing)
        #expect(coordinator.captureEnforcementState().recovery?.breaks[working.id] != nil)
        coordinator.stop()
    }

    @Test func cancellingQuitKeepsActiveIdentityAheadOfOlderDebt() {
        let time = ManualCoordinatorClock()
        let older = makeSchedule(breakInterval: 100)
        let active = makeSchedule(breakInterval: 100)
        let oldEvent = BreakEvent(scheduledAt: time.clock.now().addingTimeInterval(-600), duration: 300,
                                  level: .gentle, scheduleId: older.id)
        let activeEvent = BreakEvent(scheduledAt: time.clock.now(), duration: 300, level: .gentle, scheduleId: active.id)
        let state = EnforcementState(recovery: BreakRecoveryState(breaks: [
            older.id: InterruptedBreak(event: oldEvent, remainingDuration: 100),
            active.id: InterruptedBreak(event: activeEvent, remainingDuration: 180)], ownerScheduleID: active.id))
        let locker = MockLocker()
        let coordinator = BreakCoordinator(scheduler: ScheduleEvaluator(), detector: MockDetector(),
                                           locker: locker, clock: time.clock)
        coordinator.start(with: [older, active], preferences: AppPreferences(), restoring: state)
        coordinator.suspendForTerminationPrompt()
        #expect(coordinator.captureEnforcementState().recovery?.ownerScheduleID == active.id)
        time.advance(30)
        coordinator.resumeAfterTerminationPrompt()
        #expect(locker.lastBreakID == activeEvent.id)
        #expect(locker.lastDuration == 180)
        coordinator.stop()
    }

    @Test func firstCheckpointOfReturningPostponedBreakIsAlreadyActive() async throws {
        let time = ManualCoordinatorClock()
        let schedule = makeSchedule(breakInterval: 100, breakDuration: 300)
        let event = BreakEvent(scheduledAt: time.clock.now(), duration: 300, level: .gentle, scheduleId: schedule.id)
        let state = EnforcementState(postponedScheduleID: schedule.id, recovery: BreakRecoveryState(breaks: [
            schedule.id: InterruptedBreak(event: event, remainingDuration: 300, canPostpone: false, isPostponed: true)]))
        let locker = MockLocker()
        let coordinator = BreakCoordinator(scheduler: ScheduleEvaluator(), detector: MockDetector(),
                                           locker: locker, deferralPollingInterval: 0, clock: time.clock)
        var firstActiveSnapshot: EnforcementState?
        coordinator.onCheckpoint = { snapshot, _ in
            if firstActiveSnapshot == nil, snapshot.recovery?.breaks[schedule.id]?.isPostponed == false {
                firstActiveSnapshot = snapshot
            }
            return true
        }
        coordinator.start(with: [schedule], preferences: AppPreferences(postponeReturnDelay: 0), restoring: state)
        #expect(await waitUntil { locker.isShowing })
        let snapshot = try #require(firstActiveSnapshot)
        #expect(snapshot.postponedScheduleID == nil)
        coordinator.stop()
        let decoded = try JSONDecoder().decode(EnforcementState.self, from: JSONEncoder().encode(snapshot))
        let restoredLocker = MockLocker()
        let restored = start(time, restoredLocker, schedule: schedule, state: decoded)
        #expect(restoredLocker.lastBreakID == event.id)
        #expect(restoredLocker.isShowing)
        restored.stop()
    }

    @Test func failedCommitHoldsCompletionUntilItCanBePersisted() async throws {
        let time = ManualCoordinatorClock()
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: folder) }
        let store = CoordinatorCheckpointStore(url: folder.appendingPathComponent("state.json"))
        let locker = MockLocker()
        let coordinator = BreakCoordinator(scheduler: ScheduleEvaluator(), detector: MockDetector(),
                                           locker: locker, clock: time.clock)
        var failWrites = false
        coordinator.onCheckpoint = { state, stats in
            do {
                if failWrites { throw CocoaError(.fileWriteOutOfSpace) }
                try store.save(CoordinatorCheckpoint(enforcement: state, statistics: stats))
                return true
            } catch { return false }
        }
        var completions = 0
        let listener = Task {
            for await event in coordinator.events { if case .breakCompleted = event { completions += 1 } }
        }
        coordinator.start(with: [makeSchedule(breakInterval: 100, breakDuration: 300)], preferences: AppPreferences())
        time.advance(100)
        #expect(await waitUntil { locker.isShowing })
        failWrites = true
        coordinator.completeActiveBreak()
        for _ in 0..<30 { await Task.yield() }
        #expect(completions == 0)
        #expect(locker.isShowing)
        #expect(try store.load()?.statistics.breaksCompleted == 0)
        failWrites = false
        time.advance(5)
        #expect(await waitUntil { completions == 1 })
        #expect(!locker.isShowing)
        #expect(try store.load()?.statistics.breaksCompleted == 1)
        coordinator.stop()
        listener.cancel()
    }

    @Test func rebuildFinishesAPendingCommitAndArmsTheNextWorkInterval() async {
        let time = ManualCoordinatorClock()
        let locker = MockLocker()
        let first = BreakCoordinator(scheduler: ScheduleEvaluator(), detector: MockDetector(),
                                     locker: locker, clock: time.clock)
        var canWrite = true
        first.onCheckpoint = { _, _ in canWrite }
        let schedule = makeSchedule(breakInterval: 100, breakDuration: 300)
        first.start(with: [schedule], preferences: AppPreferences())
        time.advance(100)
        #expect(await waitUntil { locker.isShowing })
        canWrite = false
        first.completeActiveBreak()
        let state = first.captureEnforcementState()
        let statistics = first.currentStatistics
        first.stop()
        let restored = BreakCoordinator(scheduler: ScheduleEvaluator(), detector: MockDetector(),
                                        locker: locker, clock: time.clock)
        restored.onCheckpoint = { _, _ in true }
        restored.start(with: [schedule], preferences: AppPreferences(), statistics: statistics, restoring: state)
        #expect(restored.canSkipNextBreak)
        #expect(restored.currentStatistics.breaksCompleted == 1)
        restored.stop()
    }

    @Test func unavailablePersistenceDoesNotPresentOrCreditAnUnshownBreak() async {
        let time = ManualCoordinatorClock()
        let locker = MockLocker()
        let coordinator = BreakCoordinator(scheduler: ScheduleEvaluator(), detector: MockDetector(),
                                           locker: locker, clock: time.clock)
        var canWrite = false
        coordinator.onCheckpoint = { _, _ in canWrite }
        let schedule = makeSchedule(breakInterval: 100, breakDuration: 300)
        coordinator.start(with: [schedule], preferences: AppPreferences())
        time.advance(100)
        #expect(await waitUntil { coordinator.hasUnfinishedBreak })
        #expect(!locker.isShowing)
        time.advance(1000)
        for _ in 0..<30 { await Task.yield() }
        #expect(!locker.isShowing)
        #expect(coordinator.currentStatistics.breaksCompleted == 0)
        canWrite = true
        time.advance(5)
        #expect(await waitUntil { locker.isShowing })
        #expect(locker.lastDuration == 300)
        coordinator.stop()
    }

    @Test func recoveredCompletionCannotDismissTheNextOwedOverlay() {
        let time = ManualCoordinatorClock()
        let a = makeSchedule(breakInterval: 100)
        let b = makeSchedule(breakInterval: 100)
        let first = BreakEvent(scheduledAt: time.clock.now().addingTimeInterval(-300), duration: 300,
                               level: .gentle, scheduleId: a.id)
        let next = BreakEvent(scheduledAt: time.clock.now(), duration: 300, level: .gentle, scheduleId: b.id)
        let state = EnforcementState(recovery: BreakRecoveryState(breaks: [
            a.id: InterruptedBreak(event: first, remainingDuration: 30),
            b.id: InterruptedBreak(event: next, remainingDuration: 180)], ownerScheduleID: a.id))
        let locker = MockLocker()
        let coordinator = BreakCoordinator(scheduler: ScheduleEvaluator(), detector: MockDetector(),
                                           locker: locker, clock: time.clock)
        coordinator.start(with: [a, b], preferences: AppPreferences(), restoring: state, verifiedRestDuration: 30)
        #expect(coordinator.currentStatistics.breaksCompleted == 1)
        #expect(locker.lastBreakID == next.id)
        #expect(locker.lastDuration == 150)
        #expect(locker.isShowing)
        coordinator.stop()
    }

    @Test func cancellingAQuitPromptPreservesRemainingWorkInsteadOfRestartingTheInterval() {
        let time = ManualCoordinatorClock()
        let schedule = makeSchedule(breakInterval: 2700)
        let coordinator = start(time, MockLocker(), schedule: schedule)
        time.advance(1200)
        coordinator.suspendForTerminationPrompt()
        time.advance(30)
        coordinator.resumeAfterTerminationPrompt()
        #expect(coordinator.captureEnforcementState().pendingBreakDates[schedule.id] == time.clock.now().addingTimeInterval(1500))
        coordinator.stop()
    }

    @Test(arguments: [false, true])
    func pendingPresentationWaitsForAnEligibleSchedule(disable: Bool) async {
        let time = ManualCoordinatorClock()
        var schedule = makeSchedule(breakInterval: 100, breakDuration: 300)
        schedule.windows = [TimeWindow(startHour: 10, startMinute: 0, endHour: 10, endMinute: 2)]
        let locker = MockLocker()
        let coordinator = BreakCoordinator(scheduler: ScheduleEvaluator(), detector: MockDetector(),
                                           locker: locker, clock: time.clock)
        var canWrite = false
        coordinator.onCheckpoint = { _, _ in canWrite }
        coordinator.start(with: [schedule], preferences: AppPreferences())
        time.advance(100)
        #expect(await waitUntil { coordinator.hasUnfinishedBreak })
        #expect(!locker.isShowing)
        if disable {
            let state = coordinator.captureEnforcementState()
            coordinator.stop()
            schedule.isEnabled = false
            let rebuilt = BreakCoordinator(scheduler: ScheduleEvaluator(), detector: MockDetector(),
                                            locker: locker, clock: time.clock)
            rebuilt.onCheckpoint = { _, _ in true }
            rebuilt.start(with: [schedule], preferences: AppPreferences(), restoring: state)
            #expect(!locker.isShowing)
            #expect(rebuilt.captureEnforcementState().recovery?.breaks[schedule.id]?.remainingDuration == 300)
            rebuilt.stop()
        } else {
            time.advance(30)
            canWrite = true
            time.advance(5)
            for _ in 0..<30 { await Task.yield() }
            #expect(!locker.isShowing)
            #expect(coordinator.captureEnforcementState().recovery?.breaks[schedule.id]?.remainingDuration == 300)
            #expect(coordinator.currentStatistics.breaksCompleted == 0)
            coordinator.stop()
        }
    }
}
