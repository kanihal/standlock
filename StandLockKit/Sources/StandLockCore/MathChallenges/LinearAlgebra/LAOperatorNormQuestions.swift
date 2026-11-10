import Foundation

/// Induced Euclidean norm and singular values, Boyd, EE263 SVD notes:
/// https://ee263.stanford.edu/lectures/svd.pdf
enum LAOperatorNormQuestions {
    static func make(_ variant: Int, _ p: MathParameters) -> (prompt: String, answer: Double) {
        let a = LinearAlgebraMatrix([[p[0] + 1, p[2] / (p[2] + 1)], [0, p[1] + 2]])
        let base = #"Let the real $2\times2$ matrix $$A=\#(a.text).$$ The spectral norm is the operator norm induced by the Euclidean vector norm; $\kappa_{2}$ is the ratio of largest to smallest singular value. "#
        switch variant {
        case 0: return (base + #"Compute $\|A\|_{2}$. Return one real scalar."#, a.spectralNorm2)
        case 1:
            let eigenvalues = (a.transposed * a).symmetricEigenvalues2
            return (base + #"Compute $\kappa_{2}(A)$. Return one real scalar."#, sqrt(eigenvalues.maximum / eigenvalues.minimum))
        case 2:
            let b = LinearAlgebraMatrix([[p[3], p[4]], [p[5], -p[6]]])
            return (base + #"For $B=\#(b.text)$, compute $\|AB-BA\|_{F}^{2}$, the sum of squares of entries of the commutator. Return one real scalar."#, (a * b - b * a).frobeniusSquared)
        default:
            let z = p[0] + p[1] + p[7] + 5
            let resolvent = (LinearAlgebraMatrix.identity(2).scaled(z) - a).inverse
            return (base + #"For $z=\#(LinearAlgebraMatrix.number(z))$ and the $2\times2$ identity $I$, compute $\|(zI-A)^{-1}\|_{2}$. Return one real scalar."#, resolvent.spectralNorm2)
        }
    }
}
