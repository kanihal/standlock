import Foundation
import Testing
import CoreServices
@testable import Detection
import StandLockCore

@Suite("Verified powered-off rest")
struct ShutdownRestTests {
    private let origin = Date(timeIntervalSince1970: 1_800_000_000)
    private func date(_ seconds: Double) -> Date { origin.addingTimeInterval(seconds) }

    @Test func creditStopsAtFirstBootDespiteDelayedLaunchAndMoreReboots() {
        let exit = SystemExitRecord(reason: .shutdown, requestedAt: date(100),
                                    boot: SystemBoot(id: "old", startedAt: date(0)))
        let history: [SystemLifecycleEvent] = [
            .init(kind: .boot, date: date(0)), .init(kind: .shutdown, date: date(120)),
            .init(kind: .boot, date: date(720)), .init(kind: .shutdown, date: date(2000)),
            .init(kind: .boot, date: date(3000))]
        #expect(ShutdownRestVerifier.duration(after: exit,
            currentBoot: SystemBoot(id: "new", startedAt: date(3000)), history: history) == 600)
    }

    @Test func cancelledRequestDoesNotCreditWorkBeforeAnEventualShutdown() {
        let exit = SystemExitRecord(reason: .restart, requestedAt: date(100),
                                    boot: SystemBoot(id: "old", startedAt: date(0)))
        let history: [SystemLifecycleEvent] = [.init(kind: .boot, date: date(0)),
            .init(kind: .shutdown, date: date(10000)), .init(kind: .boot, date: date(10030))]
        #expect(ShutdownRestVerifier.duration(after: exit,
            currentBoot: SystemBoot(id: "new", startedAt: date(10030)), history: history) == 30)
        #expect(ShutdownRestVerifier.duration(after: exit, currentBoot: exit.boot, history: history) == nil)
    }

    @Test(arguments: [SystemTerminationReason.ordinaryQuit, .logout, .systemQuitAll, .relaunch])
    func otherTerminationReasonsEarnNoCredit(reason: SystemTerminationReason) {
        let exit = SystemExitRecord(reason: reason, requestedAt: date(100),
                                    boot: SystemBoot(id: "old", startedAt: date(0)))
        #expect(ShutdownRestVerifier.duration(after: exit,
            currentBoot: SystemBoot(id: "new", startedAt: date(1000)),
            history: [.init(kind: .boot, date: date(0)), .init(kind: .shutdown, date: date(120)),
                      .init(kind: .boot, date: date(1000))]) == nil)
    }

    @Test func missingShutdownOrClockAmbiguityDoesNotCreditRest() {
        let exit = SystemExitRecord(reason: .shutdown, requestedAt: date(100),
                                    boot: SystemBoot(id: "old", startedAt: date(0)))
        let boot = SystemBoot(id: "new", startedAt: date(1000))
        let before = SystemLifecycleEvent(kind: .boot, date: date(0))
        let after = SystemLifecycleEvent(kind: .boot, date: date(1000))
        #expect(ShutdownRestVerifier.duration(after: exit, currentBoot: boot, history: [before, after]) == nil)
        #expect(ShutdownRestVerifier.duration(after: exit, currentBoot: boot, history: [before,
            .init(kind: .clockChange, date: date(200)), .init(kind: .shutdown, date: date(300)), after]) == nil)
        #expect(ShutdownRestVerifier.duration(after: exit, currentBoot: boot, history: [before,
            .init(kind: .shutdown, date: date(50)), after]) == nil)
        #expect(ShutdownRestVerifier.duration(after: exit, currentBoot: boot, history: []) == nil)
    }

    @Test func quitAppleEventReasonIsDecoded() {
        let cases: [(OSType, SystemTerminationReason)] = [(kAEShutDown, .shutdown), (kAERestart, .restart),
                                                      (kAEReallyLogOut, .logout), (kAEQuitAll, .systemQuitAll)]
        for (code, expected) in cases {
            let event = NSAppleEventDescriptor(eventClass: AEEventClass(kCoreEventClass), eventID: AEEventID(kAEQuitApplication),
                targetDescriptor: nil, returnID: AEReturnID(kAutoGenerateReturnID), transactionID: AETransactionID(kAnyTransactionID))
            event.setParam(NSAppleEventDescriptor(typeCode: OSType(code)), forKeyword: AEKeyword(kAEQuitReason))
            #expect(QuitReasonReader.reason(for: event) == expected)
        }
        #expect(QuitReasonReader.reason(for: nil) == .ordinaryQuit)
    }

    @Test func unknownReasonCannotBypassOrdinaryQuitEnforcement() {
        let event = NSAppleEventDescriptor(eventClass: AEEventClass(kCoreEventClass), eventID: AEEventID(kAEQuitApplication),
            targetDescriptor: nil, returnID: AEReturnID(kAutoGenerateReturnID), transactionID: AETransactionID(kAnyTransactionID))
        event.setParam(NSAppleEventDescriptor(typeCode: 0), forKeyword: AEKeyword(kAEQuitReason))
        #expect(!QuitReasonReader.reason(for: event).allowsTermination(hasUnfinishedBreak: true))
        #expect(SystemTerminationReason.shutdown.allowsTermination(hasUnfinishedBreak: true))
        #expect(SystemTerminationReason.logout.allowsTermination(hasUnfinishedBreak: true))
    }
}
