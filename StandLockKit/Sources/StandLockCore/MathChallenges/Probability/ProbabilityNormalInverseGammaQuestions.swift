import Foundation

// Normal–inverse-gamma posterior and marginal likelihood, with β an inverse-gamma scale:
// https://www.cs.ubc.ca/~murphyk/Papers/bayesGauss.pdf (normal prior, unknown mean and variance).
// α₀ ≥ 3 and n ≥ 3 guarantee every requested posterior variance exists.
enum ProbabilityNormalInverseGammaQuestions {
    static let titles = [
        "Normal–inverse-gamma predictive variance", "Posterior variance of the Gaussian mean",
        "Posterior expected precision", "Gaussian log marginal likelihood"
    ]

    static func instance(_ variant: Int, _ p: MathParameters) -> ProbabilityInstance {
        let n = p[0] + 2
        let sampleMean = p[1] - 5
        let centeredSSE = p[2] + p[3]
        let priorMean = p[4] - 5
        let kappa0 = p[5] + 1
        let alpha0 = p[6] + 2
        let beta0 = p[7] + 1
        let kappa = kappa0 + n
        let alpha = alpha0 + n / 2
        let difference = sampleMean - priorMean
        let beta = beta0 + centeredSSE / 2 + kappa0 * n * difference * difference / (2 * kappa)
        let given = #"""
        Given $\mu,v$, the observations are IID $X_i \sim \mathcal{N}(\mu,v)$, where $v$ is the variance.
        The prior is $\mu \mid v \sim \mathcal{N}(\mu_0,\frac{v}{\kappa_0})$ and $v \sim \operatorname{InverseGamma}(\alpha_0,\beta_0)$, with density
        $$f(v) = \frac{\beta_0^{\alpha_0}}{\Gamma(\alpha_0)} v^{-\alpha_0-1} \exp\left(-\frac{\beta_0}{v}\right),\quad v>0.$$
        $\mu_0 = \#(ProbabilityMath.number(priorMean))$, $\kappa_0 = \#(ProbabilityMath.number(kappa0))$, $\alpha_0 = \#(ProbabilityMath.number(alpha0))$, $\beta_0 = \#(ProbabilityMath.number(beta0))$.
        The observed $n = \#(ProbabilityMath.number(n))$ values have sample mean $\bar{x} = \#(ProbabilityMath.number(sampleMean))$ and centered sum of squares
        $$\sum_{i=1}^{n}(x_i-\bar{x})^2 = \#(ProbabilityMath.number(centeredSSE)).$$
        """#
        switch variant {
        case 0:
            return ProbabilityInstance(#"""
            \#(given)
            Find $\operatorname{Var}(X_{n+1}\mid\mathrm{data})$, the posterior predictive variance of one new observation.
            """#, beta / (alpha - 1) * (1 + 1 / kappa))
        case 1:
            return ProbabilityInstance(#"""
            \#(given)
            Find $\operatorname{Var}(\mu\mid\mathrm{data})$, the marginal posterior variance of the unknown mean.
            """#, beta / ((alpha - 1) * kappa))
        case 2:
            return ProbabilityInstance(#"""
            \#(given)
            Find the posterior expected precision $\mathbb{E}[\frac{1}{v}\mid\mathrm{data}]$.
            """#, alpha / beta)
        default:
            let answer = lgamma(alpha) - lgamma(alpha0) + alpha0 * log(beta0) - alpha * log(beta)
                + 0.5 * log(kappa0 / kappa) - n / 2 * log(2 * Double.pi)
            return ProbabilityInstance(#"""
            \#(given)
            Find $\log p(x_1,\ldots,x_n)$, the natural log marginal density of this ordered sample, integrating over both $\mu$ and $v$ (not the density of the summary statistics).
            """#, answer)
        }
    }
}
