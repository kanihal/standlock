import Foundation

/// Boot-scoped time accompanies the checkpoint's wall time, including across app relaunches.
public struct BootObservation: Codable, Sendable {
    public var boot: SystemBoot
    public var continuousTime: TimeInterval

    public init(boot: SystemBoot, continuousTime: TimeInterval) {
        self.boot = boot
        self.continuousTime = continuousTime
    }
}
