import Foundation
import Testing
@testable import StandLockCore

@Suite("Math answer grading")
struct MathAnswerTests {
    @Test func parsesNumericAnswersWithoutAcceptingInvalidValues() {
        #expect(MathAnswer.parse(" -3 / 4 ") == -0.75)
        #expect(MathAnswer.parse("1.25e2") == 125)
        for text in ["", "NaN", "inf", "1/0", "1/2/3", "1 + 2"] {
            #expect(MathAnswer.parse(text) == nil)
        }
    }

    @Test func discreteAnswersMustBeExactEvenForLargeCounts() {
        #expect(MathAnswer.isCorrect("10000001", expected: 10000000, kind: .integer) == false)
        #expect(MathAnswer.isCorrect("10000000", expected: 10000000, kind: .integer))
        #expect(MathAnswer.isCorrect("0.33333333", expected: 1.0 / 3, kind: .real))
        #expect(!MathAnswer.isCorrect("0.333", expected: 1.0 / 3, kind: .real))
    }
}
