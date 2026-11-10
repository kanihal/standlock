import Foundation

public enum ScheduleMutationFailure: Error, Equatable, Sendable {
    case locked([UUID])
    case duplicateID
    case missingSchedule
}
