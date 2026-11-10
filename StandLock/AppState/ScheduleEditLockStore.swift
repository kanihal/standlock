import AppKit
import Combine
import StandLockCore

/// The platform adapter owns persistence and a monotonic runtime clock; all challenge
/// decisions live in StandLockCore. Nothing in this store changes break enforcement.
@MainActor
final class ScheduleEditLockStore: ObservableObject {
    @Published private(set) var records: [UUID: ScheduleEditLockRecord] = [:]
    @Published private(set) var displayDate = Date()
    private let defaults: UserDefaults
    private let prefix = "scheduleEditLock."
    private let originDate = Date()
    private let originInstant = ContinuousClock.now
    private var timer: Timer?
    private var random = SystemRandomNumberGenerator()

    var now: Date {
        let duration = originInstant.duration(to: ContinuousClock.now).components
        return originDate.addingTimeInterval(Double(duration.seconds) + Double(duration.attoseconds) / 1e18)
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        for key in defaults.dictionaryRepresentation().keys where key.hasPrefix(prefix) {
            guard let id = UUID(uuidString: String(key.dropFirst(prefix.count))) else { continue }
            // Presence with a wrong type is corrupt, never an implicit unlock.
            records[id] = ScheduleEditLockRecord.restore(defaults.data(forKey: key) ?? Data(), at: now)
        }
        let timer = Timer(timeInterval: 1, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.tick() }
        }
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
    }

    func isLocked(_ id: UUID) -> Bool { records[id]?.isLocked(at: now) == true }

    func lock(_ id: UUID) {
        var record = records[id] ?? ScheduleEditLockRecord()
        record.lock()
        persist(record, for: id)
    }

    func remove(_ id: UUID) {
        defaults.removeObject(forKey: prefix + id.uuidString)
        records.removeValue(forKey: id)
    }

    func begin(_ id: UUID) {
        guard var record = records[id], record.isLocked(at: now) else { return }
        if record.session == nil {
            record.session = MathUnlockSession(now: now)
            record.deck.startAttempt()
        } else if record.session?.advance(to: now) == true {
            record.session = MathUnlockSession(now: now)
            record.deck.startAttempt()
        }
        installQuestion(in: &record)
        persist(record, for: id)
    }

    func focus(_ focused: Bool, scheduleID: UUID) {
        guard var record = records[scheduleID], record.session != nil else { return }
        let previous = record.session?.problem?.id
        record.session?.setFocused(focused, at: now)
        if previous != nil && record.session?.problem == nil { record.deck.startAttempt() }
        persist(record, for: scheduleID)
    }

    func interact(scheduleID: UUID) {
        guard var record = records[scheduleID], record.isLocked(at: now), record.session != nil else { return }
        if record.session?.interact(at: now) == true { record.deck.startAttempt() }
        if record.session?.isPaused == false { installQuestion(in: &record) }
        persist(record, for: scheduleID)
    }

    func submit(_ answer: String, questionID: UUID, scheduleID: UUID) -> MathUnlockSession.Submission {
        guard var record = records[scheduleID], record.isLocked(at: now), record.session != nil else { return .paused }
        let previous = record.session?.problem?.id
        let result = record.session?.submit(answer, questionID: questionID, at: now) ?? .paused
        if result == .completed {
            record.grantEditing(at: now)
        } else if result == .correct {
            installQuestion(in: &record)
        } else if previous != nil && record.session?.problem == nil {
            record.deck.startAttempt()
            if record.session?.isPaused == false { installQuestion(in: &record) }
        }
        // Publish success only after its complete envelope has been stored.
        return persist(record, for: scheduleID) ? result : .paused
    }

    func pauseAll() {
        for id in Array(records.keys) { focus(false, scheduleID: id) }
    }

    func retainSchedules(_ ids: Set<UUID>) {
        for id in Array(records.keys) where !ids.contains(id) { remove(id) }
    }

    private func tick() {
        guard !records.isEmpty else { return }
        displayDate = now
        for id in Array(records.keys) {
            guard var record = records[id], record.session != nil else { continue }
            if record.session?.advance(to: now) == true { record.deck.startAttempt() }
            persist(record, for: id)
        }
    }

    private func installQuestion(in record: inout ScheduleEditLockRecord) {
        guard record.session?.problem == nil else { return }
        let question = MathProblemCatalog.draw(deck: &record.deck, using: &random)
        record.session?.install(question)
    }

    @discardableResult
    private func persist(_ record: ScheduleEditLockRecord, for id: UUID) -> Bool {
        guard let data = try? JSONEncoder().encode(record) else { return false }
        defaults.set(data, forKey: prefix + id.uuidString)
        records[id] = record
        return true
    }
}
