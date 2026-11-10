import Foundation

/// Pure challenge state. The caller supplies time and focus, and installs a new question
/// after a correct answer. Neither wall-clock waiting nor background activity earns credit.
public struct MathUnlockSession: Codable, Equatable, Sendable {
    public enum Submission: Equatable, Sendable {
        case correct, completed, incorrect, invalidAnswer, paused, staleQuestion
    }

    public private(set) var correctAnswers = 0
    public private(set) var problem: MathProblem?
    public private(set) var activeSeconds: TimeInterval = 0
    public private(set) var lastInputAt: Date
    public private(set) var pauseStartedAt: Date?
    public private(set) var isFocused = false
    private var lastAdvancedAt: Date

    public init(now: Date) {
        lastInputAt = now
        lastAdvancedAt = now
        pauseStartedAt = now
    }

    public var creditedSeconds: TimeInterval { Double(correctAnswers * 120) }
    public var isPaused: Bool { !isFocused || pauseStartedAt != nil }

    public var isValid: Bool {
        (0..<15).contains(correctAnswers) && activeSeconds.isFinite && (0...31_622_400).contains(activeSeconds)
            && lastInputAt.timeIntervalSince1970.isFinite
            && lastAdvancedAt.timeIntervalSince1970.isFinite
            && lastInputAt <= lastAdvancedAt
            && (pauseStartedAt?.timeIntervalSince1970.isFinite ?? true)
            && (pauseStartedAt.map { $0 >= lastInputAt && $0 <= lastAdvancedAt } ?? true)
            && (problem?.isValid ?? true)
    }

    public func hasValidTimestamps(at now: Date) -> Bool {
        lastInputAt <= now && lastAdvancedAt <= now && (pauseStartedAt.map { $0 <= now } ?? true)
    }

    public mutating func install(_ question: MathProblem) {
        guard problem == nil, correctAnswers < 15, question.isValid else { return }
        problem = question
    }

    /// Returns true only when this call cleared an existing attempt. A paused reset leaves
    /// no question until fresh input, so background ticks never consume the question bank.
    @discardableResult
    public mutating func advance(to now: Date) -> Bool {
        if now < lastAdvancedAt {
            clearProgress()
            lastInputAt = now
            pauseStartedAt = now
            lastAdvancedAt = now
            return true
        }
        if isFocused && pauseStartedAt == nil {
            let activeUntil = min(now, lastInputAt.addingTimeInterval(60))
            activeSeconds += max(0, activeUntil.timeIntervalSince(lastAdvancedAt))
        }
        // Idle continues to become applicable after focus loss. Once it does, its last-
        // input start can be earlier than the already-recorded focus interruption.
        if now.timeIntervalSince(lastInputAt) >= 60 {
            pauseStartedAt = min(pauseStartedAt ?? lastInputAt, lastInputAt)
        }
        lastAdvancedAt = now
        if let pauseStartedAt, now.timeIntervalSince(pauseStartedAt) > 300,
           problem != nil || correctAnswers != 0 || activeSeconds != 0 {
            clearProgress()
            return true
        }
        return false
    }

    public mutating func setFocused(_ focused: Bool, at now: Date) {
        advance(to: now)
        isFocused = focused
        if !focused && pauseStartedAt == nil { pauseStartedAt = now }
    }

    @discardableResult
    public mutating func interact(at now: Date) -> Bool {
        let reset = advance(to: now)
        guard isFocused else { return reset }
        lastInputAt = now
        lastAdvancedAt = now
        pauseStartedAt = nil
        return reset
    }

    public mutating func submit(_ text: String, questionID: UUID, at now: Date) -> Submission {
        interact(at: now)
        guard let question = problem, question.id == questionID else { return .staleQuestion }
        guard !isPaused else { return .paused }
        guard MathAnswer.parse(text) != nil else { return .invalidAnswer }
        guard MathAnswer.isCorrect(text, expected: question.answer, kind: question.answerKind) else { return .incorrect }
        correctAnswers += 1
        problem = nil
        return correctAnswers == 15 ? .completed : .correct
    }

    public mutating func restore(at now: Date) {
        isFocused = false
        // An unclean exit has no focus-loss notification. The last actual input is the
        // conservative start; a periodic persistence checkpoint must not move it forward.
        if pauseStartedAt == nil { pauseStartedAt = lastInputAt }
        advance(to: now)
        lastAdvancedAt = now
    }

    private mutating func clearProgress() {
        correctAnswers = 0
        activeSeconds = 0
        problem = nil
    }
}
