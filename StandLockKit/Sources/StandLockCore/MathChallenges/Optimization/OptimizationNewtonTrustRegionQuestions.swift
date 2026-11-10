import Foundation

/// Newton decrement, self-concordant damping, trust regions, and logistic Hessians.
/// Provenance: Boyd & Vandenberghe, Convex Optimization, §§9.5–9.6;
/// https://web.stanford.edu/~boyd/cvxbook/bv_cvxbook.pdf
/// Conn, Gould & Toint, Trust Region Methods, §7.3 (quadratic KKT system).
/// https://doi.org/10.1137/1.9780898719857
enum OptimizationNewtonTrustRegionQuestions {
    static func instance(_ variant: Int, _ p: MathParameters) -> OptimizationInstance {
        if variant < 2 {
            let x = [p[0] / 2, p[1] / 3, p[2] / 4]
            let c = [p[3] / 3, p[4] / 4, p[5] / 5]
            let decrement = (0..<3).reduce(0.0) { $0 + pow(c[$1] * x[$1] - 1, 2) }
            let base = #"Let $f(x)=-\sum_{i=1}^{3}\log(x_i)+c^{\mathrm{T}}x$ on $x_i>0$, with $c=\#(OptimizationMath.vector(c))$. At $x=\#(OptimizationMath.vector(x))$, define $$d=-[\nabla^{2}f(x)]^{-1}\nabla f(x),\qquad \lambda^{2}=\nabla f(x)^{\mathrm{T}}[\nabla^{2}f(x)]^{-1}\nabla f(x).$$ "#
            if variant == 0 { return OptimizationInstance(base + #"Find the squared Newton decrement $\lambda^{2}$."#, decrement) }
            let t = 1 / (1 + sqrt(decrement))
            let next = (0..<3).map { x[$0] + t * (x[$0] - c[$0] * x[$0] * x[$0]) }
            return OptimizationInstance(base + #"Use the damped Newton update $x^{+}=x+\frac{d}{1+\lambda}$, with $\lambda\ge0$. Find $f(x^{+})$."#, -next.reduce(0) { $0 + log($1) } + OptimizationMath.dot(c, next))
        }
        if variant == 2 {
            let h = [p[0] + 1, p[1] + 2, p[2] + 3]
            let g = [p[3], p[4], -p[5]]
            let multiplier = p[6] / 2
            let radius = sqrt((0..<3).reduce(0.0) { $0 + pow(g[$1] / (h[$1] + multiplier), 2) })
            let prompt = #"Solve the Euclidean trust-region subproblem $\min_{s\in\mathbb{R}^{3}}\left\{\frac{1}{2}s^{\mathrm{T}}Hs+g^{\mathrm{T}}s:\|s\|_{2}\le\Delta\right\}$, with $$H=\#(OptimizationMath.diagonal(h)),\quad g=\#(OptimizationMath.vector(g)),\quad \Delta=\#(OptimizationMath.number(radius)).$$ Use the Lagrangian $\frac{1}{2}s^{\mathrm{T}}Hs+g^{\mathrm{T}}s+\frac{\mu}{2}(\|s\|_{2}^{2}-\Delta^{2})$, with $\mu\ge0$. Find the optimal multiplier $\mu$."#
            return OptimizationInstance(prompt, multiplier)
        }
        let a = [[1.0, p[0] / 3], [p[1] / 4, -1], [-1, p[2] / 5]]
        let y = [1.0, 0, 1]
        let gamma = p[3] / 4
        let x = [(p[4] - p[5]) / 6, (p[6] - p[7]) / 7]
        var gradient = x.map { gamma * $0 }
        var hessian = [[gamma, 0], [0, gamma]]
        for i in 0..<3 {
            let probability = 1 / (1 + exp(-OptimizationMath.dot(a[i], x)))
            for j in 0..<2 {
                gradient[j] += (probability - y[i]) * a[i][j]
                for k in 0..<2 { hessian[j][k] += probability * (1 - probability) * a[i][j] * a[i][k] }
            }
        }
        let step = OptimizationMath.solve2(hessian, gradient).map { -$0 }
        return OptimizationInstance(#"For $$f(x)=\sum_{i=1}^{3}\left[\log(1+\exp(a_i^{\mathrm{T}}x))-y_i a_i^{\mathrm{T}}x\right]+\frac{\gamma}{2}\|x\|_{2}^{2}$$ (a sum, with no averaging), the rows $a_i^{\mathrm{T}}$ form $A=\#(OptimizationMath.matrix(a))$, with $y=\#(OptimizationMath.vector(y))$ and $\gamma=\#(OptimizationMath.number(gamma))$. At $x=\#(OptimizationMath.vector(x))$, find coordinate 1 of the full Newton direction $d=-[\nabla^{2}f(x)]^{-1}\nabla f(x)$."#, step[0])
    }
}
