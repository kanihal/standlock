import Foundation
import Darwin
import StandLockCore

/// Read-only Darwin APIs. Unavailable accounting history is unknown, never inferred rest.
public struct ShutdownHistoryReader: Sendable {
    private static let accountingLock = NSLock()

    public init() {}

    public func currentBoot() -> SystemBoot? {
        var size = 0
        guard sysctlbyname("kern.bootsessionuuid", nil, &size, nil, 0) == 0, size > 1 else { return nil }
        var bytes = [CChar](repeating: 0, count: size)
        guard sysctlbyname("kern.bootsessionuuid", &bytes, &size, nil, 0) == 0 else { return nil }
        let id = String(decoding: bytes.prefix { $0 != 0 }.map { UInt8(bitPattern: $0) }, as: UTF8.self)
        var time = timeval()
        size = MemoryLayout<timeval>.size
        guard !id.isEmpty, sysctlbyname("kern.boottime", &time, &size, nil, 0) == 0 else { return nil }
        return SystemBoot(id: id, startedAt: Date(timeIntervalSince1970:
            Double(time.tv_sec) + Double(time.tv_usec) / 1_000_000))
    }

    public func verifiedRest(after exit: SystemExitRecord) -> TimeInterval? {
        guard let boot = currentBoot(), boot.startedAt <= Date() else { return nil }
        return ShutdownRestVerifier.duration(after: exit, currentBoot: boot,
                                             history: history(since: exit.boot.startedAt))
    }

    public func history(since date: Date) -> [SystemLifecycleEvent] {
        Self.accountingLock.withLock {
            setutxent_wtmp(0)
            defer { endutxent_wtmp() }
            var events: [SystemLifecycleEvent] = []
            for _ in 0..<10_000 {
                guard let pointer = getutxent_wtmp() else { break }
                let entry = pointer.pointee
                let kind: SystemLifecycleEvent.Kind
                switch Int(entry.ut_type) {
                case Int(BOOT_TIME): kind = .boot
                case Int(SHUTDOWN_TIME): kind = .shutdown
                case Int(OLD_TIME), Int(NEW_TIME): kind = .clockChange
                default: continue
                }
                let timestamp = Date(timeIntervalSince1970:
                    Double(entry.ut_tv.tv_sec) + Double(entry.ut_tv.tv_usec) / 1_000_000)
                events.append(SystemLifecycleEvent(kind: kind, date: timestamp))
                if kind == .boot, abs(timestamp.timeIntervalSince(date)) <= 120 { break }
            }
            return events.reversed()
        }
    }
}
