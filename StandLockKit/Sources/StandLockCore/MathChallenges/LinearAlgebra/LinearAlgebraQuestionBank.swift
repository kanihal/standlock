import Foundation

public enum LinearAlgebraQuestionBank {
    public static let titles = [
        "Rank-one update: inverse trace", "Rank-one update: determinant",
        "Rank-one update: inverse quadratic form", "Rank-one update: inverse-squared trace",
        "Jordan block: exponential entry", "Jordan block: integer-power entry",
        "Jordan block: resolvent entry", "Jordan block: polynomial entry",
        "Kronecker product: determinant", "Kronecker product: inverse trace",
        "Kronecker product: spectral radius", "Kronecker product: condition number",
        "Orthogonal projection: squared norm", "Affine projection: squared distance",
        "Orthogonal projection: weighted trace", "Orthogonal projection: leverage entry",
        "Pseudoinverse: squared Frobenius norm", "Least squares: squared residual norm",
        "Singular values: nuclear norm", "Rank-one approximation: squared error",
        "Sylvester equation: solution trace", "Sylvester equation: solution determinant",
        "Lyapunov Gramian: quadratic form", "Lyapunov Gramian: squared Frobenius norm",
        "Block matrix: determinant", "Block inverse: lower-block trace",
        "Schur complement: smallest eigenvalue", "Block inverse: quadratic form",
        "Simple eigenvalue: first derivative", "Simple eigenvalue: second derivative",
        "Log determinant: first derivative", "Inverse trace: first derivative",
        "Operator: spectral norm", "Operator: spectral condition number",
        "Commutator: squared Frobenius norm", "Resolvent: spectral norm",
        "Jacobi iteration: spectral radius", "Gauss–Seidel iteration: spectral radius",
        "SOR iteration: optimal relaxation", "Conjugate gradients: energy error after two steps",
    ]

    public static func problem(index: Int, parameters: MathParameters) -> MathProblem {
        precondition((1...40).contains(index))
        let variant = (index - 1) % 4
        let result: (prompt: String, answer: Double)
        switch (index - 1) / 4 {
        case 0: result = LARankOneUpdateQuestions.make(variant, parameters)
        case 1: result = LAJordanFunctionQuestions.make(variant, parameters)
        case 2: result = LAKroneckerOperatorQuestions.make(variant, parameters)
        case 3: result = LAProjectionQuestions.make(variant, parameters)
        case 4: result = LASingularValueQuestions.make(variant, parameters)
        case 5: result = LASylvesterLyapunovQuestions.make(variant, parameters)
        case 6: result = LASchurComplementQuestions.make(variant, parameters)
        case 7: result = LAMatrixDerivativeQuestions.make(variant, parameters)
        case 8: result = LAOperatorNormQuestions.make(variant, parameters)
        default: result = LAIterativeSolverQuestions.make(variant, parameters)
        }
        return MathProblem(templateID: String(format: "LA%02d", index), topic: .linearAlgebra,
                           title: titles[index - 1], parameters: parameters,
                           prompt: result.prompt, answer: result.answer,
                           answerKind: [19, 20].contains(index) ? .integer : .real)
    }
}
