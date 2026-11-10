import Foundation

public struct SystemExitRecord: Codable, Sendable {
    public var reason: SystemTerminationReason
    public var requestedAt: Date
    public var boot: SystemBoot

    public init(reason: SystemTerminationReason, requestedAt: Date, boot: SystemBoot) {
        self.reason = reason
        self.requestedAt = requestedAt
        self.boot = boot
    }
}
