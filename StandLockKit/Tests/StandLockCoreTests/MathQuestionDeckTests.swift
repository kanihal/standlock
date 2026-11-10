import Foundation
import Testing
@testable import StandLockCore

@Suite("Math question selection")
struct MathQuestionDeckTests {
    @Test func everyFifteenQuestionsAreBalancedAndDecksDoNotRepeat() throws {
        var random = DeckRandom(state: 42)
        var deck = MathQuestionDeck()
        var seen: [MathTopic: Set<Int>] = [:]
        for _ in 0..<8 {
            deck.startAttempt()
            var counts: [MathTopic: Int] = [:]
            for _ in 0..<15 {
                let (topic, index) = deck.draw(using: &random)
                #expect(seen[topic, default: []].insert(index).inserted)
                counts[topic, default: 0] += 1
            }
            #expect(MathTopic.allCases.allSatisfy { counts[$0] == 5 })
            // Exposure survives JSON round trips and attempt resets.
            deck = try JSONDecoder().decode(MathQuestionDeck.self, from: JSONEncoder().encode(deck))
        }
        #expect(MathTopic.allCases.allSatisfy { seen[$0]?.count == 40 })
    }

    @Test func catalogHasOneHundredTwentyRealTemplatesAndFreshDraws() {
        #expect(MathProblemCatalog.templates.count == 120)
        #expect(Set(MathProblemCatalog.templates.map(\.id)).count == 120)
        var random = DeckRandom(state: 1234567)
        var deck = MathQuestionDeck()
        var signatures = Set<String>()
        for _ in 0..<120 {
            let problem = MathProblemCatalog.draw(deck: &deck, using: &random)
            #expect(problem.isValid)
            #expect(signatures.insert(problem.signature).inserted)
            #expect(MathProblemCatalog.templates.contains { $0.id == problem.templateID })
        }
    }
}

private struct DeckRandom: RandomNumberGenerator {
    var state: UInt64
    mutating func next() -> UInt64 {
        state = state &* 6364136223846793005 &+ 1442695040888963407
        return state
    }
}
