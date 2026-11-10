import Foundation

/// Proximal operators, including their penalty and step-size normalizations.
/// Provenance: Parikh & Boyd, Proximal Algorithms, §§6.1, 6.5.
/// https://web.stanford.edu/~boyd/papers/pdf/prox_algs.pdf
enum OptimizationProximalMapQuestions {
    static func instance(_ variant: Int, _ p: MathParameters) -> OptimizationInstance {
        let v = [p[0] - p[1], -(p[2] + p[3]) / 2, (p[4] + p[5]) / 3]
        let lambda = p[6] / 4
        let tau = p[7] / 3
        let threshold = tau * lambda
        let base = #"For $v=\#(OptimizationMath.vector(v))$, $\tau=\#(OptimizationMath.number(tau))$, and $\lambda=\#(OptimizationMath.number(lambda))$, define $$\operatorname{prox}_{\tau h}(v)=\argmin_{x\in\mathbb{R}^{3}}\left\{\frac{1}{2}\|x-v\|_{2}^{2}+\tau h(x)\right\}.$$ "#
        switch variant {
        case 0: return OptimizationInstance(base + #"Take $h(x)=\lambda\|x\|_{1}$. Find coordinate 2 of the proximal point."#, -max(0, -v[1] - threshold))
        case 1:
            let factor = 1 + threshold
            return OptimizationInstance(base + #"Take $h(x)=\frac{\lambda}{2}\|x\|_{2}^{2}$. Find the squared Euclidean norm of the proximal point."#, OptimizationMath.dot(v, v) / (factor * factor))
        case 2:
            let gamma = p[0] / 5
            return OptimizationInstance(base + #"Take $h(x)=\lambda\|x\|_{1}+\frac{\gamma}{2}\|x\|_{2}^{2}$, with $\gamma=\#(OptimizationMath.number(gamma))$. Find coordinate 3 of the proximal point."#, max(0, v[2] - threshold) / (1 + tau * gamma))
        default: return OptimizationInstance(base + #"Take $h(x)=\lambda\|x\|_{2}$ (one group). Find the Euclidean norm of the proximal point."#, max(0, OptimizationMath.norm(v) - threshold))
        }
    }
}
