import Foundation

// Posterior loss, Bayes actions, and randomized minimax decision rules:
// https://www.stat.berkeley.edu/~wfithian/courses/stat210a/models.html
// https://scholar.harvard.edu/files/kasy/files/decisiontheory_0.pdf
// Asymmetric-loss costs put the target quantile strictly inside a posterior jump.
// EVSI uses exact integer joint-mass numerators to avoid cancellation below zero.
enum ProbabilityDecisionQuestions {
    static let titles = [
        "Posterior quadratic risk", "Bayes action under asymmetric absolute loss",
        "Randomized minimax risk", "Expected value of sample information"
    ]

    static func instance(_ variant: Int, _ p: MathParameters) -> ProbabilityInstance {
        switch variant {
        case 0:
            let values = [-p[0], p[1], p[2] + 10]
            let weights = [p[3], p[4], p[5]]
            let total = weights.reduce(0, +)
            let action = p[6] - 5
            let risk = zip(values, weights).reduce(0) { $0 + $1.1 * pow(action - $1.0, 2) } / total
            return ProbabilityInstance(#"""
            Given the observed data, $\theta$ takes values $\#(ProbabilityMath.vector(values))$ with respective posterior probabilities $\#(ProbabilityMath.fractions(weights, denominator: total))$.
            For loss $L(a,\theta)=(a-\theta)^2$, find the posterior expected loss of the fixed action $a=\#(ProbabilityMath.number(action))$.
            """#, risk)
        case 1:
            let values = [-p[0], p[1], p[2] + 10]
            let weights = [p[3], p[4], p[5]]
            let total = weights.reduce(0, +)
            let index = (p.values[6] + p.values[7]) % 3
            let underCost = 2 * weights.prefix(index).reduce(0, +) + weights[index]
            let overCost = 2 * total - underCost
            return ProbabilityInstance(#"""
            $\theta$ has a finite prior on values $\#(ProbabilityMath.vector(values))$ with respective probabilities $\#(ProbabilityMath.fractions(weights, denominator: total))$.
            Choose a real action $a$ to minimize prior expected loss, where
            $$L(a,\theta)=\#(ProbabilityMath.number(overCost))\max(a-\theta,0)+\#(ProbabilityMath.number(underCost))\max(\theta-a,0).$$
            Find the unique Bayes action $a$.
            """#, values[index], kind: .integer)
        case 2:
            let a = p[0] + 1
            let b = p[1] + 1
            let base = p[2]
            return ProbabilityInstance(#"""
            A decision problem has actions $A,B$ and states $\theta_1,\theta_2$. The loss matrix has rows $A,B$ and columns $\theta_1,\theta_2$:
            $$\#(ProbabilityMath.matrix([[base, base + a], [base + b, base]])).$$
            Choose $A$ with probability $q$ and $B$ with probability $1-q$, with $0\le q\le 1$; this randomization is independent of the state.
            Nature chooses a state knowing $q$, before the random action is realized. There is no observation and no prior.
            Find $\min_{0\le q\le 1}\max_{j\in\{1,2\}}\mathbb{E}[L(\mathrm{action},\theta_j)]$, the randomized minimax expected loss.
            """#, base + a * b / (a + b))
        default:
            let priorTotal = p[0] + p[1]
            let overCost = p[2] + 1
            let underCost = p[3] + 1
            let sensitivityTotal = p[4] + p[5]
            let falsePositiveTotal = p[6] + p[7]
            let beforeNumerator = min(overCost * p[1], underCost * p[0]) * sensitivityTotal * falsePositiveTotal
            let positiveNumerator = min(overCost * p[1] * p[6] * sensitivityTotal,
                                        underCost * p[0] * p[4] * falsePositiveTotal)
            let negativeNumerator = min(overCost * p[1] * p[7] * sensitivityTotal,
                                        underCost * p[0] * p[5] * falsePositiveTotal)
            let answer = (beforeNumerator - positiveNumerator - negativeNumerator)
                / (priorTotal * sensitivityTotal * falsePositiveTotal)
            return ProbabilityInstance(#"""
            $\theta\in\{0,1\}$, with prior $\mathbb{P}(\theta=1)=\#(MathLatex.fraction(p[0], priorTotal))$. Actions are $a\in\{0,1\}$.
            Loss is zero for a correct action, $\#(ProbabilityMath.number(overCost))$ for $(a,\theta)=(1,0)$, and $\#(ProbabilityMath.number(underCost))$ for $(a,\theta)=(0,1)$.
            A binary experiment $X$ has $\mathbb{P}(X=1\mid\theta=1)=\#(MathLatex.fraction(p[4], sensitivityTotal))$
            and $\mathbb{P}(X=1\mid\theta=0)=\#(MathLatex.fraction(p[6], falsePositiveTotal))$.
            Find the expected value of sample information: the minimum prior expected loss without $X$,
            minus the expected minimum posterior loss after observing $X$. The experiment has no cost.
            """#, answer)
        }
    }
}
