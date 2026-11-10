import SwiftUI
import StandLockCore

struct MathChallengeView: View {
    let scheduleID: UUID
    let scheduleName: String
    @ObservedObject var store: ScheduleEditLockStore
    @State private var answer = ""
    @State private var feedback: LocalizedStringKey?
    @State private var lastWasCorrect = false
    @FocusState private var answerFocused: Bool

    private var record: ScheduleEditLockRecord? { store.records[scheduleID] }
    private var session: MathUnlockSession? { record?.session }
    private var problem: MathProblem? { session?.problem }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                Image(systemName: "lock.open")
                    .font(.title)
                    .foregroundStyle(.tint)
                VStack(alignment: .leading, spacing: 3) {
                    Text("Unlock Editing").font(.title2.bold())
                    Text(verbatim: scheduleName).foregroundStyle(.secondary)
                }
                Spacer()
                Text("120 problem types").font(.caption).foregroundStyle(.secondary)
            }

            if let record, !record.isLocked(at: store.now), let until = record.unlockedUntil {
                Spacer()
                Label("Schedule Unlocked", systemImage: "checkmark.circle.fill")
                    .font(.title2).foregroundStyle(.green)
                Text("Editing is available until \(until.formatted(date: .omitted, time: .shortened)).")
                Text("You can return to Settings to edit this schedule.")
                    .foregroundStyle(.secondary)
                Spacer()
            } else {
                progress
                if let session, session.isPaused { pauseNotice(session) }
                VStack(alignment: .leading, spacing: 14) {
                        if let problem {
                            Text(LocalizedStringKey(problem.topic.title))
                                .font(.caption.weight(.semibold)).foregroundStyle(.secondary)
                            Text(verbatim: problem.title).font(.headline)
                            LatexMathView(prompt: problem.prompt)
                                .frame(minHeight: 180, maxHeight: .infinity)
                        } else {
                            Text("Progress reset after a break longer than five minutes.")
                            Button("Start a Fresh Problem") { resume() }
                        }
                }
                .padding(18)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .background(.quaternary.opacity(0.45), in: RoundedRectangle(cornerRadius: 12))
                if let problem {
                    HStack {
                        TextField("Numeric answer or fraction", text: $answer)
                            .textFieldStyle(.roundedBorder)
                            .focused($answerFocused)
                            .accessibilityLabel("Answer")
                            .onSubmit { submit(problem) }
                        Button("Submit") { submit(problem) }
                            .buttonStyle(.borderedProminent)
                            .disabled(answer.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                    Text(problem.answerKind == .integer
                         ? "Enter an exact integer."
                         : "Enter a fraction or use at least six decimal places. Scientific notation is accepted.")
                        .font(.caption).foregroundStyle(.secondary)
                }
                if let feedback {
                    Text(feedback)
                        .foregroundStyle(lastWasCorrect ? Color.green : Color.orange)
                        .accessibilityAddTraits(.updatesFrequently)
                }
            }
            Divider()
            Text("Each correct answer credits two minutes. Switching windows or going idle for 60 seconds pauses solving. Any break longer than five minutes resets progress.")
                .font(.caption).foregroundStyle(.secondary)
        }
        .padding(24)
        .frame(minWidth: 560, minHeight: 600)
        .onChange(of: problem?.id) { _ in
            answer = ""
            if !lastWasCorrect { feedback = nil }
        }
        .onChange(of: session?.correctAnswers) { count in
            if count == 0 { feedback = nil; lastWasCorrect = false }
        }
        .onChange(of: store.isLocked(scheduleID)) { locked in
            if locked && session == nil { store.begin(scheduleID) }
        }
    }

    private var progress: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("Time credited: \(clock(session?.creditedSeconds ?? 0)) / 30:00")
                    .font(.headline.monospacedDigit())
                Spacer()
                Text("\(session?.correctAnswers ?? 0) / 15 correct")
                    .font(.subheadline.monospacedDigit())
            }
            ProgressView(value: session?.creditedSeconds ?? 0, total: 1800)
            Text("Active solving: \(clock(session?.activeSeconds ?? 0))")
                .font(.caption.monospacedDigit()).foregroundStyle(.secondary)
        }
    }

    private func pauseNotice(_ session: MathUnlockSession) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Label("Paused — interact with this window to resume", systemImage: "pause.circle")
            if let since = session.pauseStartedAt, session.problem != nil {
                Text("Progress resets after \(clock(max(0, 300 - store.now.timeIntervalSince(since)))) away.")
                    .font(.caption.monospacedDigit())
            }
        }
        .foregroundStyle(.secondary)
    }

    private func resume() {
        store.interact(scheduleID: scheduleID)
        answerFocused = true
    }

    private func submit(_ question: MathProblem) {
        let result = store.submit(answer, questionID: question.id, scheduleID: scheduleID)
        lastWasCorrect = result == .correct || result == .completed
        switch result {
        case .correct: feedback = "Correct. Two minutes credited."
        case .completed: feedback = nil
        case .incorrect: feedback = "That answer is incorrect. Try again."
        case .invalidAnswer: feedback = "Enter a finite number or a fraction with a nonzero denominator."
        case .paused: feedback = "Return to this window to resume."
        case .staleQuestion: feedback = "The previous problem expired. Solve the fresh problem to earn credit."
        }
        if lastWasCorrect { answer = "" }
    }

    private func clock(_ seconds: TimeInterval) -> String {
        let bounded = seconds.isFinite ? min(31_622_400, max(0, seconds)) : 0
        let value = Int(bounded.rounded(.down))
        return String(format: "%d:%02d", value / 60, value % 60)
    }
}
