import Foundation

// Delta method and CLT:
// https://web.stanford.edu/class/stats200/Lecture17.pdf
// Exponential-moment tail bounds:
// https://courses.csail.mit.edu/6.856/21/Notes/n6-chernoff.html
// https://ocw.mit.edu/courses/15-070j-advanced-stochastic-processes-fall-2013/resources/mit15_070jf13_lec2/
// Bernoulli construction enforces 0 < q < r < 1, so the optimizing tilt is positive.
enum ProbabilityLimitQuestions {
    static let titles = [
        "Delta method for the log sample mean", "CLT probability approximation",
        "Optimized Bernoulli Chernoff bound", "Poisson large deviation rate"
    ]

    static func instance(_ variant: Int, _ p: MathParameters) -> ProbabilityInstance {
        switch variant {
        case 0:
            let values = [p[0], p[1] + 10, p[2] + 20]
            let weights = [p[3], p[4], p[5]]
            let total = weights.reduce(0, +)
            let mean = zip(values, weights).reduce(0) { $0 + $1.0 * $1.1 } / total
            let variance = zip(values, weights).reduce(0) { $0 + $1.1 * pow($1.0 - mean, 2) } / total
            return ProbabilityInstance(#"""
            $X_1,X_2,\ldots$ are IID, taking values $\#(ProbabilityMath.vector(values))$ with respective probabilities $\#(ProbabilityMath.fractions(weights, denominator: total))$.
            Let $\bar{X}_n$ be the sample mean and $m=\mathbb{E}[X_1]$.
            Find $V$ in the delta-method limit $\sqrt{n}(\log\bar{X}_n-\log m)\to\mathcal{N}(0,V)$ in distribution.
            Logarithms are natural; $V$ is the limiting variance, not $V/n$ or a standard deviation.
            """#, variance / (mean * mean))
        case 1:
            let rate = (p[0] + 1) / 3
            let n = 50 + 5 * p[1]
            let z = (p[2] - 5) / 3
            let threshold = (1 + z / sqrt(n)) / rate
            return ProbabilityInstance(#"""
            $X_1,\ldots,X_n$ are IID $\operatorname{Exponential}(\mathrm{rate}\ \lambda)$, with density $\lambda\exp(-\lambda x)$ for $x>0$.
            $\lambda=\#(ProbabilityMath.number(rate))$, $n=\#(ProbabilityMath.number(n))$, and $c=\#(ProbabilityMath.number(threshold))$.
            Using the CLT normal approximation for $\bar{X}_n$, find $\mathbb{P}(\bar{X}_n\le c)$.
            Use no continuity correction; report the approximate probability.
            """#, 0.5 * erfc(-z / sqrt(2)))
        case 2:
            let probability = p[0] / (p[0] + p[1] + 2)
            let threshold = (p[0] + p[2] + 1) / (p[0] + p[1] + p[2] + 3)
            let n = 20 + p[3]
            let divergence = threshold * log(threshold / probability)
                + (1 - threshold) * log((1 - threshold) / (1 - probability))
            return ProbabilityInstance(#"""
            $X_1,\ldots,X_n$ are IID $\operatorname{Bernoulli}(q)$, where $q=\#(ProbabilityMath.number(probability))$, $n=\#(ProbabilityMath.number(n))$, and $r=\#(ProbabilityMath.number(threshold))$.
            Find the optimized exponential-moment Chernoff upper bound on $\mathbb{P}(\sum_{i=1}^{n}X_i\ge nr)$,
            optimizing over nonnegative exponential tilts. The threshold is $nr$ as written, without integer rounding.
            Give the bound itself, not its logarithm; use the exact Bernoulli moment generating function.
            """#, exp(-n * divergence))
        default:
            let rate = p[0] + 1
            let threshold = rate + p[1] / 2
            return ProbabilityInstance(#"""
            $X_1,X_2,\ldots$ are IID $\operatorname{Poisson}(\lambda)$, with $\lambda=\#(ProbabilityMath.number(rate))$. Let $a=\#(ProbabilityMath.number(threshold))>\lambda$.
            Find the large deviation rate
            $$\lim_{n\to\infty}-\frac{1}{n}\log\mathbb{P}(\bar{X}_n\ge a),$$
            using natural logarithms. Give the limiting rate, not a finite-sample tail probability.
            """#, threshold * log(threshold / rate) - threshold + rate)
        }
    }
}
