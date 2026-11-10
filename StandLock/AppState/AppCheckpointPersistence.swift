import Foundation
import Coordination
import os

/// App-specific location and diagnostics stay outside the scheduling package.
@MainActor
final class AppCheckpointPersistence {
    private let store: CoordinatorCheckpointStore
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "StandLock", category: "Recovery")

    init() {
        let support = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        let identity = Bundle.main.bundleIdentifier ?? "StandLock"
        store = CoordinatorCheckpointStore(url: support.appendingPathComponent("StandLock/Coordinator")
            .appendingPathComponent(identity).appendingPathComponent("checkpoint.json"))
    }

    func load() -> CoordinatorCheckpoint? {
        do { return try store.load() }
        catch {
            logger.error("Could not read coordinator checkpoint: \(error.localizedDescription, privacy: .public)")
            return nil
        }
    }

    func save(_ checkpoint: CoordinatorCheckpoint) -> Bool {
        do {
            try store.save(checkpoint)
            return true
        } catch {
            logger.error("Could not save coordinator checkpoint: \(error.localizedDescription, privacy: .public)")
            return false
        }
    }
}
