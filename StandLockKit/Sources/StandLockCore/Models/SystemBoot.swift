import Foundation

public struct SystemBoot: Codable, Sendable {
    public var id: String
    public var startedAt: Date

    public init(id: String, startedAt: Date) {
        self.id = id
        self.startedAt = startedAt
    }
}
