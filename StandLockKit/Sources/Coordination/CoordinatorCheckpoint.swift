import Foundation
import StandLockCore

public struct CoordinatorCheckpoint: Codable, Sendable {
    public let version: Int
    public var savedAt: Date
    public var enforcement: EnforcementState
    public var statistics: BreakStatistics
    public var dailyRecord: DailyBreakRecord?
    public var exit: SystemExitRecord?

    public init(enforcement: EnforcementState, statistics: BreakStatistics,
                dailyRecord: DailyBreakRecord? = nil, exit: SystemExitRecord? = nil, savedAt: Date = Date()) {
        version = 1
        self.enforcement = enforcement
        self.statistics = statistics
        self.dailyRecord = dailyRecord
        self.exit = exit
        self.savedAt = savedAt
    }

    private enum CodingKeys: String, CodingKey { case version, savedAt, enforcement, statistics, dailyRecord, exit }

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        version = try values.decode(Int.self, forKey: .version)
        guard version == 1 else {
            throw DecodingError.dataCorruptedError(forKey: .version, in: values,
                                                    debugDescription: "Unsupported coordinator checkpoint")
        }
        savedAt = try values.decode(Date.self, forKey: .savedAt)
        enforcement = try values.decode(EnforcementState.self, forKey: .enforcement)
        statistics = try values.decode(BreakStatistics.self, forKey: .statistics)
        dailyRecord = try values.decodeIfPresent(DailyBreakRecord.self, forKey: .dailyRecord)
        exit = try values.decodeIfPresent(SystemExitRecord.self, forKey: .exit)
    }
}
