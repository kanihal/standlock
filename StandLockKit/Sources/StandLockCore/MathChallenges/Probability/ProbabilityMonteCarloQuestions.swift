import Foundation

// Importance sampling and control variates (Art Owen, Monte Carlo theory):
// https://artowen.su.domains/mc/Ch-var-is.pdf
// https://artowen.su.domains/mc/Ch-var-basic.pdf
// Autocorrelation-based ESS, including ESS > n under anticorrelation:
// https://mc-stan.org/docs/reference-manual/analysis.html
// Positive proposal weights ensure finite variance; |ρ| ≤ 0.8 guarantees stationary AR(1).
enum ProbabilityMonteCarloQuestions {
    static let titles = [
        "Finite importance sampling variance", "Self-normalized importance estimate",
        "Optimal control variate coefficient", "Stationary AR(1) asymptotic effective sample size"
    ]

    static func instance(_ variant: Int, _ p: MathParameters) -> ProbabilityInstance {
        switch variant {
        case 0:
            let proposalWeights = [p[0], p[1], p[2]]
            let proposalTotal = proposalWeights.reduce(0, +)
            let targetWeights = [p[6], p[7], p[0] + 1]
            let targetTotal = targetWeights.reduce(0, +)
            let values = [-p[3], p[4], p[5] + 1]
            let n = p[1] + 2
            let mean = zip(targetWeights, values).reduce(0) { $0 + $1.0 * $1.1 } / targetTotal
            let secondMoment = (0..<3).reduce(0.0) { result, index in
                let target = targetWeights[index] / targetTotal
                let proposal = proposalWeights[index] / proposalTotal
                return result + target * target * values[index] * values[index] / proposal
            }
            return ProbabilityInstance(#"""
            On the support $\{1,2,3\}$, the normalized target PMF $\pi$ and proposal PMF $q$ are
            $$\pi=\#(ProbabilityMath.fractions(targetWeights, denominator: targetTotal)),$$
            $$q=\#(ProbabilityMath.fractions(proposalWeights, denominator: proposalTotal)).$$
            The function values $f(1),f(2),f(3)$ are $\#(ProbabilityMath.vector(values))$. Draw $n=\#(ProbabilityMath.number(n))$ IID samples $X_i$ from $q$.
            Find the variance of the ordinary importance estimate $\frac{1}{n}\sum_{i=1}^{n}\frac{f(X_i)\pi(X_i)}{q(X_i)}$ of $\mathbb{E}_{\pi}[f(X)]$.
            """#, (secondMoment - mean * mean) / n)
        case 1:
            let values = [-p[0], p[1], p[2] + 1]
            let weights = [p[3], p[4], p[5]]
            let counts = [p[6], p[7], Double(1 + p.values[0] % 3)]
            let numerator = (0..<3).reduce(0.0) { $0 + counts[$1] * weights[$1] * values[$1] }
            let denominator = zip(counts, weights).reduce(0) { $0 + $1.0 * $1.1 }
            return ProbabilityInstance(#"""
            A realized importance sample contains three kinds of observation. Their function values, importance weights, and multiplicities are
            $$f=\#(ProbabilityMath.vector(values)),$$
            $$w=\#(ProbabilityMath.vector(weights)),$$
            $$\mathrm{multiplicity}=\#(ProbabilityMath.vector(counts)).$$
            Each $w$ is the unnormalized target-density/proposal-density ratio for that observation; all weights share one unknown common normalization constant. Repeated observations have repeated weights.
            Find the self-normalized importance estimate of the target expectation of $f$ from this realized sample.
            """#, numerator / denominator)
        case 2:
            let y = [p[0], p[1] + 2, -p[2]]
            let z = [-p[3], p[4], p[5] + 1]
            let weights = [p[6], p[7], p[0] + 1]
            let total = weights.reduce(0, +)
            let meanY = zip(y, weights).reduce(0) { $0 + $1.0 * $1.1 } / total
            let meanZ = zip(z, weights).reduce(0) { $0 + $1.0 * $1.1 } / total
            let covariance = (0..<3).reduce(0.0) { $0 + weights[$1] * (y[$1] - meanY) * (z[$1] - meanZ) } / total
            let varianceZ = zip(z, weights).reduce(0) { $0 + $1.1 * pow($1.0 - meanZ, 2) } / total
            return ProbabilityInstance(#"""
            The pair $(Y,Z)$ takes the three respective values
            $$Y=\#(ProbabilityMath.vector(y)),\quad Z=\#(ProbabilityMath.vector(z)),$$
            with probabilities $\#(ProbabilityMath.fractions(weights, denominator: total))$. The exact $\mathbb{E}[Z]$ is available.
            A control variate uses $Y-c(Z-\mathbb{E}[Z])$ to estimate $\mathbb{E}[Y]$ from IID pairs.
            Find the real coefficient $c$ minimizing this estimator's variance, with this subtraction sign convention.
            """#, covariance / varianceZ)
        default:
            let correlation = (p[0] - 5) / 5
            let n = 100 + 10 * p[1]
            let innovationVariance = p[2] + 1
            return ProbabilityInstance(#"""
            A stationary Gaussian AR(1) process satisfies $X_t=\rho X_{t-1}+\varepsilon_t$, where $\rho=\#(ProbabilityMath.number(correlation))$.
            The innovations $\varepsilon_t$ are IID $\mathcal{N}(0,\#(ProbabilityMath.number(innovationVariance)))$ and independent of the past; the second parameter is variance.
            For $n=\#(ProbabilityMath.number(n))$ consecutive observations, find the asymptotic effective sample size for estimating the stationary mean,
            defined as $n$ divided by $1+2\sum_{k=1}^{\infty}\operatorname{Corr}(X_0,X_k)$. Use the infinite autocorrelation sum, not a finite-sample correction.
            Do not cap the asymptotic effective sample size at $n$ when correlations are negative.
            """#, n * (1 - correlation) / (1 + correlation))
        }
    }
}
