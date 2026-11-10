import Foundation

/// Stationary iterations, optimal SOR for consistently ordered SPD matrices,
/// and unpreconditioned CG, Barrett et al., Templates (1994), Chapter 2:
/// https://www.netlib.org/templates/templates.pdf
enum LAIterativeSolverQuestions {
    static func make(_ variant: Int, _ p: MathParameters) -> (prompt: String, answer: Double) {
        if variant == 3 { return conjugateGradient(p) }
        let a = p[2] + p[0] + 1, b = p[2] + p[1] + 1, c = p[2]
        // a > c > 0 and b > c imply SPD and Jacobi convergence.
        let matrix = LinearAlgebraMatrix([[a, c], [c, b]])
        let rhoSquared = c * c / (a * b)
        let base = #"Consider solving $Ax=b$ with the real SPD matrix $$A=\#(matrix.text).$$ Split $A=D+L+U$ into its diagonal, strictly lower, and strictly upper parts. Use variable order 1, then 2. "#
        switch variant {
        case 0:
            return (base + #"Compute the spectral radius of the Jacobi error iteration matrix $-D^{-1}(L+U)$. Return one real scalar."#, sqrt(rhoSquared))
        case 1:
            return (base + #"Compute the spectral radius of the forward Gauss–Seidel error iteration matrix $-(D+L)^{-1}U$. Return one real scalar."#, rhoSquared)
        default:
            return (base + #"For forward SOR with error iteration matrix $(D+\omega L)^{-1}((1-\omega)D-\omega U)$, find the relaxation parameter $\omega\in(0,2)$ that minimizes its spectral radius. Return one real scalar."#, 2 / (1 + sqrt(1 - rhoSquared)))
        }
    }

    private static func conjugateGradient(_ p: MathParameters) -> (prompt: String, answer: Double) {
        let l1 = p[0] + 1, l2 = l1 + p[1] + 1, l3 = l2 + p[2] + 1
        let eigenvalues = [l1, l2, l3]
        let a = LinearAlgebraMatrix.diagonal(eigenvalues)
        let b = [p[3], -p[4], p[5]]
        var x = [0.0, 0.0, 0.0], residual = b, direction = b
        // Three distinct eigenvalues and three nonzero components ensure that
        // both requested CG updates have strictly positive denominators.
        for _ in 0..<2 {
            let ad = a.applied(to: direction)
            let rr = LinearAlgebraMatrix.dot(residual, residual)
            let alpha = rr / LinearAlgebraMatrix.dot(direction, ad)
            x = (0..<3).map { x[$0] + alpha * direction[$0] }
            let nextResidual = (0..<3).map { residual[$0] - alpha * ad[$0] }
            let beta = LinearAlgebraMatrix.dot(nextResidual, nextResidual) / rr
            direction = (0..<3).map { nextResidual[$0] + beta * direction[$0] }
            residual = nextResidual
        }
        let error = (0..<3).map { b[$0] / eigenvalues[$0] - x[$0] }
        let prompt = #"Solve $Ax=b$ for $$A=\#(a.text), b=\#(LinearAlgebraMatrix.vectorText(b)).$$ Run ordinary unpreconditioned conjugate gradients in exact arithmetic from $x_{0}=0$, with $r_{0}=b$ and $p_{0}=r_{0}$. Each iteration means one step-length update to $x$; $x_{2}$ is after exactly two such updates. For the exact solution $x^{*}$, compute the squared energy error $(x_{2}-x^{*})^{T}A(x_{2}-x^{*})$. Return one real scalar."#
        return (prompt, a.quadratic(error))
    }
}
