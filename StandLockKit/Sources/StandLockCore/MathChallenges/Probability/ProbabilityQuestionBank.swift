import Foundation

public enum ProbabilityQuestionBank {
    public static let titles: [String] = ProbabilityGaussianQuestions.titles
        + ProbabilityNormalInverseGammaQuestions.titles
        + ProbabilityConjugateQuestions.titles
        + ProbabilityMarkovQuestions.titles
        + ProbabilityProcessQuestions.titles
        + ProbabilityLimitQuestions.titles
        + ProbabilityInformationQuestions.titles
        + ProbabilityTestQuestions.titles
        + ProbabilityDecisionQuestions.titles
        + ProbabilityMonteCarloQuestions.titles

    public static func problem(index: Int, parameters: MathParameters) -> MathProblem {
        precondition((1...40).contains(index))
        let variant = (index - 1) % 4
        let instance: ProbabilityInstance
        switch (index - 1) / 4 {
        case 0: instance = ProbabilityGaussianQuestions.instance(variant, parameters)
        case 1: instance = ProbabilityNormalInverseGammaQuestions.instance(variant, parameters)
        case 2: instance = ProbabilityConjugateQuestions.instance(variant, parameters)
        case 3: instance = ProbabilityMarkovQuestions.instance(variant, parameters)
        case 4: instance = ProbabilityProcessQuestions.instance(variant, parameters)
        case 5: instance = ProbabilityLimitQuestions.instance(variant, parameters)
        case 6: instance = ProbabilityInformationQuestions.instance(variant, parameters)
        case 7: instance = ProbabilityTestQuestions.instance(variant, parameters)
        case 8: instance = ProbabilityDecisionQuestions.instance(variant, parameters)
        default: instance = ProbabilityMonteCarloQuestions.instance(variant, parameters)
        }
        return MathProblem(
            templateID: String(format: "PS%02d", index), topic: .probability,
            title: titles[index - 1], parameters: parameters,
            prompt: instance.prompt, answer: instance.answer, answerKind: instance.answerKind
        )
    }
}
