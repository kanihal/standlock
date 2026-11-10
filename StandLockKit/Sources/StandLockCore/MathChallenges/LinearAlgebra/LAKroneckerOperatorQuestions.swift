import Foundation

/// Kronecker determinant, spectrum and inverse identities, Matrix Cookbook §10.2:
/// https://www2.imm.dtu.dk/pubdb/edoc/imm3274.pdf
enum LAKroneckerOperatorQuestions {
    static func make(_ variant: Int, _ p: MathParameters) -> (prompt: String, answer: Double) {
        let a0 = p[0] + 2, a1 = a0 + p[1] + 1, offA = p[2] / (p[2] + 1)
        let b0 = p[3] + 3, b1 = b0 + p[4] + 1, offB = p[5] / (p[5] + 1)
        let a = LinearAlgebraMatrix([[a0, offA], [offA, a1]])
        let b = LinearAlgebraMatrix([[b0, offB], [offB, b1]])
        // Both factors are positive, strictly diagonally dominant symmetric matrices.
        let base = #"Let $$A=\#(a.text), B=\#(b.text).$$ Let $K=A\otimes B$, the $4\times4$ Kronecker product whose $(i,j)$ block is $A_{ij}B$. "#
        let ea = a.symmetricEigenvalues2, eb = b.symmetricEigenvalues2
        switch variant {
        case 0: return (base + #"Compute $\det(K)$. Return one real scalar."#, pow(a.determinant * b.determinant, 2))
        case 1: return (base + #"Compute $\tr(K^{-1})$. Return one real scalar."#, a.inverse.trace * b.inverse.trace)
        case 2:
            return (base + #"Compute the spectral radius $\rho(K)$, the largest absolute value of an eigenvalue. Return one real scalar."#, ea.maximum * eb.maximum)
        default:
            return (base + #"Compute $\kappa_{2}(K)$, the ratio of largest to smallest singular value. Return one real scalar."#, (ea.maximum / ea.minimum) * (eb.maximum / eb.minimum))
        }
    }
}
