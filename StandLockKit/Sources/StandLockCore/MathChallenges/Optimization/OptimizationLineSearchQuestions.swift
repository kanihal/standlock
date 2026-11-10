import Foundation

/// Finite-grid Armijo/strong Wolfe searches and a precisely counted backtracking loop.
/// Provenance: Nocedal & Wright, Numerical Optimization, Chapter 3.
/// https://doi.org/10.1007/978-0-387-40065-5
/// Boyd & Vandenberghe, Convex Optimization, §9.2.
/// https://web.stanford.edu/~boyd/cvxbook/bv_cvxbook.pdf
enum OptimizationLineSearchQuestions {
    static func instance(_ variant: Int, _ p: MathParameters) -> OptimizationInstance {
        let h = [p[0] + 1, p[1] + 2]
        let x = [p[2] / 2, -p[3] / 3]
        let gradient = [h[0] * x[0], h[1] * x[1]]
        let d = [-gradient[0] / (p[4] + 1), -gradient[1] / (p[5] + 1)]
        let slope = OptimizationMath.dot(gradient, d)
        let curvature = h[0] * d[0] * d[0] + h[1] * d[1] * d[1]
        let exact = -slope / curvature
        let base = #"Let $f(z)=\frac{1}{2}z^{\mathrm{T}}Hz$ on $\mathbb{R}^{2}$, with $H=\#(OptimizationMath.diagonal(h))$, $x=\#(OptimizationMath.vector(x))$, and search direction $d=\#(OptimizationMath.vector(d))$. Write $\phi(\alpha)=f(x+\alpha d)$. "#
        if variant == 0 { return OptimizationInstance(base + #"Find the exact minimizing step $\alpha\ge0$."#, exact) }
        let grid = [0.125, 0.25, 0.5, 1, 1.5, 2, 3].map { $0 * exact }
        let c1 = (p[6] + 1) / 20
        // For this quadratic, both tests can be evaluated without subtracting nearly equal losses.
        func armijo(_ alpha: Double, _ constant: Double) -> Bool {
            (1 - constant) * slope + 0.5 * alpha * curvature <= 1e-13 * abs(slope)
        }
        if variant == 1 {
            let accepted = grid.filter { armijo($0, c1) }.max()!
            return OptimizationInstance(base + #"On the supplied finite grid $G=\#(OptimizationMath.vector(grid))$, find the largest $\alpha$ satisfying Armijo: $$\phi(\alpha)\le\phi(0)+c_1\alpha\phi'(0),\qquad c_1=\#(OptimizationMath.number(c1)).$$"#, accepted)
        }
        if variant == 2 {
            let c2 = 0.75 + 0.02 * p[7]
            let accepted = grid.filter { armijo($0, c1) && abs(slope + $0 * curvature) <= c2 * abs(slope) }.min()!
            return OptimizationInstance(base + #"On $G=\#(OptimizationMath.vector(grid))$, find the smallest $\alpha$ satisfying both Armijo and the strong Wolfe curvature condition: $$\phi(\alpha)\le\phi(0)+c_1\alpha\phi'(0),\qquad |\phi'(\alpha)|\le c_2|\phi'(0)|.$$ Here $c_1=\#(OptimizationMath.number(c1))$ and $c_2=\#(OptimizationMath.number(c2))$."#, accepted)
        }
        let alpha0 = exact * (p[6] + 2)
        let constant = 0.1 + p[7] / 25
        var alpha = alpha0
        var count = 0
        while !armijo(alpha, constant) { alpha *= 0.5; count += 1 }
        return OptimizationInstance(base + #"Use Armijo backtracking with $\alpha_0=\#(OptimizationMath.number(alpha0))$, $\rho=0.5$, and $c_1=\#(OptimizationMath.number(constant))$. Test $\alpha_m=\alpha_0\rho^{m}$ for $m=0,1,2,\ldots$ in that order; accept the first $\phi(\alpha_m)\le\phi(0)+c_1\alpha_m\phi'(0)$. Return $m$, the number of reductions (the initial test counts as zero reductions)."#, Double(count), kind: .integer)
    }
}
