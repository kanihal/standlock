import Foundation

// Fisher information and the transformed-parameter Cramér–Rao bound:
// https://web.stanford.edu/class/stats200/Lecture15.pdf
// Gaussian MLE and likelihood-ratio conventions:
// https://web.stanford.edu/class/stats200/Lecture13.pdf
// https://web.stanford.edu/class/stats200/Lecture22.pdf
// Positive variances, rates and centered SSE avoid all boundary likelihood cases.
enum ProbabilityInformationQuestions {
    static let titles = [
        "Fisher information under reparameterization", "Cramér–Rao bound for a transformed parameter",
        "Gaussian variance maximum likelihood", "Poisson likelihood ratio statistic"
    ]

    static func instance(_ variant: Int, _ p: MathParameters) -> ProbabilityInstance {
        switch variant {
        case 0:
            let variance = p[0] + 1
            let n = p[1] + 2
            let theta = (p[2] - 5) / 4
            return ProbabilityInstance(#"""
            $X_1,\ldots,X_n$ are IID $\mathcal{N}(e^{\theta},\sigma^2)$. The unknown parameter is $\theta\in\mathbb{R}$; $\sigma^2$ is known.
            $n=\#(ProbabilityMath.number(n))$, $\sigma^2=\#(ProbabilityMath.number(variance))$ (variance, not standard deviation).
            Find the expected Fisher information $I_n(\theta)$ in the entire sample, evaluated at $\theta=\#(ProbabilityMath.number(theta))$.
            """#, n * exp(2 * theta) / variance)
        case 1:
            let n = p[0] + 2
            let rate = (p[1] + 1) / 3
            return ProbabilityInstance(#"""
            $X_1,\ldots,X_n$ are IID $\operatorname{Exponential}(\mathrm{rate}\ \lambda)$, with density $\lambda\exp(-\lambda x)$ for $x>0$ and $\lambda>0$.
            $n=\#(ProbabilityMath.number(n))$. An estimator $T$ is unbiased for $g(\lambda)=\frac{1}{\lambda}$ for every $\lambda>0$.
            Find the Cramér–Rao lower bound on $\operatorname{Var}_{\lambda}(T)$, evaluated at $\lambda=\#(ProbabilityMath.number(rate))$.
            """#, 1 / (n * rate * rate))
        case 2:
            let n = p[0] + 3
            let sampleMean = p[1] - 5
            let centeredSSE = p[2] + p[3] + 1
            return ProbabilityInstance(#"""
            $X_1,\ldots,X_n$ are IID $\mathcal{N}(\mu,v)$, with both $\mu\in\mathbb{R}$ and variance $v>0$ unknown.
            $n=\#(ProbabilityMath.number(n))$, $\bar{x}=\#(ProbabilityMath.number(sampleMean))$, and $\sum_{i=1}^{n}(x_i-\bar{x})^2=\#(ProbabilityMath.number(centeredSSE))$.
            Find the maximum likelihood estimate of $v$ when $\mu$ is estimated jointly from these data.
            """#, centeredSSE / n)
        default:
            let n = p[0] + 2
            let total = p[1] + p[2] + 1
            let nullRate = (p[3] + 1) / 2
            let answer = 2 * (total * log(total / (n * nullRate)) - total + n * nullRate)
            return ProbabilityInstance(#"""
            $X_1,\ldots,X_n$ are IID $\operatorname{Poisson}(\lambda)$, with $n=\#(ProbabilityMath.number(n))$ and observed total $\sum_{i=1}^{n}x_i=\#(ProbabilityMath.number(total))$.
            Test $H_0:\lambda=\#(ProbabilityMath.number(nullRate))$ against an unrestricted positive rate $\lambda>0$.
            Define $\Lambda=\frac{L(\lambda_0)}{\sup_{\lambda>0}L(\lambda)}$. Find $-2\log\Lambda$, using natural logarithms.
            """#, answer)
        }
    }
}
