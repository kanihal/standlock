import Foundation

/// Jordan definition of matrix functions, Higham & Al-Mohy (2010), §2:
/// https://eprints.maths.manchester.ac.uk/1406/1/covered/MIMS_ep2010_18.pdf
enum LAJordanFunctionQuestions {
    static func make(_ variant: Int, _ p: MathParameters) -> (prompt: String, answer: Double) {
        let lambda = p[0] / 3
        let c = p[1], d = p[2]
        let j = LinearAlgebraMatrix([[lambda, c, 0], [0, lambda, d], [0, 0, lambda]])
        let base = #"Let $$J=\#(j.text).$$ Matrix entries use 1-based row and column indices, and $I$ is the $3\times3$ identity. "#
        switch variant {
        case 0:
            let t = p[3] / 4
            return (base + #"For $t=\#(LinearAlgebraMatrix.number(t))$, find entry $(1,3)$ of the matrix exponential $\exp(tJ)$. Return one real scalar."#, exp(t * lambda) * t * t * c * d / 2)
        case 1:
            let n = Int(p[3]) + 2
            return (base + #"Find entry $(1,3)$ of $J^{\#(n)}$, using ordinary matrix multiplication. Return one real scalar."#, Double(n * (n - 1)) / 2 * pow(lambda, Double(n - 2)) * c * d)
        case 2:
            let z = lambda + p[4] + 1
            return (base + #"For $z=\#(LinearAlgebraMatrix.number(z))$, find entry $(1,3)$ of the resolvent $(zI-J)^{-1}$. Return one real scalar."#, c * d / pow(z - lambda, 3))
        default:
            return (base + #"Let $f(x)=x^{3}+\#(Int(p[4]))x^{2}+\#(Int(p[5]))x+\#(Int(p[6]))$. Find entry $(1,3)$ of $f(J)$, with the constant term multiplying $I$. Return one real scalar."#, c * d * (3 * lambda + p[4]))
        }
    }
}
