import SwiftUI

/// The footer action locks a saved schedule or opens its existing unlock challenge.
struct ScheduleEditingLockButton: View {
    let isLocked: Bool
    let hasUnsavedEdits: Bool
    let onLock: () -> Void
    let onUnlock: () -> Void

    var body: some View {
        Button {
            if isLocked { onUnlock() }
            else { onLock() }
        } label: {
            Image(systemName: isLocked ? "lock.fill" : "lock.open")
                .frame(width: 16)
        }
        .buttonStyle(.bordered)
        .disabled(hasUnsavedEdits && !isLocked)
        .help(help)
        .accessibilityLabel(isLocked ? Text("Unlock Editing") : Text("Lock Schedule"))
        .accessibilityValue(isLocked ? Text("Locked") : Text("Unlocked"))
    }

    private var help: Text {
        if isLocked { return Text("Unlock Editing") }
        if hasUnsavedEdits { return Text("Save or discard your changes before locking.") }
        return Text("Lock Schedule")
    }
}
