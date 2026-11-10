import Foundation

/// Simple-eigenvalue derivatives, Magnus (1985), Theorems 1 and 4:
/// https://www.janmagnus.nl/papers/JRM011.pdf
/// Inverse and determinant derivatives, Matrix Cookbook §§2.1–2.2:
/// https://www2.imm.dtu.dk/pubdb/edoc/imm3274.pdf
enum LAMatrixDerivativeQuestions {
    static func make(_ variant: Int, _ p: MathParameters) -> (prompt: String, answer: Double) {
        let l = p[0] + 1, m = l + p[1] + 2
        let q = LinearAlgebraMatrix([[3.0 / 5, -4.0 / 5], [4.0 / 5, 3.0 / 5]])
        let a = q * LinearAlgebraMatrix.diagonal([l, m]) * q.transposed
        let h = LinearAlgebraMatrix([[p[2], p[3] / 2], [p[3] / 2, -p[4]]])
        // The distinct positive eigenvalues ensure a smooth simple eigenvalue
        // branch and positive definiteness in a neighborhood of t = 0.
        let base = #"For real $t$ near $0$, define the symmetric matrix $A(t)=A_{0}+tH$ with $$A_{0}=\#(a.text), H=\#(h.text).$$ "#
        switch variant {
        case 0:
            return (base + #"Let $\lambda(t)$ be the eigenvalue branch equal to the smaller eigenvalue of $A_{0}$ at $t=0$. Compute $\frac{d\lambda}{dt}(0)$. Return one real scalar."#, h.quadratic([3.0 / 5, 4.0 / 5]))
        case 1:
            let transformed = q.transposed * h * q
            let coupling = transformed[0, 1]
            return (base + #"Let $\lambda(t)$ be the eigenvalue branch equal to the smaller eigenvalue of $A_{0}$ at $t=0$. Compute $\frac{d^{2}\lambda}{dt^{2}}(0)$. Return one real scalar."#, 2 * coupling * coupling / (l - m))
        case 2:
            return (base + #"Compute $\frac{d}{dt}\log(\det(A(t)))$ at $t=0$, using the natural logarithm. Return one real scalar."#, (a.inverse * h).trace)
        default:
            let inverse = a.inverse
            return (base + #"Compute $\frac{d}{dt}\tr(A(t)^{-1})$ at $t=0$. Return one real scalar."#, -(inverse * h * inverse).trace)
        }
    }
}
