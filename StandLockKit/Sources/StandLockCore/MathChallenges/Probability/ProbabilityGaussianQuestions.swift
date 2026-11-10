import Foundation

// Gaussian conditioning and density: Murphy, Conjugate Bayesian analysis of the Gaussian distribution.
// https://www.cs.ubc.ca/~murphyk/Papers/bayesGauss.pdf
// KL direction and expectation definition:
// https://web.stanford.edu/class/stats200/Lecture16.pdf
// Construction: Σ = [[a + c², c], [c, b]], a,b ≥ 2, so det Σ = ab+c²(b−1) > 0.
enum ProbabilityGaussianQuestions {
    static let titles = [
        "Conditional Gaussian mean", "Conditional Gaussian variance",
        "Multivariate Gaussian log density", "Gaussian KL divergence"
    ]

    static func instance(_ variant: Int, _ p: MathParameters) -> ProbabilityInstance {
        let a = p[0] + 1
        let b = p[1] + 1
        let c = (p[2] - 5) / 2
        let s11 = a + c * c
        let determinant = s11 * b - c * c
        let mean = [p[3] - 5, p[4] - 5]
        let observation = [p[5] - 5, p[6] - 5]
        let covariance = ProbabilityMath.matrix([[s11, c], [c, b]])
        let given = #"""
        $(X_1,X_2)$ is jointly Gaussian with mean $\mu = \#(ProbabilityMath.vector(mean))$ and covariance matrix
        $$\Sigma = \#(covariance).$$
        The entries of $\Sigma$ are covariances, not standard deviations.
        """#
        switch variant {
        case 0:
            let answer = mean[0] + c / b * (observation[1] - mean[1])
            return ProbabilityInstance(#"""
            \#(given)
            Find $\mathbb{E}[X_1 \mid X_2 = \#(ProbabilityMath.number(observation[1]))]$.
            """#, answer)
        case 1:
            return ProbabilityInstance(#"""
            \#(given)
            Find the conditional variance $\operatorname{Var}(X_1 \mid X_2 = \#(ProbabilityMath.number(observation[1])))$.
            """#, s11 - c * c / b)
        case 2:
            let d1 = observation[0] - mean[0]
            let d2 = observation[1] - mean[1]
            let quadratic = (b * d1 * d1 - 2 * c * d1 * d2 + s11 * d2 * d2) / determinant
            let answer = -log(2 * Double.pi) - 0.5 * log(determinant) - 0.5 * quadratic
            return ProbabilityInstance(#"""
            \#(given)
            Find the natural log of the joint density $f(x)$ at $x = \#(ProbabilityMath.vector(observation))$.
            """#, answer)
        default:
            let u = p[5] + 1
            let v = p[6] + 1
            let z = (p[7] - 5) / 3
            let q11 = u + z * z
            let qDeterminant = q11 * v - z * z
            let qMean = [-mean[1], mean[0] + 1]
            let d1 = qMean[0] - mean[0]
            let d2 = qMean[1] - mean[1]
            let trace = (v * s11 + q11 * b - 2 * z * c) / qDeterminant
            let quadratic = (v * d1 * d1 - 2 * z * d1 * d2 + q11 * d2 * d2) / qDeterminant
            let answer = 0.5 * (trace + quadratic - 2 + log(qDeterminant / determinant))
            return ProbabilityInstance(#"""
            $P$ is the bivariate Gaussian with mean $\#(ProbabilityMath.vector(mean))$ and covariance
            $$\#(covariance).$$
            $Q$ is the bivariate Gaussian with mean $\#(ProbabilityMath.vector(qMean))$ and covariance
            $$\#(ProbabilityMath.matrix([[q11, z], [z, v]])).$$
            Find $\operatorname{KL}(P \Vert Q) = \mathbb{E}_P[\log(f_P(X)/f_Q(X))]$, using natural logarithms.
            """#, answer)
        }
    }
}
