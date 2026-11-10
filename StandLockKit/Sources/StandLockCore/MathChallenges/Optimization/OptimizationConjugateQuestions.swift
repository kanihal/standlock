import Foundation

/// Fenchel conjugates and support functions with explicit domains.
/// Provenance: Boyd & Vandenberghe, Convex Optimization, §§3.3, 5.1.
/// https://web.stanford.edu/~boyd/cvxbook/bv_cvxbook.pdf
enum OptimizationConjugateQuestions {
    static func instance(_ variant: Int, _ p: MathParameters) -> OptimizationInstance {
        if variant == 1 {
            let tau = p[6] / 3
            let y = [p[0] - p[1], p[2] / 2, -p[3] / 3, p[4] / p[5]]
            let largest = y.max()!
            let value = largest + tau * log(y.reduce(0) { $0 + exp(($1 - largest) / tau) })
            return OptimizationInstance(#"Define $f(x)=\tau\sum_{i=1}^{4}x_i\log(x_i)$ when $x_i\ge0$ and $\sum_{i=1}^{4}x_i=1$, and $f(x)=+\infty$ otherwise; use $0\log 0=0$. For $\tau=\#(OptimizationMath.number(tau))$ and $y=\#(OptimizationMath.vector(y))$, find $f^{*}(y)=\operatorname{sup}_x\{y^{\mathrm{T}}x-f(x)\}$."#, value)
        }
        let h = [[p[0] + 2, 1], [1, p[1] + 2]]
        let c = [p[2] / 3, p[3] / 4]
        let y = [p[4] / 2, -p[5] / 3]
        let inverseY = OptimizationMath.solve2(h, y)
        if variant == 2 {
            let radius = p[6] / 2
            return OptimizationInstance(#"Let $E=\{x\in\mathbb{R}^{2}:(x-c)^{\mathrm{T}}H(x-c)\le r^{2}\}$, with $H=\#(OptimizationMath.matrix(h))$, $c=\#(OptimizationMath.vector(c))$, and $r=\#(OptimizationMath.number(radius))$. At $y=\#(OptimizationMath.vector(y))$, find the support $\sigma_E(y)=\operatorname{sup}_{x\in E}y^{\mathrm{T}}x$."#, OptimizationMath.dot(y, c) + radius * sqrt(OptimizationMath.dot(y, inverseY)))
        }
        let r = p[6] / p[7]
        let conjugate = 0.5 * OptimizationMath.dot(y, inverseY) + OptimizationMath.dot(y, c) - r
        let base = #"Let $f(x)=\frac{1}{2}(x-c)^{\mathrm{T}}H(x-c)+r$ on $\mathbb{R}^{2}$, with $$H=\#(OptimizationMath.matrix(h)),\quad c=\#(OptimizationMath.vector(c)),\quad r=\#(OptimizationMath.number(r)),\quad y=\#(OptimizationMath.vector(y)).$$ Define $f^{*}(y)=\operatorname{sup}_z\{y^{\mathrm{T}}z-f(z)\}$. "#
        if variant == 0 { return OptimizationInstance(base + #"Find $f^{*}(y)$."#, conjugate) }
        let x = [p[6] / 3, -p[7] / 4]
        let offset = zip(x, c).map(-)
        let value = 0.5 * OptimizationMath.dot(offset, OptimizationMath.multiply(h, offset)) + r
        return OptimizationInstance(base + #"For $x=\#(OptimizationMath.vector(x))$, find the Fenchel–Young gap $f(x)+f^{*}(y)-y^{\mathrm{T}}x$."#, value + conjugate - OptimizationMath.dot(y, x))
    }
}
