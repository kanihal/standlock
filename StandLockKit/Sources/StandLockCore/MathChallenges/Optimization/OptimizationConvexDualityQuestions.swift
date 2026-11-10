import Foundation

/// Strict convexity and a positive equality-dual domain give a unique multiplier.
/// Provenance: Boyd & Vandenberghe, Convex Optimization, §§5.1, 5.6.
/// https://web.stanford.edu/~boyd/cvxbook/bv_cvxbook.pdf
enum OptimizationConvexDualityQuestions {
    static func instance(_ variant: Int, _ p: MathParameters) -> OptimizationInstance {
        let a = [p[0], p[1] + 1, p[2] + 2]
        let w = [p[3] + 1, p[4] + 1, p[5] + 1]
        let b = (p[6] - p[7]) / 2
        let sumA = a.reduce(0, +)
        let weightedLog = (0..<3).reduce(0.0) { $0 + a[$1] * log(a[$1] / w[$1]) }
        let optimum = exp((b - weightedLog) / sumA)
        let base = #"Consider $\min_{x\in\mathbb{R}^{3}}\sum_{i=1}^{3}w_i\exp(x_i)$ subject to $a^{\mathrm{T}}x=b$, where $$a=\#(OptimizationMath.vector(a)),\quad w=\#(OptimizationMath.vector(w)),\quad b=\#(OptimizationMath.number(b)).$$ Define $L(x,\lambda)=\sum_{i=1}^{3}w_i\exp(x_i)+\lambda(b-a^{\mathrm{T}}x)$ and $g(\lambda)=\operatorname{inf}_x L(x,\lambda)$. "#
        switch variant {
        case 0:
            let lambda = p[6] / (p[7] + 1)
            let value = lambda * b + (0..<3).reduce(0.0) { $0 + lambda * a[$1] * (1 - log(lambda * a[$1] / w[$1])) }
            return OptimizationInstance(base + #"Find $g(\lambda)$ at $\lambda=\#(OptimizationMath.number(lambda))$."#, value)
        case 1: return OptimizationInstance(base + #"Find the unique optimal dual multiplier $\lambda^{*}$."#, optimum)
        case 2: return OptimizationInstance(base + #"Let $v(b)$ be the optimal primal value as the right-hand side varies. Find $\frac{dv}{db}$ at the supplied $b$."#, optimum)
        default: return OptimizationInstance(base + "Recover the primal minimizer from a dual optimum and report its primal objective value.", optimum * sumA)
        }
    }
}
