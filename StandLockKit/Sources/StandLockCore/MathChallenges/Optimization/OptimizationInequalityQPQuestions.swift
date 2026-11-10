import Foundation

/// Strictly convex box QPs with a constructed strictly complementary upper face.
/// Provenance: Boyd & Vandenberghe, Convex Optimization, §§5.2, 5.5.
/// https://web.stanford.edu/~boyd/cvxbook/bv_cvxbook.pdf
enum OptimizationInequalityQPQuestions {
    static func instance(_ variant: Int, _ p: MathParameters) -> OptimizationInstance {
        let h = [[p[0] + 2, 1], [1, p[1] + 2]]
        let upper = [p[4] / 2, p[5] / 2]
        let constructed = [upper[0], upper[1] / (1 + p[6])]
        let linear = OptimizationMath.multiply(h, constructed)
        let q = [-linear[0] - p[2] - p[3] / 2, -linear[1]]
        let optimum = OptimizationMath.boxMinimum(h, q, upper)
        let value = OptimizationMath.objective(h, q, optimum)
        let base = #"Minimize $f(x)=\frac{1}{2}x^{\mathrm{T}}Hx+q^{\mathrm{T}}x$ over $x\in\mathbb{R}^{2}$ with $0\le x\le U$ componentwise, where $$H=\#(OptimizationMath.matrix(h)),\quad q=\#(OptimizationMath.vector(q)),\quad U=\#(OptimizationMath.vector(upper)).$$ Use $L(x,\ell,u)=f(x)-\ell^{\mathrm{T}}x+u^{\mathrm{T}}(x-U)$, with $\ell,u\ge0$, and $g(\ell,u)=\operatorname{inf}_{x}L(x,\ell,u)$. "#
        switch variant {
        case 0: return OptimizationInstance(base + "Find the optimal primal objective value.", value)
        case 1:
            let gradient = OptimizationMath.multiply(h, optimum)
            return OptimizationInstance(base + #"The constraint $x_{1}\le U_{1}$ is active. Find its optimal multiplier $u_{1}$."#, -gradient[0] - q[0])
        case 2: return OptimizationInstance(base + #"Find the optimal dual objective value $\max_{\ell,u\ge0}g(\ell,u)$."#, value)
        default:
            let x = [upper[0] / 2, upper[1] / 3]
            let low = [p[6] / 4, p[7] / 5]
            let up = [p[2] / 3, p[3] / 4]
            let z = (0..<2).map { q[$0] - low[$0] + up[$0] }
            let dual = -0.5 * OptimizationMath.dot(z, OptimizationMath.solve2(h, z)) - OptimizationMath.dot(up, upper)
            return OptimizationInstance(base + #"At the feasible pair $x=\#(OptimizationMath.vector(x))$, $\ell=\#(OptimizationMath.vector(low))$, $u=\#(OptimizationMath.vector(up))$, find the primal–dual gap $f(x)-g(\ell,u)$."#, OptimizationMath.objective(h, q, x) - dual)
        }
    }
}
