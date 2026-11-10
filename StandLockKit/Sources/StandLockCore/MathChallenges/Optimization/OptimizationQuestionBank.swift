import Foundation

public enum OptimizationQuestionBank {
    public static let titles: [String] = [
        "Equality QP optimum", "Equality QP multiplier", "Equality QP sensitivity", "Perturbed equality QP",
        "Box QP optimum", "Active inequality multiplier", "Optimal quadratic dual value", "Primal–dual gap",
        "Exponential dual function", "Unique exponential dual multiplier", "Exponential value sensitivity", "Primal recovery from a dual solution",
        "Lasso proximal coordinate", "Ridge proximal norm", "Elastic-net proximal coordinate", "Group-lasso proximal norm",
        "Newton decrement", "Damped Newton objective", "Trust-region multiplier", "Logistic Newton direction",
        "Exact quadratic line search", "Finite-grid Armijo search", "Finite-grid strong Wolfe search", "Backtracking reductions",
        "Quadratic conjugate", "Entropy conjugate", "Ellipsoid support function", "Fenchel–Young gap",
        "Simplex projection coordinate", "Metric hyperplane distance", "Ball projection distance", "Metric box projection objective",
        "Gradient descent loss", "Optimal fixed gradient step", "Accelerated convergence bound", "Subgradient iteration budget",
        "Expected one-step SGD loss", "Gradient estimator variance", "Optimal importance-sampling variance", "SVRG estimator variance"
    ]

    public static func problem(index: Int, parameters: MathParameters) -> MathProblem {
        precondition((1...40).contains(index))
        let variant = (index - 1) % 4
        let instance: OptimizationInstance
        switch (index - 1) / 4 {
        case 0: instance = OptimizationEqualityQPQuestions.instance(variant, parameters)
        case 1: instance = OptimizationInequalityQPQuestions.instance(variant, parameters)
        case 2: instance = OptimizationConvexDualityQuestions.instance(variant, parameters)
        case 3: instance = OptimizationProximalMapQuestions.instance(variant, parameters)
        case 4: instance = OptimizationNewtonTrustRegionQuestions.instance(variant, parameters)
        case 5: instance = OptimizationLineSearchQuestions.instance(variant, parameters)
        case 6: instance = OptimizationConjugateQuestions.instance(variant, parameters)
        case 7: instance = OptimizationProjectionQuestions.instance(variant, parameters)
        case 8: instance = OptimizationConvergenceRateQuestions.instance(variant, parameters)
        default: instance = OptimizationStochasticOptimizationQuestions.instance(variant, parameters)
        }
        return MathProblem(
            templateID: String(format: "OPT%02d", index), topic: .optimization,
            title: titles[index - 1], parameters: parameters, prompt: instance.prompt,
            answer: instance.answer, answerKind: instance.kind
        )
    }
}
