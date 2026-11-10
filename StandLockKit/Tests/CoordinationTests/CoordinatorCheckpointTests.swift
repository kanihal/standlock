import Foundation
import Testing
@testable import Coordination
import StandLockCore

@Suite("Atomic coordinator checkpoints")
struct CoordinatorCheckpointTests {
    @Test func completionAndConsumedRecoveryRoundTripTogether() throws {
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: folder) }
        let store = CoordinatorCheckpointStore(url: folder.appendingPathComponent("state.json"))
        #expect(try store.load() == nil)
        var stats = BreakStatistics()
        stats.breaksCompleted = 1
        let checkpoint = CoordinatorCheckpoint(enforcement: EnforcementState(recovery: BreakRecoveryState()),
            statistics: stats, dailyRecord: DailyBreakRecord(dateKey: "2026-11-10", breaksCompleted: 1))
        try store.save(checkpoint)
        let loaded = try store.load()
        let restored = try #require(loaded)
        #expect(restored.statistics.breaksCompleted == 1)
        #expect(restored.enforcement.recovery?.breaks.isEmpty == true)
        #expect(restored.dailyRecord?.breaksCompleted == 1)
    }

    @Test func corruptOrInterruptedWriteRetainsLastValidCheckpoint() throws {
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: folder) }
        let url = folder.appendingPathComponent("state.json")
        let store = CoordinatorCheckpointStore(url: url)
        let first = CoordinatorCheckpoint(enforcement: EnforcementState(), statistics: BreakStatistics())
        try store.save(first)
        var second = first
        second.statistics.breaksCompleted = 1
        try store.save(second)
        try Data("truncated".utf8).write(to: url)
        #expect(try store.load()?.statistics.breaksCompleted == 0)
        try store.save(second)
        #expect(try store.load()?.statistics.breaksCompleted == 1)
        var invalid = second
        invalid.enforcement.recovery = BreakRecoveryState(remainingWork: [UUID(): .infinity])
        #expect(throws: (any Error).self) { try store.save(invalid) }
        #expect(try store.load()?.statistics.breaksCompleted == 1)
    }

    @Test func legacyEnforcementStateDecodesWithoutRecovery() throws {
        let state = try JSONDecoder().decode(EnforcementState.self, from: Data("{}".utf8))
        #expect(state.recovery == nil)
        #expect(state.consecutiveDismissalCounts.isEmpty)
    }

    @Test func failedReplacementDoesNotRemoveTheExistingCheckpoint() throws {
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: folder) }
        let url = folder.appendingPathComponent("state.json")
        let store = CoordinatorCheckpointStore(url: url)
        let first = CoordinatorCheckpoint(enforcement: EnforcementState(), statistics: BreakStatistics())
        try store.save(first)
        try FileManager.default.createDirectory(at: url.appendingPathExtension("previous"), withIntermediateDirectories: false)
        var next = first
        next.statistics.breaksCompleted = 1
        #expect(throws: (any Error).self) { try store.save(next) }
        #expect(try store.load()?.statistics.breaksCompleted == 0)
    }
}
