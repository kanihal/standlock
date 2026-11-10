import Foundation

// Conjugate updates and predictive integration:
// https://web.stanford.edu/class/stats200/Lecture20.pdf
// https://www.stat.umn.edu/geyer/f22/5421/notes/prior.html (exponential-family conjugacy).
// Distribution definitions (including shape–rate gamma) are included in each prompt.
enum ProbabilityConjugateQuestions {
    static let titles = [
        "Beta–binomial predictive variance", "Gamma–Poisson predictive mass",
        "Dirichlet–multinomial covariance", "Gamma–exponential predictive survival"
    ]

    static func instance(_ variant: Int, _ p: MathParameters) -> ProbabilityInstance {
        switch variant {
        case 0:
            let a = p[0] + 1
            let b = p[1] + 1
            let successes = p[2]
            let failures = p[3]
            let m = p[4] + 2
            let posteriorA = a + successes
            let posteriorB = b + failures
            let sum = posteriorA + posteriorB
            let answer = m * posteriorA * posteriorB * (sum + m) / (sum * sum * (sum + 1))
            return ProbabilityInstance(#"""
            $\theta \sim \operatorname{Beta}(a,b)$, whose density is proportional to $\theta^{a-1}(1-\theta)^{b-1}$ on $(0,1)$.
            $a = \#(ProbabilityMath.number(a))$, $b = \#(ProbabilityMath.number(b))$. Conditional on $\theta$, all trials are independent $\operatorname{Bernoulli}(\theta)$.
            Observed trials contain $\#(ProbabilityMath.number(successes))$ successes and $\#(ProbabilityMath.number(failures))$ failures.
            Let $Y$ be the number of successes in $\#(ProbabilityMath.number(m))$ additional trials.
            Find the posterior predictive variance $\operatorname{Var}(Y\mid\mathrm{data})$, integrating out $\theta$.
            """#, answer)
        case 1:
            let shape = p[0] + 1
            let rate = p[1] + 1
            let n = p[2] + 1
            let total = p[3] + p[4]
            let exposure = (p[5] + 1) / 3
            let count = p[6]
            let posteriorShape = shape + total
            let posteriorRate = rate + n
            let logMass = lgamma(posteriorShape + count) - lgamma(posteriorShape) - lgamma(count + 1)
                + posteriorShape * log(posteriorRate / (posteriorRate + exposure))
                + count * log(exposure / (posteriorRate + exposure))
            return ProbabilityInstance(#"""
            $\lambda$ has a shape–rate $\operatorname{Gamma}(a,b)$ prior:
            $$f(\lambda)=\frac{b^a\lambda^{a-1}\exp(-b\lambda)}{\Gamma(a)},\quad\lambda>0.$$
            $a = \#(ProbabilityMath.number(shape))$, $b = \#(ProbabilityMath.number(rate))$.
            Given $\lambda$, the $n = \#(ProbabilityMath.number(n))$ observed counts are IID $\operatorname{Poisson}(\lambda)$, each with unit exposure; their total is $\#(ProbabilityMath.number(total))$.
            A new conditionally independent count satisfies $Y\mid\lambda\sim\operatorname{Poisson}(t\lambda)$, with exposure $t = \#(ProbabilityMath.number(exposure))$.
            Find $\mathbb{P}(Y = \#(ProbabilityMath.number(count))\mid\mathrm{data})$.
            """#, exp(logMass))
        case 2:
            let prior = [p[0] + 1, p[1] + 1, p[2] + 1]
            let counts = [p[3], p[4], p[5]]
            let posterior = zip(prior, counts).map(+)
            let sum = posterior.reduce(0, +)
            let m = p[6] + 2
            let answer = -m * posterior[0] * posterior[1] * (sum + m) / (sum * sum * (sum + 1))
            return ProbabilityInstance(#"""
            $(\theta_1,\theta_2,\theta_3)\sim\operatorname{Dirichlet}(\alpha)$, with $\alpha=\#(ProbabilityMath.vector(prior))$; the density on the probability simplex is proportional to $\theta_1^{\alpha_1-1}\theta_2^{\alpha_2-1}\theta_3^{\alpha_3-1}$.
            Observed categorical trials have counts $\#(ProbabilityMath.vector(counts))$. Conditional on $\theta$, trials are independent.
            In $\#(ProbabilityMath.number(m))$ new trials let $Y_1,Y_2,Y_3$ be the category counts.
            Find the posterior predictive covariance $\operatorname{Cov}(Y_1,Y_2\mid\mathrm{data})$, integrating out $\theta$.
            """#, answer)
        default:
            let shape = p[0] + 1
            let rate = p[1] + 1
            let n = p[2] + 1
            let totalTime = p[3] + p[4] + 1
            let t = (p[5] + 1) / 2
            let posteriorShape = shape + n
            let posteriorRate = rate + totalTime
            return ProbabilityInstance(#"""
            $\lambda$ has a shape–rate $\operatorname{Gamma}(a,b)$ prior:
            $$f(\lambda)=\frac{b^a\lambda^{a-1}\exp(-b\lambda)}{\Gamma(a)},\quad\lambda>0.$$
            $a = \#(ProbabilityMath.number(shape))$, $b = \#(ProbabilityMath.number(rate))$.
            Given $\lambda$, the $n = \#(ProbabilityMath.number(n))$ waiting times are IID $\operatorname{Exponential}(\mathrm{rate}\ \lambda)$, with density $\lambda\exp(-\lambda x)$ for $x>0$; their sum is $\#(ProbabilityMath.number(totalTime))$.
            A new waiting time $T$ is conditionally independent with the same rate.
            Find $\mathbb{P}(T>\#(ProbabilityMath.number(t))\mid\mathrm{data})$, integrating out $\lambda$.
            """#, pow(posteriorRate / (posteriorRate + t), posteriorShape))
        }
    }
}
