enum ProbabilityMath {
    static func number(_ value: Double) -> String {
        MathLatex.number(value)
    }

    static func vector(_ values: [Double]) -> String {
        MathLatex.vector(values)
    }

    static func matrix(_ rows: [[Double]]) -> String {
        MathLatex.matrix(rows)
    }

    static func fractions(_ numerators: [Double], denominator: Double) -> String {
        #"\begin{bmatrix}"#
            + numerators.map { MathLatex.fraction($0, denominator) }.joined(separator: " & ")
            + #"\end{bmatrix}"#
    }
}
