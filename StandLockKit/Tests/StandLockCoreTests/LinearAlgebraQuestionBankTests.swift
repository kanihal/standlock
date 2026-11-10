import Foundation
import Testing
@testable import StandLockCore

@Suite("Linear algebra question bank")
struct LinearAlgebraQuestionBankTests {
    // Independent dense NumPy 2.4.5 calculations: inverse/determinant, SVD,
    // Kronecker-system Sylvester solves, scalar characteristic differentiation,
    // direct SOR spectral-radius minimization, and a Krylov-space minimization.
    // No expected value is derived with production helpers or stored formulas.
    private let parameterSets = [
        [1, 2, 3, 4, 5, 6, 7, 8],
        [9, 8, 7, 6, 5, 4, 3, 2],
        [2, 9, 4, 7, 1, 8, 3, 6],
    ]
    private let expectedByTemplate: [[Double]] = [
        [0.61394838001098284, 0.21476014760147605, 0.32771133599100477], // LA01: Inverse trace
        [728.40000000000032, 6774.9999999999909, 2445.7500000000018], // LA02: Determinant
        [27.381383855024701, 9.2808118081180826, 11.620975160993556], // LA03: Inverse quadratic form
        [0.19598807734886259, 0.020217861957217365, 0.055263471653599225], // LA04: Inverse-squared trace
        [4.1868372752582683, 5671.0792719328738, 177.02128869134], // LA05: Exponential entry
        [1.1111111111111112, 1143072, 75.851851851851848], // LA06: Integer-power entry
        [0.027777777777777776, 0.25925925925925919, 4.5], // LA07: Resolvent entry
        [36, 784, 108], // LA08: Polynomial entry
        [2477480.0153077524, 867675413.88931417, 43552855.996638596], // LA09: Kronecker determinant
        [0.11435823007300547, 0.025257728447974335, 0.060004920717778278], // LA10: Kronecker inverse trace
        [81.043199809321365, 303.36973737358062, 173.51600850507629], // LA11: Kronecker spectral radius
        [4.1728049001768577, 3.1243945054040605, 4.5621627890514462], // LA12: Kronecker condition number
        [35.857142857142854, 75.989690721649509, 106.78217821782181], // LA13: Projected squared norm
        [68.642857142857153, 1.4896907216494846, 8.9108910891089117], // LA14: Affine squared distance
        [10.857142857142858, 12, 15.534653465346537], // LA15: Weighted projection trace
        [0.7142857142857143, 0.67010309278350511, 0.19801980198019795], // LA16: Leverage entry
        [0.27777777777777779, 0.012499999999999995, 0.1162131519274375], // LA17: Pseudoinverse Frobenius norm squared
        [94.239289940828385, 49.865325443786993, 39.981301775147926], // LA18: Least-squares residual squared
        [8, 30, 17], // LA19: Nuclear norm
        [4, 100, 9], // LA20: Best rank-one error squared
        [1.0067340067340067, -0.048010973936899876, 0.27453703703703702], // LA21: Sylvester trace
        [-0.57575757575757569, -0.051662228677479223, -0.20819088319088316], // LA22: Sylvester determinant
        [130.10000000000002, 19.966061705989116, 110.38974358974357], // LA23: Gramian quadratic form
        [38.95000000000001, 13.860562349926385, 17.748517730933596], // LA24: Gramian Frobenius norm squared
        [2426.2499999999995, 4809.75, 2868], // LA25: Block determinant
        [0.16692426584234932, 0.32704402515723274, 0.28451882845188287], // LA26: Inverse lower-block trace
        [8.9723074309312913, 4.9188611699158109, 4.9644660940672622], // LA27: Schur minimum eigenvalue
        [11.315933367679889, 15.750241119023279, 14.505442817294281], // LA28: Block inverse quadratic form
        [-0.20000000000000001, 2.2000000000000002, 4.1600000000000001], // LA29: Eigenvalue first derivative
        [-9.6799999999999997, -8.7119999999999997, -2.0771636363636365], // LA30: Eigenvalue second derivative
        [-0.40000000000000002, 0.20999999999999999, 1.3038095238095238], // LA31: Logdet first derivative
        [0.10000000000000001, -0.021499999999999998, -0.45630385487528347], // LA32: Inverse-trace first derivative
        [4.0913471237766474, 10.447065737333462, 11.031369505631597], // LA33: Spectral norm
        [2.0923901609044306, 1.0914118252016676, 3.6876094899932941], // LA34: Spectral condition number
        [517.5625, 86.515625, 4433.9199999999992], // LA35: Commutator Frobenius norm squared
        [0.083770285698468436, 0.07369558300706304, 0.091030060449619657], // LA36: Resolvent spectral norm
        [0.54772255750516619, 0.42443734381358267, 0.40406101782088433], // LA37: Jacobi spectral radius
        [0.30000000000000004, 0.18014705882352941, 0.16326530612244897], // LA38: Gauss–Seidel spectral radius
        [1.0889331564394964, 1.0496167974777837, 1.0445325844925151], // LA39: Optimal SOR relaxation
        [0.94708866876057018, 0.058466010072553157, 0.064984664613814358], // LA40: CG energy error after two steps
    ]

    @Test func allFortyTemplatesMatchThreeIndependentScalarFixtures() {
        #expect(LinearAlgebraQuestionBank.titles.count == 40)
        for (caseIndex, values) in parameterSets.enumerated() {
            for index in 1...40 {
                let problem = LinearAlgebraQuestionBank.problem(index: index, parameters: MathParameters(values))
                let answer = expectedByTemplate[index - 1][caseIndex]
                #expect(abs(problem.answer - answer) <= 2e-9 * max(1, abs(answer)),
                        "LA \(index), fixture \(caseIndex): expected \(answer), received \(problem.answer)")
                #expect(problem.templateID == String(format: "LA%02d", index))
                #expect(problem.topic == .linearAlgebra)
                #expect(problem.parameters.values == values)
            }
        }
    }

    @Test func boundedParametersAlwaysProduceCompleteFiniteScalarProblems() throws {
        var seed: UInt64 = 0x31A7_9B55_0842
        for sample in 0..<256 {
            let values: [Int]
            if sample < 2 {
                values = Array(repeating: sample == 0 ? 1 : 9, count: 8)
            } else {
                values = (0..<8).map { _ in
                    seed = seed &* 6_364_136_223_846_793_005 &+ 1_442_695_040_888_963_407
                    return Int((seed >> 32) % 9) + 1
                }
            }
            for index in 1...40 {
                let problem = LinearAlgebraQuestionBank.problem(index: index, parameters: MathParameters(values))
                #expect(problem.isValid)
                #expect(problem.prompt.count > 60)
                #expect(!problem.prompt.contains("nan"))
                #expect(!problem.prompt.contains("inf"))
                #expect(!problem.prompt.contains("Optional("))
                #expect(MathAnswer.isCorrect(String(problem.answer), expected: problem.answer, kind: problem.answerKind))
                #expect(!MathAnswer.isCorrect(String(problem.answer + max(1, abs(problem.answer))),
                                             expected: problem.answer, kind: problem.answerKind))
                if [19, 20].contains(index) {
                    #expect(problem.answerKind == .integer)
                    #expect(problem.answer.rounded() == problem.answer)
                    #expect(!MathAnswer.isCorrect(String(problem.answer + 1e-7),
                                                 expected: problem.answer, kind: problem.answerKind))
                }
                let data = try JSONEncoder().encode(problem)
                #expect(try JSONDecoder().decode(MathProblem.self, from: data) == problem)
            }
        }
    }

    @Test func everyTemplateAuthorsDelimitedLatexWithCompleteMatrixEnvironments() throws {
        let math = try NSRegularExpression(pattern: #"\$\$[\s\S]+?\$\$|\$[^$\n]+?\$"#)
        for index in 1...40 {
            let problem = LinearAlgebraQuestionBank.problem(index: index, parameters: MathParameters(parameterSets[0]))
            let range = NSRange(problem.prompt.startIndex..., in: problem.prompt)
            let matches = math.matches(in: problem.prompt, range: range)
            #expect(!matches.isEmpty, "LA \(index) needs delimited mathematical expressions")
            let outsideMath = math.stringByReplacingMatches(in: problem.prompt, range: range, withTemplate: "")
            #expect(!outsideMath.contains("$"))
            #expect(!outsideMath.contains(#"\begin{"#))
            #expect(!outsideMath.contains(#"\frac"#))
            #expect(problem.prompt.contains(#"\begin{bmatrix}"#))
            #expect(!problem.prompt.contains("[["))
            for match in matches {
                let expression = String(problem.prompt[Range(match.range, in: problem.prompt)!])
                let beginnings = expression.components(separatedBy: #"\begin{bmatrix}"#).count
                let endings = expression.components(separatedBy: #"\end{bmatrix}"#).count
                #expect(beginnings == endings)
            }
            if (17...20).contains(index) {
                #expect(problem.prompt.contains(#"\frac{"#), "SVD matrix entries must remain exact fractions")
            }
        }
    }
}
