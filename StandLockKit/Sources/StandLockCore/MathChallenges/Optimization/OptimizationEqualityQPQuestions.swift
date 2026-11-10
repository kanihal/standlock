import Foundation

/// Equality-constrained quadratic programming and value sensitivity.
/// Provenance: Boyd & Vandenberghe, Convex Optimization, §§5.6, 10.1.
/// https://web.stanford.edu/~boyd/cvxbook/bv_cvxbook.pdf
enum OptimizationEqualityQPQuestions {
    static func instance(_ variant: Int, _ p: MathParameters) -> OptimizationInstance {
        let h = [p[0] + 1, p[1] + 2, p[2] + 3]
        let q = [p[3], -p[4], p[5]]
        let rhs = [p[6] / 2, p[7] / 3]
        func solve(_ b: [Double]) -> (Double, [Double]) {
            let t = (h[0] * b[0] + h[2] * b[1] + q[0] - q[1] + q[2]) / h.reduce(0, +)
            let x = [b[0] - t, t, b[1] - t]
            let value = zip(h, x).reduce(0) { $0 + 0.5 * $1.0 * $1.1 * $1.1 }
                + OptimizationMath.dot(q, x)
            return (value, [-h[0] * x[0] - q[0], -h[2] * x[2] - q[2]])
        }
        let (value, multipliers) = solve(rhs)
        let base = #"Minimize $f(x)=\frac{1}{2}x^{\mathrm{T}}Hx+q^{\mathrm{T}}x$ over $x\in\mathbb{R}^{3}$ subject to $Ax=b$, where $$H=\#(OptimizationMath.diagonal(h)),\quad q=\#(OptimizationMath.vector(q)),\quad A=\#(OptimizationMath.matrix([[1, 1, 0], [0, 1, 1]])),\quad b=\#(OptimizationMath.vector(rhs)).$$ Use $L(x,\lambda)=f(x)+\lambda^{\mathrm{T}}(Ax-b)$. "#
        switch variant {
        case 0: return OptimizationInstance(base + "Find the optimal objective value.", value)
        case 1: return OptimizationInstance(base + #"Find the first component $\lambda_{1}$ of the optimal multiplier."#, multipliers[0])
        case 2: return OptimizationInstance(base + #"For the value function $v(b)$, find $\frac{\partial v}{\partial b_{1}}$ at the supplied $b$."#, -multipliers[0])
        default:
            let delta = [p[3] / 10, -p[4] / 12]
            let perturbed = zip(rhs, delta).map(+)
            return OptimizationInstance(base + #"Let $\delta=\#(OptimizationMath.vector(delta))$. Find the exact change $v(b+\delta)-v(b)$."#, solve(perturbed).0 - value)
        }
    }
}
