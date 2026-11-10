import Foundation
import Testing
@testable import StandLockCore

@Suite("Probability question bank")
struct ProbabilityQuestionBankTests {
    // Literal fixtures independently obtained with SciPy distributions, quadrature,
    // finite-state enumeration, linear solves, and decision optimization. Each row
    // follows PS01...PS40; expectations never call a production math helper.
    private let parameters = [
        MathParameters([1, 2, 3, 4, 5, 6, 7, 8]),
        MathParameters([9, 8, 7, 6, 5, 4, 3, 2]),
        MathParameters([3, 7, 2, 9, 4, 8, 1, 6])
    ]

    private let expected: [[Double]] = [
        [
            -1.6666666666666665, 2.6666666666666674, -4.8775978372492634, 0.49216405267330826,
            2.5415789473684218, 0.23105263157894734, 0.4783599088838269, -12.256164523871288,
            2.486645299145299, 0.050133601413108367, -0.99000000000000743, 0.23919739661773995,
            0.375, 12.250000000000004, 0.37319249821673539, 0.64453125000000011,
            0.20949167018650369, 26.590909090909086, 4.4444444444444429, 10.113928941256923,
            0.43294775022056653, 0.25249253754692302, 0.000641121091789369, 0.21639532432449304,
            0.73575888234288478, 0.33333333333333326, 2.0000000000000004, 0.32227738422947994,
            2.918059701492536, 0.082338047102406303, 0.34722222222222143, 1.4054054054054055,
            50.800000000000004, -1, 4.2000000000000002, 0,
            7.975778546712804, 1.25, 0.10676835081029552, 1079.9999999999964
        ],
        [
            0.77777777777777779, 10.888888888888893, -4.4977077445201417, 0.9709155425423317,
            2.7925575657894739, 0.16426809210526319, 0.42052565707133921, -28.21932938890663,
            2.0601029829545454, 0.17684371273756386, -0.69398301956442776, 0.13204616249242102,
            0.50373134328358204, 7.9074074074074119, 0.50373134193017843, 0.2817007286468084,
            0.16326516936982641, 1984.4999999999959, 37.3333333333333, 12.7883279108409,
            0.18622448979591832, 0.7475074624530772, 0.27942353411071419, 0.7106113126969813,
            2.718281828459046, 0.010101010101010104, 1.166666666666667, 16.901775390273372,
            21.951188811188814, 1.5320089067730509, 0.17361111111110006, 0.94736842105263164,
            149.19999999999999, 17, 11.736842105263158, 0.14117647058823524,
            3.5428571428571431, -1.5625, -1.1969696969696972, 20.000000000000004
        ],
        [
            4.5625, 5.9687499999999991, -4.5378823066789975, 10.783678186247357,
            6.4200680272108839, 0.42800453514739234, 0.2039735099337748, -13.833034622844185,
            1.3979206049149335, 0.060386683948379108, -0.38063063063063179, 0.27179261252966591,
            0.61904761904761907, 6.7777777777777786, 0.59125853970428177, 0.9320807688154632,
            0.23844603634269845, 815.99999999999818, 9.2307692307692299, 4.4175796250006965,
            0.46088697049332128, 0.15865525393145719, 0.20818164098771816, 1.214564945667806,
            0.50204286033396706, 0.028124999999999966, 1.9999999999999996, 11.674185362516894,
            10.296885553470917, 0.25306612419308616, 9, 1.3617747440273038,
            121, 7, 4.6666666666666661, 0,
            5.9563164108618674, 4.024390243902439, -0.41649484536082454, 396.66666666666686
        ]
    ]

    @Test func allFortyTemplatesMatchThreeIndependentLiteralFixtures() {
        #expect(ProbabilityQuestionBank.titles.count == 40)
        #expect(Set(ProbabilityQuestionBank.titles).count == 40)
        for (parameters, answers) in zip(parameters, expected) {
            for index in 1...40 {
                let problem = ProbabilityQuestionBank.problem(index: index, parameters: parameters)
                let answer = answers[index - 1]
                #expect(abs(problem.answer - answer) <= 1e-10 * max(1, abs(answer)),
                        "\(problem.templateID): got \(problem.answer), expected \(answer)")
                #expect(problem.templateID == String(format: "PS%02d", index))
                #expect(problem.title == ProbabilityQuestionBank.titles[index - 1])
                #expect(problem.topic == .probability)
                #expect(problem.parameters == parameters)
                #expect(problem.isValid)
            }
        }
    }

    @Test func boundedInputsAlwaysProduceFiniteGradableReproducibleProblems() {
        var random = ProbabilityTestRandom(state: 0x74D7_05A1_EB82_096C)
        var samples = [MathParameters(Array(repeating: 1, count: 8)),
                       MathParameters(Array(repeating: 9, count: 8))]
        samples += (0..<300).map { _ in MathParameters(using: &random) }
        for parameters in samples {
            for index in 1...40 {
                let problem = ProbabilityQuestionBank.problem(index: index, parameters: parameters)
                let repeatProblem = ProbabilityQuestionBank.problem(index: index, parameters: parameters)
                #expect(problem.isValid)
                #expect(problem.answer == repeatProblem.answer)
                #expect(problem.prompt == repeatProblem.prompt)
                #expect(problem.signature == repeatProblem.signature)
                #expect(MathAnswer.isCorrect(String(format: "%.12g", problem.answer),
                                             expected: problem.answer, kind: problem.answerKind))
                #expect(!MathAnswer.isCorrect(String(problem.answer + 1),
                                              expected: problem.answer, kind: problem.answerKind))
                #expect(problem.answerKind == (index == 34 ? .integer : .real))
                if [10, 12, 13, 15, 17, 22, 23].contains(index) {
                    #expect((0...1).contains(problem.answer))
                }
                if [2, 4, 5, 6, 7, 9, 14, 16, 18, 19, 20, 21, 24, 25,
                    26, 27, 28, 29, 30, 31, 33, 35, 36, 37, 40].contains(index) {
                    #expect(problem.answer >= -1e-12)
                }
                if index == 11 { #expect(problem.answer < 0) }
            }
        }
    }

    @Test func allFortyPromptsContainSupportedDelimitedLatexMath() {
        for parameters in parameters {
            for index in 1...40 {
                let problem = ProbabilityQuestionBank.problem(index: index, parameters: parameters)
                let document = MathPromptDocument(problem.prompt)
                #expect(document.mathCount > 0, "\(problem.templateID) must contain delimited LaTeX")
                #expect(document.unsupportedCommands.isEmpty,
                        "\(problem.templateID): \(document.unsupportedCommands)")
                #expect(problem.prompt.filter { $0 == "$" }.count.isMultiple(of: 2))
            }
        }
    }

    @Test func promptsMakeStatisticalConventionsExplicit() {
        let parameters = parameters[0]
        func prompt(_ index: Int) -> String {
            ProbabilityQuestionBank.problem(index: index, parameters: parameters).prompt
        }
        #expect(prompt(3).contains("natural log"))
        #expect(prompt(4).contains(#"\operatorname{KL}(P \Vert Q)"#))
        for index in 5...8 {
            #expect(prompt(index).contains(#"v^{-\alpha_0-1}"#))
            #expect(prompt(index).contains(#"\exp\left(-\frac{\beta_0}{v}\right)"#))
            #expect(prompt(index).contains(#"\mu \mid v \sim \mathcal{N}(\mu_0,\frac{v}{\kappa_0})"#))
            #expect(prompt(index).contains("centered sum of squares"))
        }
        #expect(prompt(6).contains(#"\operatorname{Var}(\mu\mid\mathrm{data})"#))
        for index in [10, 12] { #expect(prompt(index).contains("shape–rate")) }
        #expect(prompt(16).contains(#"\lim_{n\to\infty}n\operatorname{Var}"#))
        #expect(prompt(20).contains("diffusion coefficient"))
        #expect(prompt(21).contains(#"\sqrt{n}"#))
        #expect(prompt(22).contains("CLT normal approximation"))
        #expect(prompt(27).contains(#"$\mu$ is estimated"#))
        #expect(prompt(30).contains("squared score statistic"))
        #expect(prompt(32).contains("smallest included likelihood ratio"))
        #expect(prompt(32).contains(#"\ge\mathrm{cutoff}"#))
        #expect(prompt(32).contains("no randomization"))
        #expect(prompt(34).contains("finite prior"))
        #expect(prompt(35).contains("probability $q$"))
        #expect(prompt(39).contains(#"Y-c(Z-\mathbb{E}[Z])"#))
        #expect(prompt(40).contains("asymptotic"))
        #expect(prompt(40).contains("Do not cap"))
    }

    @Test func conditionalVarianceHasOneClosingMathParenthesisAfterTheObservation() {
        let prompt = ProbabilityQuestionBank.problem(index: 2, parameters: parameters[0]).prompt
        #expect(prompt.contains(#"\operatorname{Var}(X_1 \mid X_2 = 2)$"#))
        #expect(!prompt.contains(#"\operatorname{Var}(X_1 \mid X_2 = 2))$"#))
    }

    @Test func anticorrelatedChainsHaveAsymptoticEffectiveSampleSizeAboveN() {
        let parameters = MathParameters([1, 2, 3, 4, 5, 6, 7, 8])
        let problem = ProbabilityQuestionBank.problem(index: 40, parameters: parameters)
        #expect(abs(problem.answer - 1080) < 1e-9)
        #expect(problem.answer > 120)
    }
}

private struct ProbabilityTestRandom: RandomNumberGenerator {
    var state: UInt64
    mutating func next() -> UInt64 {
        state = state &* 6364136223846793005 &+ 1442695040888963407
        return state
    }
}
