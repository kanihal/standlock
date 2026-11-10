import Testing
@testable import StandLockCore

@Suite("Dismissal availability")
struct DismissalAvailabilityTests {
    @Test func capBlocksEveryDismissalAtBoundary() {
        let result = DismissalAvailability(progressiveEnforcement: true, consecutiveSkipLimit: 2,
            consecutiveDismissals: 2, dailySkipLimit: 5, dailySkips: 0)
        #expect(!result.normalSkipAllowed)
        #expect(!result.emergencyEscapeAllowed)
        #expect(result.remainingConsecutiveSkips == 0)
    }

    @Test func dailyQuotaStillAllowsEmergencyExit() {
        let result = DismissalAvailability(progressiveEnforcement: true, consecutiveSkipLimit: 2,
            consecutiveDismissals: 1, dailySkipLimit: 1, dailySkips: 1)
        #expect(!result.normalSkipAllowed)
        #expect(result.emergencyEscapeAllowed)
        #expect(result.remainingConsecutiveSkips == 1)
    }

    @Test func disabledProgressiveEnforcementIgnoresCap() {
        let result = DismissalAvailability(progressiveEnforcement: false, consecutiveSkipLimit: 2,
            consecutiveDismissals: 20, dailySkipLimit: nil, dailySkips: 0)
        #expect(result.normalSkipAllowed && result.emergencyEscapeAllowed)
        #expect(result.remainingConsecutiveSkips == nil)
    }

    @Test(arguments: [false, true])
    func zeroDisablesAllDismissalsEvenWithoutProgressiveEscalation(progressive: Bool) {
        let result = DismissalAvailability(progressiveEnforcement: progressive, consecutiveSkipLimit: 0)
        #expect(!result.normalSkipAllowed)
        #expect(!result.emergencyEscapeAllowed)
        #expect(result.remainingConsecutiveSkips == 0)
    }

    @Test func quietEscapeStillEscalatesWithoutOnscreenChallenges() {
        let preferences = AppPreferences()
        #expect(DisciplineLevel.gentle.enforcementPolicy(preferences: preferences).tier(at: 0).quietEscapeHoldDuration == 30)
        #expect(DisciplineLevel.gentle.enforcementPolicy(preferences: preferences).tier(at: 2).quietEscapeHoldDuration == 40)
        #expect(DisciplineLevel.firm.enforcementPolicy(preferences: preferences).tier(at: 0).quietEscapeHoldDuration == 40)
        #expect(DisciplineLevel.strict.enforcementPolicy(preferences: preferences).tier(at: 0).quietEscapeHoldDuration == 10)
        #expect(DisciplineLevel.strict.enforcementPolicy(preferences: preferences).tier(at: 3).quietEscapeHoldDuration == 25)
    }
}
