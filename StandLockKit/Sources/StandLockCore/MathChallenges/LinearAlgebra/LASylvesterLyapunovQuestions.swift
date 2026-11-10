import Foundation

/// Sylvester uniqueness and vectorization, Matrix Cookbook §§5.1.2, 10.2;
/// continuous-time Lyapunov Gramians, Boyd, EE363 lecture notes:
/// https://www2.imm.dtu.dk/pubdb/edoc/imm3274.pdf
/// https://ee363.stanford.edu/archive/lectures/lq-lyap.pdf
enum LASylvesterLyapunovQuestions {
    static func make(_ variant: Int, _ p: MathParameters) -> (prompt: String, answer: Double) {
        let a = p[0] + 1, b = a + p[1] + 1
        let d = p[2] + 1, f = d + p[3] + 1, c = p[4] / 5, e = -p[5] / 6
        if variant < 2 {
            let left = LinearAlgebraMatrix([[a, c], [0, b]])
            let right = LinearAlgebraMatrix([[d, 0], [e, f]])
            let forcing = LinearAlgebraMatrix([[p[6], p[7]], [p[3], -p[2]]])
            // Positive spectra of A and B make AX + XB = C uniquely solvable.
            let x = solve(left, right, forcing)
            let base = #"Let $$A=\#(left.text), B=\#(right.text), C=\#(forcing.text).$$ Let $X$ be the unique real $2\times2$ solution of $AX+XB=C$. "#
            if variant == 0 { return (base + #"Compute $\tr(X)$. Return one real scalar."#, x.trace) }
            return (base + #"Compute $\det(X)$. Return one real scalar."#, x.determinant)
        }
        let dynamics = LinearAlgebraMatrix([[-a, c], [0, -b]])
        let input = LinearAlgebraMatrix([[p[2], 0], [p[3], p[4]]])
        let q = input * input.transposed
        // A has strictly negative eigenvalues and BBᵀ is positive definite.
        let gramian = solve(dynamics, dynamics.transposed, q.scaled(-1))
        let base = #"Let $$A=\#(dynamics.text), B=\#(input.text).$$ Define the continuous-time controllability Gramian $W$ as the unique symmetric solution of $AW+WA^{T}+BB^{T}=0$. "#
        if variant == 2 {
            let v = [p[5], -p[6]]
            return (base + #"For $v=\#(LinearAlgebraMatrix.vectorText(v))$, compute $v^{T}Wv$. Return one real scalar."#, gramian.quadratic(v))
        }
        return (base + #"Compute $\|W\|_{F}^{2}$, the sum of squares of all entries of $W$. Return one real scalar."#, gramian.frobeniusSquared)
    }

    /// Row-major vectorization, assembled directly from the defining equation.
    private static func solve(_ a: LinearAlgebraMatrix, _ b: LinearAlgebraMatrix,
                              _ c: LinearAlgebraMatrix) -> LinearAlgebraMatrix {
        let coefficients = (0..<4).map { row in
            (0..<4).map { column in
                let i = row / 2, j = row % 2, k = column / 2, l = column % 2
                return (j == l ? a[i, k] : 0) + (i == k ? b[l, j] : 0)
            }
        }
        let x = LinearAlgebraMatrix(coefficients).solving(c.rows.flatMap { $0 })
        return LinearAlgebraMatrix([[x[0], x[1]], [x[2], x[3]]])
    }
}
