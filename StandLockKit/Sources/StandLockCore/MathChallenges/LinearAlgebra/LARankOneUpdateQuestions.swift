import Foundation

/// Sherman–Morrison and the determinant lemma; Petersen & Pedersen, §§3.2, 8.1:
/// https://www2.imm.dtu.dk/pubdb/edoc/imm3274.pdf
enum LARankOneUpdateQuestions {
    static func make(_ variant: Int, _ p: MathParameters) -> (prompt: String, answer: Double) {
        let d = LinearAlgebraMatrix.diagonal([p[0] + 1, p[1] + 2, p[2] + 3])
        let u = [p[3], p[4], -p[5]]
        let alpha = p[6] / (p[7] + 2)
        // D is strictly positive and alpha > 0, so the update is always SPD.
        let a = d + LinearAlgebraMatrix.outer(u, u).scaled(alpha)
        let inverse = a.inverse
        let v = [p[7], -p[0], p[2]]
        let base = #"Let $$D=\#(d.text), u=\#(LinearAlgebraMatrix.vectorText(u)).$$ Set $\alpha=\#(LinearAlgebraMatrix.number(alpha))$ and $A=D+\alpha uu^{T}$. All matrices are real and $I$ denotes the identity. "#
        switch variant {
        case 0: return (base + #"Compute $\tr(A^{-1})$. Return one real scalar."#, inverse.trace)
        case 1: return (base + #"Compute $\det(A)$. Return one real scalar."#, a.determinant)
        case 2:
            return (base + #"For $v=\#(LinearAlgebraMatrix.vectorText(v))$, compute $v^{T}A^{-1}v$. Return one real scalar."#, inverse.quadratic(v))
        default:
            return (base + #"Compute $\tr(A^{-2})$, where $A^{-2}=A^{-1}A^{-1}$. Return one real scalar."#, (inverse * inverse).trace)
        }
    }
}
