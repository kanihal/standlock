import Testing
@testable import Coordination

@Suite("Five-minute activity checkpoints")
struct ActivityCheckpointCadenceTests {
    @Test func savesBecomeDueAfterFiveMinutes() {
        var cadence = ActivityCheckpointCadence()
        #expect(cadence.remaining(at: 0) == 0)
        cadence.recordSave(at: 0)
        #expect(cadence.remaining(at: 299) == 1)
        #expect(cadence.remaining(at: 300) == 0)
        #expect(cadence.remaining(at: 600) == 0)
    }

    @Test func transitionSavesCoalesceWithoutExtendingTheGapPastFiveMinutes() {
        var cadence = ActivityCheckpointCadence()
        cadence.recordSave(at: 0)
        cadence.recordSave(at: 299)
        #expect(cadence.remaining(at: 300) == 299)
        #expect(cadence.remaining(at: 599) == 0)
    }
}
