import Foundation

/// Exact quadratic iterates and explicitly stated named convergence bounds.
/// Provenance: Nesterov, Introductory Lectures on Convex Optimization, §2.2.
/// https://doi.org/10.1007/978-1-4419-8853-9
/// Boyd, Subgradient Methods, §2 (constant-step averaged/best-iterate bound).
/// https://web.stanford.edu/class/ee364b/lectures/subgrad_method_notes.pdf
enum OptimizationConvergenceRateQuestions {
    static func instance(_ variant: Int, _ p: MathParameters) -> OptimizationInstance {
        switch variant {
        case 0:
            let mu = p[0] + 1
            let lipschitz = mu + p[1] + 1
            let x = [p[2] / 2, -(p[3] + p[7]) / 3]
            let alpha = 1 / (lipschitz + p[4] / 2)
            let k = Int(p[5] + p[6])
            let value = 0.5 * mu * x[0] * x[0] * pow(1 - alpha * mu, Double(2 * k))
                + 0.5 * lipschitz * x[1] * x[1] * pow(1 - alpha * lipschitz, Double(2 * k))
            return OptimizationInstance(#"For $f(x)=\frac{1}{2}x^{\mathrm{T}}Hx$ on $\mathbb{R}^{2}$, with $H=\#(OptimizationMath.diagonal([mu, lipschitz]))$, run gradient descent $x_{t+1}=x_t-\alpha\nabla f(x_t)$, starting at $x_0=\#(OptimizationMath.vector(x))$ with $\alpha=\#(OptimizationMath.number(alpha))$. Find $f(x_{\#(k)})-\min f$ after exactly \#(k) updates, with $t$ starting at 0."#, value)
        case 1:
            let mu = p[0] + p[2] / 2
            let lipschitz = mu + p[1] + p[3] / 2
            return OptimizationInstance(#"For symmetric positive-definite quadratic objectives whose Hessian eigenvalues lie in $[\mu,L]$, with $\mu=\#(OptimizationMath.number(mu))$ and $L=\#(OptimizationMath.number(lipschitz))$, gradient descent uses a constant $\alpha>0$. Find the $\alpha$ minimizing the worst-case spectral contraction $\max_{\lambda\in[\mu,L]}|1-\alpha\lambda|$."#, 2 / (mu + lipschitz))
        case 2:
            let mu = p[0] + 1
            let lipschitz = mu + p[1] + 2
            let k = Int(p[2] + p[3])
            let gap = p[4] / 2
            let normSquared = p[5] + p[6] / 3 + p[7] / 4
            let bound = pow(1 - sqrt(mu / lipschitz), Double(k)) * (gap + mu * normSquared / 2)
            return OptimizationInstance(#"Use the Nesterov strongly convex accelerated-gradient upper bound $$B_k=\left(1-\sqrt{\frac{\mu}{L}}\right)^{k}\left[f(x_0)-f^{*}+\frac{\mu}{2}\|x_0-x^{*}\|_{2}^{2}\right]$$ on $f(x_k)-f^{*}$, where $x_0$ is the initial iterate and $k$ counts updates. Given $\mu=\#(OptimizationMath.number(mu))$, $L=\#(OptimizationMath.number(lipschitz))$, $f(x_0)-f^{*}=\#(OptimizationMath.number(gap))$, $\|x_0-x^{*}\|_{2}^{2}=\#(OptimizationMath.number(normSquared))$, and $k=\#(k)$, evaluate this stated bound $B_k$."#, bound)
        default:
            let radius = p[0] / 2
            let numerator = p.values[0] * (3 * p.values[1] + p.values[2])
                * (p.values[5] + p.values[6] + p.values[7] + 10)
            let denominator = 6 * (p.values[3] + p.values[4])
            // Integer arithmetic preserves exact-square boundaries before rounding up.
            let squaredNumerator = numerator * numerator
            let squaredDenominator = denominator * denominator
            let budget = Double((squaredNumerator + squaredDenominator - 1) / squaredDenominator)
            let epsilonNumerator = p.values[3] + p.values[4]
            let epsilonDenominator = p.values[5] + p.values[6] + p.values[7] + 10
            let gradientNumerator = 3 * p.values[1] + p.values[2]
            return OptimizationInstance(#"For a convex objective on a nonempty closed convex set $C$, with $x_0\in C$ and a minimizer $x^{*}\in C$, assume $\|x_0-x^{*}\|_{2}\le R=\#(OptimizationMath.number(radius))$ and all subgradients have norm $\le G=\frac{\#(gradientNumerator)}{3}$ (exact). Use the projected subgradient averaged-iterate bound $$f(\bar{x}_k)-f^{*}\le\frac{RG}{\sqrt{k}},\qquad \bar{x}_k=\frac{1}{k}\sum_{t=0}^{k-1}x_t,$$ with constant step $\frac{R}{G\sqrt{k}}$ for a run of $k\ge1$ updates. For $\varepsilon=\frac{\#(epsilonNumerator)}{\#(epsilonDenominator)}$ (exact), return the smallest positive integer $k$ for which this stated upper bound is $\le\varepsilon$ (round up)."#, budget, kind: .integer)
        }
    }
}
