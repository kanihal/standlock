import SwiftUI
import StandLockCore

struct ScheduleFormView: View {
    @Binding var draft: ScheduleDraft
    /// The stored schedule, nil for a new one.
    let schedule: Schedule?

    var body: some View {
        nameSection
        if schedule == nil {
            TemplateRow(draft: $draft)
        }
        whenSection
        rhythmSection
        DayPreviewCard(draft: draft, schedule: schedule)
            .equatable()
        disciplineSection
    }

    // MARK: - Sections

    private var nameSection: some View {
        SettingsSection {
            SettingsRow("Name", symbol: "textformat", expandsTitle: false) {
                TextField("e.g. Work Hours", text: $draft.name)
                    .labelsHidden()
                    .accessibilityLabel("Name")
                    .textFieldStyle(.roundedBorder)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    private var whenSection: some View {
        SettingsSection("When") {
            DayButtons(days: $draft.days)
                .padding(SettingsTokens.rowInsets)
            Divider()
            ScheduleHoursEditor(draft: $draft)
        }
    }

    private var rhythmSection: some View {
        ScheduleRhythmSection(draft: $draft)
    }

    private var disciplineSection: some View {
        SettingsSection("Discipline") {
            DisciplineLevelPicker(selection: $draft.disciplineLevel)
                .padding(SettingsTokens.rowInsets)
            Divider()
            SettingsToggleRow(
                "Progressive Enforcement",
                symbol: "chart.line.uptrend.xyaxis",
                description: "Makes each skipped break harder to dismiss",
                isOn: $draft.progressiveEnforcement
            )
            if draft.progressiveEnforcement {
                Divider()
                SettingsToggleRow(
                    "Limit consecutive skips",
                    symbol: "lock",
                    description: "Skip up to \(draft.consecutiveSkipLimit ?? 2) breaks in a row. After that, skipping and Control + Option + Command are disabled until you complete a break.",
                    isOn: Binding(
                        get: { draft.consecutiveSkipLimit != nil },
                        set: { draft.consecutiveSkipLimit = $0 ? 2 : nil }
                    )
                )
                if draft.consecutiveSkipLimit != nil {
                    SettingsRow(
                        "Maximum consecutive skips", symbol: "arrow.turn.down.right",
                        description: "Skip Next Break and emergency exits count toward this limit. Completing a break resets it; enough time locked or asleep does too."
                    ) {
                        Stepper(value: Binding(
                            get: { draft.consecutiveSkipLimit ?? 2 },
                            set: { draft.consecutiveSkipLimit = $0 }
                        ), in: 1...20) {
                            Text("\(draft.consecutiveSkipLimit ?? 2)")
                                .monospacedDigit()
                        }
                        .fixedSize()
                    }
                    .padding(.leading, SettingsTokens.rowChipSize + SettingsTokens.rowSpacing)
                }
            }
        }
    }

}
