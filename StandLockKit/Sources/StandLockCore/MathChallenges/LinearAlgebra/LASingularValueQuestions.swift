import Foundation

/// Pseudoinverse and optimal low-rank approximation, Boyd, EE263 SVD notes:
/// https://ee263.stanford.edu/lectures/svd.pdf
enum LASingularValueQuestions {
    static func make(_ variant: Int, _ p: MathParameters) -> (prompt: String, answer: Double) {
        let s1 = p[0] + p[1] + 3, s2 = p[0] + 1
        // Use orthonormal columns (3/5, 4/5, 0) and (-4, 3, 12)/13,
        // with orthogonal complement (48, -36, 25)/65. Scale their entries
        // by 65 below to display the resulting matrix as exact fractions.
        let numerator = Int(p[2]), denominator = Int(p[3]) + 1
        let c = denominator * denominator - numerator * numerator
        let s = 2 * numerator * denominator
        let matrixDenominator = 65 * (denominator * denominator + numerator * numerator)
        let firstColumn = [39, 52, 0], secondColumn = [-20, 15, 60]
        let rows = (0..<3).map { row in
            let a = firstColumn[row] * Int(s1), b = secondColumn[row] * Int(s2)
            return #"\frac{\#(a * c - b * s)}{\#(matrixDenominator)} & \frac{\#(a * s + b * c)}{\#(matrixDenominator)}"#
        }
        let matrixText = #"\begin{bmatrix}\#(rows.joined(separator: #" \\ "#))\end{bmatrix}"#
        let base = #"Let the real $3\times2$ matrix $$A=\#(matrixText),$$ with all displayed fractions exact. The squared Frobenius norm is the sum of squared entries. "#
        switch variant {
        case 0:
            return (base + #"Compute $\|A^{+}\|_{F}^{2}$, where $A^{+}$ is the Moore–Penrose pseudoinverse. Return one real scalar."#, 1 / (s1 * s1) + 1 / (s2 * s2))
        case 1:
            let b = [p[4], -p[5], p[6]]
            let residual = (48 * b[0] - 36 * b[1] + 25 * b[2]) / 65
            return (base + #"For $b=\#(LinearAlgebraMatrix.vectorText(b))$, compute $\min_{x\in\mathbb{R}^{2}}\|Ax-b\|_{2}^{2}$. Return one real scalar."#, residual * residual)
        case 2:
            return (base + #"Compute the nuclear norm $\|A\|_{*}$, the sum of its singular values. Its exact value is an integer; return that integer."#, s1 + s2)
        default:
            return (base + #"Compute $\min_{\operatorname{rank}(R)\le1}\|A-R\|_{F}^{2}$ over real $3\times2$ matrices $R$. Its exact value is an integer; return that integer."#, s2 * s2)
        }
    }
}
