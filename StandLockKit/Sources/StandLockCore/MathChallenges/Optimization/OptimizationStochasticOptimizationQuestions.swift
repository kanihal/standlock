import Foundation

/// Finite-population expectations, optimal importance probabilities, and SVRG.
/// Provenance: Johnson & Zhang, Accelerating Stochastic Gradient Descent using
/// Predictive Variance Reduction (2013), Algorithm 1.
/// https://papers.nips.cc/paper_files/paper/2013/hash/ac1dd209cbcc5e5d1c6e28598e8cbbe8-Abstract.html
/// Zhao & Zhang, Stochastic Optimization with Importance Sampling (2015), §3.
/// https://proceedings.mlr.press/v37/zhaoa15.html
enum OptimizationStochasticOptimizationQuestions {
    static func instance(_ variant: Int, _ p: MathParameters) -> OptimizationInstance {
        if variant == 2 {
            let gradients = [[p[0], -p[1]], [p[2], p[3]], [-p[4] * p[6] / 3, p[5] * p[7] / 4]]
            let normSum = gradients.reduce(0) { $0 + OptimizationMath.norm($1) }
            let mean = (0..<2).map { j in gradients.reduce(0) { $0 + $1[j] } / 3 }
            let minimumVariance = normSum * normSum / 9 - OptimizationMath.dot(mean, mean)
            return OptimizationInstance(#"At a fixed point $x$, three finite-sum component gradients in $\mathbb{R}^{2}$ are $g_1=\#(OptimizationMath.vector(gradients[0]))$, $g_2=\#(OptimizationMath.vector(gradients[1]))$, and $g_3=\#(OptimizationMath.vector(gradients[2]))$. The full gradient is $\bar{g}=\frac{g_1+g_2+g_3}{3}$. Choose probabilities $q_i>0$ with $\sum_{i=1}^{3}q_i=1$, sample $I$ with $\operatorname{Pr}(I=i)=q_i$, and use the unbiased estimator $\hat{g}=\frac{g_I}{3q_I}$. Find $\min_q\mathbb{E}\|\hat{g}-\bar{g}\|_{2}^{2}$."#, minimumVariance)
        }
        let a = [p[0] + 1, p[1] + 2, p[2] + 3]
        let b = [p[3] / 3, -p[4] / 4, p[5] / 5]
        let x = (p[6] - p[7]) / 3
        let gradients = (0..<3).map { a[$0] * (x - b[$0]) }
        let mean = gradients.reduce(0, +) / 3
        let base = #"Let $f_i(z)=\frac{a_i}{2}(z-b_i)^{2}$ on $\mathbb{R}$ and $F(z)=\frac{f_1(z)+f_2(z)+f_3(z)}{3}$, with $a=\#(OptimizationMath.vector(a))$ and $b=\#(OptimizationMath.vector(b))$. Sample $I$ uniformly from $\{1,2,3\}$. At $x=\#(OptimizationMath.number(x))$, "#
        if variant == 0 {
            let eta = 1 / (a.max()! + 1)
            let expected = gradients.reduce(0) { total, gradient in
                let next = x - eta * gradient
                return total + (0..<3).reduce(0.0) { $0 + a[$1] * pow(next - b[$1], 2) / 6 } / 3
            }
            return OptimizationInstance(base + #"take $x^{+}=x-\eta f'_I(x)$, with $\eta=\#(OptimizationMath.number(eta))$. Find $\mathbb{E}_I[F(x^{+})]$, averaging the full objective after each sampled update."#, expected)
        }
        if variant == 1 {
            let variance = gradients.reduce(0) { $0 + pow($1 - mean, 2) } / 3
            return OptimizationInstance(base + #"find the population variance $\mathbb{E}_I[(f'_I(x)-F'(x))^{2}]$ of the unscaled stochastic gradient (denominator 3)."#, variance)
        }
        let snapshot = (p[6] + p[7]) / 4
        let snapshotGradient = (0..<3).reduce(0.0) { $0 + a[$1] * (snapshot - b[$1]) } / 3
        let estimates = (0..<3).map { gradients[$0] - a[$0] * (snapshot - b[$0]) + snapshotGradient }
        let variance = estimates.reduce(0) { $0 + pow($1 - mean, 2) } / 3
        return OptimizationInstance(base + #"use snapshot $w=\#(OptimizationMath.number(snapshot))$ and SVRG estimator $v_I=f'_I(x)-f'_I(w)+F'(w)$. Find $\mathbb{E}_I[(v_I-F'(x))^{2}]$, with $x$ and $w$ held fixed."#, variance)
    }
}
