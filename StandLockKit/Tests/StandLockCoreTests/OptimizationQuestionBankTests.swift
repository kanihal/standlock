import Foundation
import Testing
@testable import StandLockCore

@Suite("Optimization question bank")
struct OptimizationQuestionBankTests {
    // Independent offline numerical fixtures: equality KKT systems, box-face minimization,
    // dual stationarity and trust-radius bisection, simplex bisection, and direct sample enumeration.
    // A wrong family dispatch, KKT sign, penalty normalization, or algorithm index breaks these.
    private let parameterSets = [
        MathParameters([1, 1, 1, 1, 1, 1, 1, 1]),
        MathParameters([2, 3, 4, 5, 6, 7, 8, 9]),
        MathParameters([9, 8, 7, 6, 5, 4, 3, 2])
    ]
    private let expected: [[Double]] = [
        [-0.27469135802469136, 9.7999999999999936, 2.7314814814814836], // OPT01
        [-0.8148148148148151, -6.7999999999999989, -8.7777777777777786], // OPT02
        [0.8148148148148151, 6.7999999999999989, 8.7777777777777786], // OPT03
        [0.1074691358024692, 2.4166666666666607, 8.5268518518518519], // OPT04
        [-1.34375, -39.04475308641976, -61.875], // OPT05
        [1.5, 6.5, 10], // OPT06
        [-1.34375, -39.04475308641976, -61.875], // OPT07
        [1.1231249999999995, 31.766994801819372, 28.744853465851165], // OPT08
        [4.8178174697975624, 16.271602223647292, 16.298904188379293], // OPT09
        [0.91648642466573516, 1.6029008415216812, 0.67278001034023482], // OPT10
        [0.91648642466573516, 1.6029008415216812, 0.67278001034023482], // OPT11
        [5.4989185479944105, 19.234810098260176, 18.165060279186342], // OPT12
        [-0.91666666666666663, -0, -6], // OPT13
        [1.2307692307692308, 0.81689342403628118, 23.222222222222218], // OPT14
        [0.54687499999999989, 0, 1.1363636363636362], // OPT15
        [1.1185170918213299, 0.32675096536743542, 6.7284161474004804], // OPT16
        [2.4372222222222222, 0.85444444444444445, 69.604444444444439], // OPT17
        [2.6775273375859636, 4.2677321561168089, 4.3608951933868321], // OPT18
        [0.49999999999999933, 3.9999999999999991, 1.4999999999999991], // OPT19
        [-0.10918156082308697, 0.049131996123905189, -0.4737920249981063], // OPT20
        [0.80000000000000004, 1.8118541979167151, 0.56801776790671854], // OPT21
        [1.2000000000000002, 1.8118541979167151, 0.85202665186007787], // OPT22
        [0.20000000000000001, 0.22648177473958939, 0.14200444197667964], // OPT23
        [1, 4, 2], // OPT24
        [-0.828125, 2.320175438596491, 2.7403160040774726], // OPT25
        [1.0851991577130402, 4.1373924066347403, 3.6752726000234923], // OPT26
        [0.29373968621587659, 9.3309627996021405, 5.186633750221108], // OPT27
        [0.296875, 19.472953216374272, 33.518093781855249], // OPT28
        [0, 1.0833333333333335, 0.20833333333333348], // OPT29
        [0.39605901719066966, 1.3734677431101669, 5.8454494264226771], // OPT30
        [0.56249031002511263, 2.1778373863998466, 4.3135441722436694], // OPT31
        [0.3715277777777779, 0.41232638888888928, 168.76388888888891], // OPT32
        [0.023950447933072539, 0.00013523604175984683, 0.009610310497424366], // OPT33
        [0.44444444444444442, 0.14814814814814814, 0.055555555555555552], // OPT34
        [0.28143528319301714, 0.0041243769844020251, 3.5022115302317006e-06], // OPT35
        [19, 180, 6452], // OPT36
        [0.11647901234567902, 7.3669126157407412, 16.444478879706157], // OPT37
        [0.49191358024691362, 55.605185185185185, 180.05555555555557], // OPT38
        [0.85448399303205458, 70.9544293888449, 65.447278722798245], // OPT39
        [0.16666666666666666, 56.018518518518484, 0], // OPT40
    ]

    @Test func matchesThreeIndependentFixturesForEveryTemplate() {
        #expect(OptimizationQuestionBank.titles.count == 40)
        for index in 1...40 {
            for fixture in 0..<3 {
                let problem = OptimizationQuestionBank.problem(index: index, parameters: parameterSets[fixture])
                let want = expected[index - 1][fixture]
                #expect(abs(problem.answer - want) <= 2e-10 * max(1, abs(want)), "OPT\(index), fixture \(fixture): \(problem.answer) versus \(want)")
                #expect(problem.templateID == String(format: "OPT%02d", index))
                #expect(problem.topic == .optimization)
                #expect(problem.isValid)
            }
        }
    }

    @Test func everyTemplateDelimitsItsLatexForTheMathRenderer() throws {
        let math = try NSRegularExpression(pattern: #"\$\$[\s\S]+?\$\$|\$[^$\n]+\$"#)
        for index in 1...40 {
            let prompt = OptimizationQuestionBank.problem(index: index, parameters: parameterSets[1]).prompt
            let range = NSRange(prompt.startIndex..., in: prompt)
            let matches = math.matches(in: prompt, range: range)
            #expect(!matches.isEmpty, "OPT\(index) needs delimited math")
            let prose = math.stringByReplacingMatches(in: prompt, range: range, withTemplate: "")
            #expect(!prose.contains("$"), "OPT\(index) has an unmatched delimiter")
            #expect(!prose.contains(#"\"#), "OPT\(index) has a LaTeX command outside math")
            #expect(!prose.contains(where: { "∈ℝλμτγφΣ‖ᵀ₀₁₂₃₄ₖᵢ⁺≤≥²³".contains($0) }), "OPT\(index) has bare mathematical notation")
        }
    }

    @Test func subgradientBudgetRoundsAnExactSquareWithoutAnExtraIteration() {
        let problem = OptimizationQuestionBank.problem(
            index: 36, parameters: MathParameters([1, 1, 5, 1, 1, 3, 1, 1])
        )
        // R = 1/2, G = 8/3, ε = 2/15; (RG/ε)² = 100 exactly.
        #expect(problem.answer == 100)
    }

    @Test func constructsFiniteDeterministicGradableProblemsWithoutRetrying() {
        var state: UInt64 = 0x9E3779B97F4A7C15
        for index in 1...40 {
            for _ in 0..<80 {
                let values = (0..<8).map { _ -> Int in
                    state = state &* 6364136223846793005 &+ 1442695040888963407
                    return 1 + Int((state >> 32) % 9)
                }
                let parameters = MathParameters(values)
                let problem = OptimizationQuestionBank.problem(index: index, parameters: parameters)
                let repeated = OptimizationQuestionBank.problem(index: index, parameters: parameters)
                #expect(problem.isValid)
                #expect(problem.answer == repeated.answer)
                #expect(problem.prompt == repeated.prompt)
                #expect(MathAnswer.isCorrect(String(format: "%.16g", problem.answer), expected: problem.answer, kind: problem.answerKind))
                let wrong = problem.answer + max(1, abs(problem.answer)) * 0.01
                #expect(!MathAnswer.isCorrect(String(wrong), expected: problem.answer, kind: problem.answerKind))
                if index == 24 || index == 36 {
                    #expect(problem.answerKind == .integer)
                }
            }
        }
    }
}
