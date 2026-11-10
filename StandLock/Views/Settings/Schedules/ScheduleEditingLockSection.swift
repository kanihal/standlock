import SwiftUI
import StandLockCore

struct ScheduleEditingLockSection: View {
    let schedule: Schedule
    let hasUnsavedEdits: Bool
    @EnvironmentObject private var coordinator: AppCoordinator

    var body: some View {
        SettingsSection("Schedule Editing") {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Label(isLocked ? "Editing Locked" : "Schedule Editing", systemImage: isLocked ? "lock.fill" : "lock.open")
                        .font(.headline)
                    Spacer()
                    if isLocked {
                        Button("Unlock Editing") { coordinator.openScheduleChallenge(schedule) }
                            .buttonStyle(.borderedProminent)
                    } else {
                        Button(coordinator.scheduleEditLocks.records[schedule.id] == nil ? "Lock Schedule" : "Lock Now") {
                            coordinator.lockScheduleEditing(schedule.id)
                        }
                        .disabled(hasUnsavedEdits)
                    }
                }
                if isLocked {
                    Text("Solve 15 randomized graduate math problems to unlock editing for one hour. Each correct answer credits two minutes toward 30 minutes.")
                        .font(.subheadline).foregroundStyle(.secondary)
                } else if let until = coordinator.scheduleEditLocks.records[schedule.id]?.unlockedUntil {
                    Text("Editing unlock expires at \(until.formatted(date: .omitted, time: .shortened)).")
                        .font(.subheadline).foregroundStyle(.secondary)
                } else {
                    Text("Lock this schedule to require a math challenge before editing, disabling, or deleting it.")
                        .font(.subheadline).foregroundStyle(.secondary)
                }
                if hasUnsavedEdits && !isLocked {
                    Text("Save or discard your changes before locking.")
                        .font(.caption).foregroundStyle(.secondary)
                }
                if isLocked && hasUnsavedEdits {
                    Text("Your unsaved changes are preserved. Unlock editing to save them.")
                        .font(.caption).foregroundStyle(.orange)
                }
            }
            .padding(SettingsTokens.rowInsets)
        }
    }

    private var isLocked: Bool { coordinator.scheduleEditLocks.isLocked(schedule.id) }
}
