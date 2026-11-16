import Foundation
import Coordination

/// App-lifetime heartbeat; frequent transition and break saves postpone the next disk write.
@MainActor
final class ActivityCheckpointMonitor {
    private var cadence = ActivityCheckpointCadence()
    private var task: Task<Void, Never>?
    private let clock = CoordinatorClock.live

    func recordSave() { cadence.recordSave(at: clock.elapsed()) }

    func start(save: @escaping @MainActor () -> Bool) {
        task?.cancel()
        task = Task { [weak self] in
            while let self, !Task.isCancelled {
                let remaining = self.cadence.remaining(at: self.clock.elapsed())
                if remaining > 0 {
                    do { try await self.clock.sleep(remaining) } catch { return }
                    continue
                }
                if save() { self.recordSave() }
                else {
                    do { try await self.clock.sleep(5) } catch { return }
                }
            }
        }
    }

    deinit { task?.cancel() }
}
