import Foundation

/// Block inversion, determinants and Schur complements, Matrix Cookbook §9.1:
/// https://www2.imm.dtu.dk/pubdb/edoc/imm3274.pdf
enum LASchurComplementQuestions {
    static func make(_ variant: Int, _ p: MathParameters) -> (prompt: String, answer: Double) {
        let a = LinearAlgebraMatrix.diagonal([p[0] + 2, p[1] + 3])
        let b = LinearAlgebraMatrix([[p[2] / 3, p[3] / 4], [p[4] / 5, -p[5] / 6]])
        let s0 = p[6] + 2
        let schur = LinearAlgebraMatrix([[s0, 0.5], [0.5, s0 + p[7] + 1]])
        let d = schur + b.transposed * a.inverse * b
        // Positive A and Schur complement construct a positive definite block matrix.
        let matrix = LinearAlgebraMatrix((0..<4).map { i in
            (0..<4).map { j in
                if i < 2 && j < 2 { return a[i, j] }
                if i < 2 { return b[i, j - 2] }
                if j < 2 { return b[j, i - 2] }
                return d[i - 2, j - 2]
            }
        })
        let base = #"Let $$M=\#(matrix.text).$$ Partition after the first two rows and columns as $M=\begin{bmatrix}A & B \\ B^{T} & D\end{bmatrix}$, so $A$, $B$, and $D$ are $2\times2$ blocks. "#
        switch variant {
        case 0: return (base + #"Compute $\det(M)$. Return one real scalar."#, a.determinant * schur.determinant)
        case 1:
            return (base + #"Let $E$ be the lower-right $2\times2$ block of $M^{-1}$. Compute $\tr(E)$. Return one real scalar."#, schur.inverse.trace)
        case 2:
            return (base + #"Compute the smallest eigenvalue of the Schur complement $D-B^{T}A^{-1}B$. Return one real scalar."#, schur.symmetricEigenvalues2.minimum)
        default:
            let v = [p[0], -p[1], p[6], -p[7]]
            return (base + #"For $v=\#(LinearAlgebraMatrix.vectorText(v))$, compute $v^{T}M^{-1}v$. Return one real scalar."#, matrix.inverse.quadratic(v))
        }
    }
}
