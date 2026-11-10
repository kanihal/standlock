import Foundation

/// Orthogonal projection and least-squares geometry, Boyd, EE263:
/// https://see.stanford.edu/Course/EE263/59
enum LAProjectionQuestions {
    static func make(_ variant: Int, _ p: MathParameters) -> (prompt: String, answer: Double) {
        let n = [p[0], p[1], -p[2]], v = [p[3], -p[4], p[5]]
        let norm = LinearAlgebraMatrix.dot(n, n)
        let nv = LinearAlgebraMatrix.dot(n, v)
        let base = #"Work in real Euclidean $\mathbb{R}^{3}$ with its ordinary inner product. Let $$n=\#(LinearAlgebraMatrix.vectorText(n)), v=\#(LinearAlgebraMatrix.vectorText(v)).$$ Let $P$ be the orthogonal projector onto $\{x\in\mathbb{R}^{3}:n^{T}x=0\}$. "#
        switch variant {
        case 0:
            return (base + #"Compute $\|Pv\|_{2}^{2}$. Return one real scalar."#, LinearAlgebraMatrix.dot(v, v) - nv * nv / norm)
        case 1:
            return (base + #"Compute the squared Euclidean distance from $v$ to the affine plane $\{x\in\mathbb{R}^{3}:n^{T}x=\#(Int(p[6]))\}$. Return one real scalar."#, pow(nv - p[6], 2) / norm)
        case 2:
            let w = [p[3], p[4] + 1, p[5] + 2]
            let weight = LinearAlgebraMatrix.diagonal(w)
            let answer = (0..<3).reduce(0.0) { $0 + w[$1] * (1 - n[$1] * n[$1] / norm) }
            return (base + #"For $W=\#(weight.text)$, compute the weighted trace $\tr(WP)$. Return one real scalar."#, answer)
        default:
            return (base + #"Compute the leverage entry $P_{22}$, with 1-based row and column indices. Return one real scalar."#, 1 - n[1] * n[1] / norm)
        }
    }
}
