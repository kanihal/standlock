import Foundation

// Transition powers, invariant distributions and geometric covariance decay:
// https://www.stat.cmu.edu/~cshalizi/dst/18/lectures/20/lecture-20.html
// https://www.cs.cmu.edu/~odonnell/papers/probability-and-computing-lecture-notes.pdf
// All nonabsorbing transition probabilities are strictly interior; |1−a−b| < 1.
enum ProbabilityMarkovQuestions {
    static let titles = [
        "Markov stationary probability", "Markov expected hitting time",
        "Markov multistep transition", "Markov sample mean asymptotic variance"
    ]

    static func instance(_ variant: Int, _ p: MathParameters) -> ProbabilityInstance {
        let a = p[0] / (p[0] + p[1] + 2)
        let b = p[2] / (p[2] + p[3] + 2)
        let matrix = ProbabilityMath.matrix([[1 - a, a], [b, 1 - b]])
        let given = #"""
        A time-homogeneous Markov chain has states $\{0,1\}$ and row transition matrix
        $$P = \#(matrix).$$
        $P_{ij}=\mathbb{P}(X_{t+1}=j\mid X_t=i)$; rows and columns are in state order $0,1$.
        """#
        switch variant {
        case 0:
            return ProbabilityInstance(#"""
            \#(given)
            Find $\pi_1$, the probability of state $1$ in the unique stationary distribution.
            """#, a / (a + b))
        case 1:
            let denominator = p[2] + p[3] + p[4] + 2
            let back = p[2] / denominator
            let onward = p[3] / denominator
            let absorbing = ProbabilityMath.matrix([
                [1 - a, a, 0], [back, 1 - back - onward, onward], [0, 0, 1]
            ])
            return ProbabilityInstance(#"""
            A Markov chain has states $\{0,1,2\}$ and row transition matrix
            $$P = \#(absorbing).$$
            Rows and columns are in state order $0,1,2$. Start at $X_0=0$.
            For $\tau = \min\{t\ge 0:X_t=2\}$, find $\mathbb{E}[\tau]$, measured in transitions.
            """#, (a + back + onward) / (a * onward))
        case 2:
            let steps = p[4] + 2
            let answer = a / (a + b) * (1 - pow(1 - a - b, steps))
            return ProbabilityInstance(#"""
            \#(given)
            Starting at $X_0=0$, find $\mathbb{P}(X_k=1)$ for $k = \#(ProbabilityMath.number(steps))$ transitions.
            """#, answer)
        default:
            let stationary = a / (a + b)
            let correlation = 1 - a - b
            let answer = stationary * (1 - stationary) * (1 + correlation) / (1 - correlation)
            return ProbabilityInstance(#"""
            \#(given)
            Start the chain in stationarity, and let $M_n = \frac{1}{n}\sum_{t=1}^{n}\mathbf{1}(X_t=1)$.
            Find the asymptotic variance coefficient $\lim_{n\to\infty}n\operatorname{Var}(M_n)$.
            """#, answer)
        }
    }
}
