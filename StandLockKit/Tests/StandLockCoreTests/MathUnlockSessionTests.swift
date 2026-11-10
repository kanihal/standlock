import Foundation
import Testing
@testable import StandLockCore

@Suite("Schedule math unlock")
struct MathUnlockSessionTests {
    private let start = Date(timeIntervalSince1970: 1_800_000_000)

    private func problem() -> MathProblem {
        MathProblem(templateID: "LA01", topic: .linearAlgebra, title: "Fixture",
                    parameters: MathParameters([1,2,3,4,5,6,7,8]), prompt: "Value?", answer: 7)
    }

    @Test func fifteenDistinctCorrectAnswersCompleteWithoutPassiveCredit() {
        var session = MathUnlockSession(now: start)
        session.setFocused(true, at: start)
        session.interact(at: start)
        for count in 1...15 {
            let question = problem()
            session.install(question)
            #expect(session.submit("8", questionID: question.id, at: start) == .incorrect)
            #expect(session.submit("7", questionID: question.id, at: start) == (count == 15 ? .completed : .correct))
            #expect(session.creditedSeconds == Double(count * 120))
            #expect(session.submit("7", questionID: question.id, at: start) == .staleQuestion)
        }
    }

    @Test func idlePausesAtSixtyAndResetStartsAtLastInput() {
        var session = MathUnlockSession(now: start)
        session.setFocused(true, at: start)
        session.interact(at: start)
        session.install(problem())
        session.advance(to: start.addingTimeInterval(59))
        #expect(!session.isPaused)
        session.advance(to: start.addingTimeInterval(60))
        #expect(session.isPaused)
        #expect(session.pauseStartedAt == start)
        #expect(session.activeSeconds == 60)
        session.advance(to: start.addingTimeInterval(300))
        #expect(session.problem != nil)
        session.advance(to: start.addingTimeInterval(300.001))
        #expect(session.problem == nil)
        #expect(session.creditedSeconds == 0)
    }

    @Test func focusLossDoesNotRestartAnExistingBreak() {
        var session = MathUnlockSession(now: start)
        session.setFocused(true, at: start)
        session.interact(at: start)
        session.install(problem())
        session.setFocused(false, at: start.addingTimeInterval(10))
        session.setFocused(false, at: start.addingTimeInterval(50))
        #expect(session.pauseStartedAt == start.addingTimeInterval(10))
        session.setFocused(true, at: start.addingTimeInterval(299))
        session.interact(at: start.addingTimeInterval(299))
        #expect(session.problem != nil)
    }

    @Test func idleCauseBackdatesAnAlreadyPausedWindowBreak() {
        var session = MathUnlockSession(now: start)
        session.setFocused(true, at: start)
        session.interact(at: start)
        session.install(problem())
        session.setFocused(false, at: start.addingTimeInterval(10))
        session.advance(to: start.addingTimeInterval(60))
        #expect(session.pauseStartedAt == start)
        session.advance(to: start.addingTimeInterval(301))
        #expect(session.problem == nil)
    }

    @Test func corruptSessionOrDeckCannotPreserveATemporaryUnlock() throws {
        var record = ScheduleEditLockRecord()
        record.grantEditing(at: start)
        var json = try #require(JSONSerialization.jsonObject(with: JSONEncoder().encode(record)) as? [String: Any])
        json["deck"] = ["remaining": ["linearAlgebra": [99]], "topics": []] as [String: Any]
        let data = try JSONSerialization.data(withJSONObject: json)
        let restored = try #require(ScheduleEditLockRecord.restore(data, at: start))
        #expect(restored.isLocked(at: start))
        #expect(restored.session == nil)
    }

    @Test func malformedFiniteDurationsAndFutureTimestampsFailClosed() throws {
        var record = ScheduleEditLockRecord()
        var session = MathUnlockSession(now: start)
        session.install(problem())
        record.session = session
        let original = try #require(JSONSerialization.jsonObject(with: JSONEncoder().encode(record)) as? [String: Any])
        for (key, value) in [("activeSeconds", 1e300), ("pauseStartedAt", 1e300), ("lastInputAt", 1e300)] {
            var json = original
            var changed = try #require(json["session"] as? [String: Any])
            changed[key] = value
            json["session"] = changed
            let restored = try #require(ScheduleEditLockRecord.restore(JSONSerialization.data(withJSONObject: json), at: start))
            #expect(restored.isLocked(at: start))
            #expect(restored.session == nil)
        }
        var json = original
        json["unlockedUntil"] = 1e300
        let restored = try #require(ScheduleEditLockRecord.restore(JSONSerialization.data(withJSONObject: json), at: start))
        #expect(restored.isLocked(at: start))
    }

    @Test func submissionAfterLongBreakCannotUseTheOldQuestion() {
        var session = MathUnlockSession(now: start)
        session.setFocused(true, at: start)
        session.interact(at: start)
        let old = problem()
        session.install(old)
        #expect(session.submit("7", questionID: old.id, at: start.addingTimeInterval(301)) == .staleQuestion)
        #expect(session.creditedSeconds == 0)
    }

    @Test func restorationUsesKnownLastInputAndPreservesShortPauses() throws {
        var session = MathUnlockSession(now: start)
        session.setFocused(true, at: start)
        session.interact(at: start)
        let question = problem()
        session.install(question)
        var record = ScheduleEditLockRecord()
        record.session = session
        let data = try JSONEncoder().encode(record)
        let short = ScheduleEditLockRecord.restore(data, at: start.addingTimeInterval(300))
        #expect(short?.session?.problem?.id == question.id)
        #expect(short?.session?.isPaused == true)
        let long = ScheduleEditLockRecord.restore(data, at: start.addingTimeInterval(301))
        #expect(long?.session?.problem == nil)
        #expect(long?.isLocked(at: start.addingTimeInterval(301)) == true)
        #expect(ScheduleEditLockRecord.restore(nil, at: start) == nil)
        #expect(ScheduleEditLockRecord.restore(Data("bad".utf8), at: start)?.isLocked(at: start) == true)
    }

    @Test func unlockExpiresExactlyOneHourLater() {
        var record = ScheduleEditLockRecord()
        record.grantEditing(at: start)
        #expect(!record.isLocked(at: start.addingTimeInterval(3599.999)))
        #expect(record.isLocked(at: start.addingTimeInterval(3600)))
    }

    @Test func mutationPolicyProtectsOnlyChangedOrRemovedLockedSchedules() {
        let first = Schedule(name: "First", days: .weekdays, windows: [], breakInterval: 60, breakDuration: 60)
        var second = first
        second.name = "Changed"
        let locks = [first.id: ScheduleEditLockRecord()]
        #expect(ScheduleEditPolicy.blockedIDs(current: [first], incoming: [first], locks: locks, at: start).isEmpty)
        #expect(ScheduleEditPolicy.blockedIDs(current: [first], incoming: [second], locks: locks, at: start) == [first.id])
        #expect(ScheduleEditPolicy.blockedIDs(current: [first], incoming: [], locks: locks, at: start) == [first.id])
        var unlocked = ScheduleEditLockRecord()
        unlocked.grantEditing(at: start)
        #expect(ScheduleEditPolicy.blockedIDs(current: [first], incoming: [second], locks: [first.id: unlocked], at: start).isEmpty)
        #expect(ScheduleEditPolicy.blockedIDs(current: [first], incoming: [second], locks: [first.id: unlocked], at: start.addingTimeInterval(3600)) == [first.id])
    }
}
