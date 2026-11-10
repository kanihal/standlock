import Foundation

/// An absent record is editable. A present record is protected until a challenge grants
/// a temporary deadline. One encoded envelope makes the final answer and unlock atomic.
public struct ScheduleEditLockRecord: Codable, Equatable, Sendable {
    public private(set) var unlockedUntil: Date?
    public var session: MathUnlockSession?
    public var deck = MathQuestionDeck()

    public init() {}

    public func isLocked(at now: Date) -> Bool { unlockedUntil.map { now >= $0 } ?? true }

    public mutating func grantEditing(at now: Date) {
        unlockedUntil = now.addingTimeInterval(3600)
        session = nil
    }

    public mutating func lock() {
        unlockedUntil = nil
        session = nil
        deck.startAttempt()
    }

    public static func restore(_ data: Data?, at now: Date) -> Self? {
        guard let data else { return nil }
        guard var record = try? JSONDecoder().decode(Self.self, from: data),
              record.unlockedUntil.map({ $0.timeIntervalSince1970.isFinite && $0 <= now.addingTimeInterval(3600) }) ?? true,
              record.deck.isValid,
              record.session.map({ $0.isValid && $0.hasValidTimestamps(at: now) }) ?? true
        else { return Self() }
        if record.isLocked(at: now), record.session != nil {
            let hadProblem = record.session?.problem != nil
            record.session?.restore(at: now)
            if hadProblem && record.session?.problem == nil { record.deck.startAttempt() }
        } else {
            record.session = nil
        }
        return record
    }
}
