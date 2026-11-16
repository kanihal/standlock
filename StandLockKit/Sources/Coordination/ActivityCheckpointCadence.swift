import Foundation

public struct ActivityCheckpointCadence: Sendable {
    public static let interval: TimeInterval = 300
    private var lastSave: TimeInterval?

    public init() {}

    public mutating func recordSave(at elapsed: TimeInterval) { lastSave = elapsed }

    public func remaining(at elapsed: TimeInterval) -> TimeInterval {
        guard let lastSave else { return 0 }
        return max(0, Self.interval - (elapsed - lastSave))
    }
}
