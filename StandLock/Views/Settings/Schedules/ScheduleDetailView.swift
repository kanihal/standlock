import SwiftUI
import StandLockCore

/// Finds the stored schedule. A nil `id` is a new one.
struct ScheduleDetailView: View {
    let id: UUID?
    let navigation: SettingsNavigation
    @EnvironmentObject private var coordinator: AppCoordinator

    var body: some View {
        let schedule = coordinator.schedules.first { $0.id == id }
        // A deleted schedule is on screen for the moment before the sidebar moves the selection.
        if schedule != nil || id == nil {
            SchedulePage(schedule: schedule, navigation: navigation)
        }
    }
}

/// Holds the draft. Enforcement restarts on every `updateSchedule`, so edits stay here until Save.
private struct SchedulePage: View {
    /// The latest stored value. The draft loads from it once and does not follow it.
    let schedule: Schedule?
    @ObservedObject var navigation: SettingsNavigation

    @EnvironmentObject private var coordinator: AppCoordinator
    // Captured here, not read inside the sheet: a presentation starts a fresh root, so
    // the chosen locale has to be re-applied on the other side of it.
    @EnvironmentObject private var languageStore: LanguageStore
    @State private var draft: ScheduleDraft
    @State private var baseline: ScheduleDraft
    @State private var showDeleteConfirmation = false

    init(schedule: Schedule?, navigation: SettingsNavigation) {
        self.schedule = schedule
        self.navigation = navigation
        let loaded = ScheduleDraft(schedule: schedule)
        _draft = State(initialValue: loaded)
        _baseline = State(initialValue: loaded)
    }

    private var isDirty: Bool { draft.hasChanges(from: baseline) }
    private var isLocked: Bool { schedule.map { coordinator.scheduleEditLocks.isLocked($0.id) } ?? false }

    var body: some View {
        VStack(spacing: 0) {
            SettingsPageLayout(title: title, accessory: { enableToggle }) {
                if let schedule {
                    ScheduleStatusView(schedule: schedule)
                    ScheduleEditingLockSection(schedule: schedule, hasUnsavedEdits: isDirty)
                } else if coordinator.schedules.isEmpty {
                    emptyNote
                }
                ScheduleFormView(draft: $draft, schedule: schedule)
                    .disabled(isLocked)
                    .environment(\.settingsRowTone, .strict)
                    // Not `.keyboardShortcut`: in a pane that reaches the whole window, sidebar
                    // and search included. These two need focus inside the form.
                    .onSubmit { saveAndStay() }
                    .onExitCommand { cancel() }
            }
            Divider()
            footer
        }
        .onAppear { navigation.unsavedEdits = { draft.hasChanges(from: baseline) } }
        .alert(
            "Unsaved Changes",
            isPresented: promptIsPresented,
            presenting: navigation.pendingLeave
        ) { leave in
            // Left out, not disabled: an alert button cannot explain why it is dimmed.
            if draft.canSave && !isLocked {
                Button("Save") {
                    if saveAndStay() { navigation.finish(leave) }
                }
            }
            Button("Discard", role: .destructive) {
                draft = baseline
                navigation.finish(leave)
            }
            Button("Cancel", role: .cancel) { navigation.cancelPending() }
        } message: { _ in
            Text(leaveMessage)
        }
        .sheet(isPresented: $showDeleteConfirmation) {
            LocalizedRoot(store: languageStore) {
                DeleteConfirmationView(
                    scheduleName: schedule?.name ?? "",
                    onCancel: { showDeleteConfirmation = false },
                    onDelete: {
                        showDeleteConfirmation = false
                        if let schedule { coordinator.deleteSchedule(schedule) }
                    }
                )
            }
        }
    }

    private var leaveMessage: LocalizedStringKey {
        if isLocked { return "This schedule is locked. Unlock editing to save your changes, or discard them." }
        if draft.canSave { return "Your changes to this schedule have not been saved." }
        if draft.days.isEmpty {
            return draft.hasName
                ? "Pick at least one day to save this schedule, or discard your changes."
                : "Name this schedule and pick at least one day to save it, or discard your changes."
        }
        if draft.hasName && !draft.hasValidLongBreak {
            return "Make the longer break longer than the short break to save this schedule, or discard your changes."
        }
        return "Name this schedule to save it, or discard your changes."
    }

    private var title: Text {
        schedule.map { Text(verbatim: $0.name) } ?? Text("New Schedule")
    }

    @ViewBuilder
    private var enableToggle: some View {
        if let schedule {
            Toggle("Enabled", isOn: Binding(
                get: { schedule.isEnabled },
                set: { enabled in
                    var updated = schedule
                    updated.isEnabled = enabled
                    coordinator.updateSchedule(updated)
                }
            ))
            .labelsHidden()
            .toggleStyle(.switch)
            .tint(.green)
            .controlSize(.small)
            .disabled(isLocked)
        }
    }

    private var emptyNote: some View {
        VStack(alignment: .leading, spacing: SettingsTokens.rowTextSpacing) {
            Text("No Schedules")
                .font(.headline)
            Text("Add a schedule to start taking breaks.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private var footer: some View {
        HStack {
            if schedule != nil {
                Button("Delete", role: .destructive) { showDeleteConfirmation = true }
                    .foregroundStyle(.red)
                    .disabled(isLocked)
            }
            Spacer()
            Button("Cancel") { cancel() }
                .disabled(!isDirty && (schedule != nil || coordinator.schedules.isEmpty))
            Button(schedule == nil ? "Add Schedule" : "Save") { saveAndStay() }
                .buttonStyle(.borderedProminent)
                .disabled(isLocked || !draft.canSubmit(from: baseline))
        }
        .padding(SettingsTokens.footerInsets)
    }

    private var promptIsPresented: Binding<Bool> {
        let navigation = navigation
        return Binding(
            get: { navigation.pendingLeave != nil },
            set: { if !$0 { navigation.cancelPending() } }
        )
    }

    /// Return lands here too, so nothing the Save button would refuse goes through: a nameless
    /// schedule, or a restart of enforcement with nothing changed.
    @discardableResult
    private func saveAndStay() -> Bool {
        guard !isLocked, draft.canSubmit(from: baseline) else { return false }
        let saved = draft.build(existing: schedule)
        let result = schedule == nil ? coordinator.addSchedule(saved) : coordinator.updateSchedule(saved)
        guard case .success = result else { return false }
        // Reloaded because the pane stays open: the form must show what was stored.
        draft = ScheduleDraft(schedule: saved)
        baseline = draft
        if schedule == nil {
            navigation.leave(to: .schedule(saved.id))
        }
        return true
    }

    private func cancel() {
        draft = baseline
        if schedule == nil {
            navigation.leave(to: .firstSchedule(in: coordinator.schedules.map(\.id)))
        }
    }
}
