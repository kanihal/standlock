import Foundation

// GLRT and Neyman–Pearson likelihood-ratio conventions:
// https://web.stanford.edu/class/stats200/Lecture22.pdf
// https://artowen.su.domains/courses/200/lec08.pdf
// Fisher/score information: https://web.stanford.edu/class/stats200/Lecture15.pdf
// Wald covariance is the covariance of the estimate itself, not its √n limit.
// The NP construction has strictly increasing ratios and an exactly attainable size.
enum ProbabilityTestQuestions {
    static let titles = [
        "Multivariate Wald statistic", "Logistic intercept score test",
        "Gaussian mean likelihood ratio", "Neyman–Pearson included boundary"
    ]

    static func instance(_ variant: Int, _ p: MathParameters) -> ProbabilityInstance {
        switch variant {
        case 0:
            let estimate = [p[0] / 3, p[1] / 4]
            let null = [(p[2] - 5) / 4, (p[3] - 5) / 5]
            let a = p[4] + 1
            let b = p[5] + 1
            let c = (p[6] - 5) / 3
            let n = p[7] + 10
            let s11 = (a + c * c) / n
            let s12 = c / n
            let s22 = b / n
            let d1 = estimate[0] - null[0]
            let d2 = estimate[1] - null[1]
            let answer = (s22 * d1 * d1 - 2 * s12 * d1 * d2 + s11 * d2 * d2)
                / (s11 * s22 - s12 * s12)
            return ProbabilityInstance(#"""
            A bivariate parameter estimate is $\hat{\theta}=\#(ProbabilityMath.vector(estimate))$.
            Its estimated sampling covariance $\operatorname{Cov}(\hat{\theta})$ is the matrix
            $$V=\#(ProbabilityMath.matrix([[s11, s12], [s12, s22]])).$$
            $V$ already includes the sample-size scaling. Test $H_0:\theta=\#(ProbabilityMath.vector(null))$.
            Find the multivariate Wald statistic for this two-coordinate null.
            """#, answer)
        case 1:
            let n = p[0] + p[1] + 2
            let successes = p[0] + 1
            let beta0 = (p[2] - 5) / 3
            let probability = 1 / (1 + exp(-beta0))
            let score = successes - n * probability
            return ProbabilityInstance(#"""
            $Y_1,\ldots,Y_n$ are independent Bernoulli observations with an intercept-only logistic model
            $$\mathbb{P}(Y_i=1)=\frac{e^{\beta}}{1+e^{\beta}}.$$
            There are $n=\#(ProbabilityMath.number(n))$ observations and $\#(ProbabilityMath.number(successes))$ successes.
            For $H_0:\beta=\#(ProbabilityMath.number(beta0))$, find the one-degree-of-freedom squared score statistic $\frac{U(\beta_0)^2}{I_n(\beta_0)}$,
            using expected Fisher information at the null.
            """#, score * score / (n * probability * (1 - probability)))
        case 2:
            let variance = p[0] + 1
            let n = p[1] + 2
            let sampleMean = (p[2] - 5) / 3
            let nullMean = (p[3] - 5) / 4
            let difference = sampleMean - nullMean
            return ProbabilityInstance(#"""
            $X_1,\ldots,X_n$ are IID $\mathcal{N}(\mu,v)$, with known variance $v=\#(ProbabilityMath.number(variance))$.
            $n=\#(ProbabilityMath.number(n))$ and the observed sample mean is $\bar{x}=\#(ProbabilityMath.number(sampleMean))$.
            Test $H_0:\mu=\#(ProbabilityMath.number(nullMean))$ against the unrestricted alternative $\mu\in\mathbb{R}$.
            Define $\Lambda=\frac{L(\mu_0)}{\sup_{\mu\in\mathbb{R}}L(\mu)}$. Find $-2\log\Lambda$, using natural logarithms.
            """#, n * difference * difference / variance)
        default:
            let weights = [p[0], p[1], p[2], p[3]]
            let ratios = [p[4], p[4] + p[5], p[4] + p[5] + p[6], p[4] + p[5] + p[6] + p[7]]
            let total0 = weights.reduce(0, +)
            let numerators1 = zip(weights, ratios).map(*)
            let total1 = numerators1.reduce(0, +)
            let includedCount = 1 + (p.values[0] + p.values[7]) % 3
            let boundary = 4 - includedCount
            let sizeNumerator = weights[boundary...].reduce(0, +)
            let answer = ratios[boundary] * total0 / total1
            return ProbabilityInstance(#"""
            One observation $X$ has support $\{1,2,3,4\}$. Test the simple hypotheses with respective PMFs in this support order:
            $$H_0:f_0=\#(ProbabilityMath.fractions(weights, denominator: total0)),$$
            $$H_1:f_1=\#(ProbabilityMath.fractions(numerators1, denominator: total1)).$$
            The required size is exactly $\alpha=\#(MathLatex.fraction(sizeNumerator, total0))$. Use the most powerful size-$\alpha$ test with no randomization,
            rejecting iff $\frac{f_1(X)}{f_0(X)}\ge\mathrm{cutoff}$. Give the smallest included likelihood ratio $\frac{f_1(x)}{f_0(x)}$,
            rather than any other cutoff producing the same rejection region.
            """#, answer)
        }
    }
}
