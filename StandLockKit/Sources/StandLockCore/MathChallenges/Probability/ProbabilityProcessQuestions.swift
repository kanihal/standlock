import Foundation

// Poisson conditioning, compound processes, Gaussian conditioning and OU processes:
// https://adembo.su.domains/math-136/nnotes.pdf (Amir Dembo, Stochastic Processes).
// Positive horizons, positive diffusion and strict interior bridge times are constructive.
enum ProbabilityProcessQuestions {
    static let titles = [
        "Conditional Poisson count", "Compound Poisson variance",
        "Brownian bridge variance", "Ornstein–Uhlenbeck transition variance"
    ]

    static func instance(_ variant: Int, _ p: MathParameters) -> ProbabilityInstance {
        switch variant {
        case 0:
            let rate = p[0] + 1
            let totalCount = p[1] + p[2] + 2
            let count = p[1]
            let time = p[3] + 1
            let horizon = p[3] + p[4] + 2
            let probability = time / horizon
            let logMass = lgamma(totalCount + 1) - lgamma(count + 1) - lgamma(totalCount - count + 1)
                + count * log(probability) + (totalCount - count) * log1p(-probability)
            return ProbabilityInstance(#"""
            $N(t)$ is a homogeneous Poisson process with rate $\lambda=\#(ProbabilityMath.number(rate))$ per unit time and $N(0)=0$.
            Given $N(\#(ProbabilityMath.number(horizon)))=\#(ProbabilityMath.number(totalCount))$, find
            $$\mathbb{P}\left(N(\#(ProbabilityMath.number(time)))=\#(ProbabilityMath.number(count))\mid N(\#(ProbabilityMath.number(horizon)))=\#(ProbabilityMath.number(totalCount))\right).$$
            """#, exp(logMass))
        case 1:
            let rate = p[0]
            let time = (p[1] + 1) / 2
            let low = -p[2]
            let high = p[3] + 1
            let probability = p[4] / (p[4] + p[5])
            let secondMoment = probability * low * low + (1 - probability) * high * high
            return ProbabilityInstance(#"""
            $N(t)$ is a Poisson process of rate $\#(ProbabilityMath.number(rate))$. Independent IID jumps $J_i$ are also independent of $N$:
            $$\mathbb{P}(J_i=\#(ProbabilityMath.number(low)))=\#(ProbabilityMath.number(probability)),\quad\mathbb{P}(J_i=\#(ProbabilityMath.number(high)))=\#(ProbabilityMath.number(1 - probability)).$$
            Define $S(t)=\sum_{i=1}^{N(t)}J_i$ (the empty sum is zero).
            Find $\operatorname{Var}(S(\#(ProbabilityMath.number(time))))$, the variance of the compound count at this time.
            """#, rate * time * secondMoment)
        case 2:
            let varianceRate = p[0] + 1
            let endpoint = p[1] - 5
            let time = p[2] + 1
            let horizon = p[2] + p[3] + 2
            return ProbabilityInstance(#"""
            $B(t)$ is a zero-mean Brownian motion with $B(0)=0$ and $\operatorname{Cov}(B(s),B(t))=\sigma^2\min(s,t)$,
            where the variance rate is $\sigma^2 = \#(ProbabilityMath.number(varianceRate))$. Condition on $B(\#(ProbabilityMath.number(horizon)))=\#(ProbabilityMath.number(endpoint))$.
            Find the Brownian bridge variance
            $$\operatorname{Var}\left(B(\#(ProbabilityMath.number(time)))\mid B(\#(ProbabilityMath.number(horizon)))=\#(ProbabilityMath.number(endpoint))\right).$$
            """#, varianceRate * time * (horizon - time) / horizon)
        default:
            let theta = (p[0] + 1) / 4
            let mean = p[1] - 5
            let sigma = p[2] + 1
            let time = (p[3] + 1) / 5
            let initial = p[4] - 5
            let answer = sigma * sigma / (2 * theta) * -expm1(-2 * theta * time)
            return ProbabilityInstance(#"""
            The Ornstein–Uhlenbeck process satisfies $dX_t=-\theta(X_t-\mu)\,dt+\sigma\,dW_t$, with standard Brownian motion $W$.
            $\theta=\#(ProbabilityMath.number(theta))$, $\mu=\#(ProbabilityMath.number(mean))$, and diffusion coefficient $\sigma=\#(ProbabilityMath.number(sigma))$ (not $\sigma^2$).
            $X_0=\#(ProbabilityMath.number(initial))$ is known exactly. Find $\operatorname{Var}(X_t\mid X_0)$ at $t=\#(ProbabilityMath.number(time))$.
            """#, answer)
        }
    }
}
