import Foundation
import CoreServices
import StandLockCore

public enum QuitReasonReader {
    @MainActor public static var currentReason: SystemTerminationReason {
        reason(for: NSAppleEventManager.shared().currentAppleEvent)
    }

    public static func reason(for event: NSAppleEventDescriptor?) -> SystemTerminationReason {
        guard let event, event.eventClass == AEEventClass(kCoreEventClass),
              event.eventID == AEEventID(kAEQuitApplication) else { return .ordinaryQuit }
        let descriptor = event.paramDescriptor(forKeyword: AEKeyword(kAEQuitReason))
            ?? event.attributeDescriptor(forKeyword: AEKeyword(kAEQuitReason))
        switch descriptor?.typeCodeValue {
        case OSType(kAEShutDown): return .shutdown
        case OSType(kAERestart): return .restart
        case OSType(kAELogOut), OSType(kAEReallyLogOut): return .logout
        case OSType(kAEQuitAll): return .systemQuitAll
        default: return .ordinaryQuit
        }
    }
}
