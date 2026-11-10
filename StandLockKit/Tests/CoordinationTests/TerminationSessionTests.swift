import Testing
import Coordination
import StandLockCore

@Suite("Termination confirmation")
struct TerminationSessionTests {
    @Test func ordinaryQuitCannotDiscardAnOwedHiddenBreak() {
        var session = TerminationSession()
        #expect(session.request(.ordinaryQuit, hasUnfinishedBreak: true, hasUnsavedEdits: false) == .deny)
        #expect(session.pendingReason == nil)
    }

    @Test func systemReasonSurvivesUnsavedSettingsConfirmationAndRepeatedRequests() {
        var session = TerminationSession()
        #expect(session.request(.shutdown, hasUnfinishedBreak: true, hasUnsavedEdits: true) == .wait)
        #expect(session.request(.ordinaryQuit, hasUnfinishedBreak: true, hasUnsavedEdits: true) == .wait)
        #expect(session.finish(confirmed: true) == .shutdown)
        #expect(session.pendingReason == nil)
    }

    @Test func cancellingConfirmationDoesNotAuthorizeALaterOrdinaryQuit() {
        var session = TerminationSession()
        #expect(session.request(.restart, hasUnfinishedBreak: true, hasUnsavedEdits: true) == .wait)
        #expect(session.finish(confirmed: false) == nil)
        #expect(session.request(.ordinaryQuit, hasUnfinishedBreak: true, hasUnsavedEdits: false) == .deny)
    }
}
