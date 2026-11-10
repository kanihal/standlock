import Foundation

public enum ScheduleEditPolicy {
    /// Compare whole stored values, including enablement and values hidden by the form.
    /// The caller checks this before *any* part of a settings import takes effect.
    public static func blockedIDs(
        current: [Schedule], incoming: [Schedule], locks: [UUID: ScheduleEditLockRecord], at now: Date
    ) -> [UUID] {
        current.compactMap { schedule in
            guard locks[schedule.id]?.isLocked(at: now) == true,
                  incoming.first(where: { $0.id == schedule.id }) != schedule else { return nil }
            return schedule.id
        }
    }
}
