import Foundation

/// Euclidean and SPD-metric projections; simplex thresholds use sorted active sets.
/// Provenance: Parikh & Boyd, Proximal Algorithms, §§6.2, 6.5.
/// https://web.stanford.edu/~boyd/papers/pdf/prox_algs.pdf
/// Boyd & Vandenberghe, Convex Optimization, §8.1.
/// https://web.stanford.edu/~boyd/cvxbook/bv_cvxbook.pdf
enum OptimizationProjectionQuestions {
    static func instance(_ variant: Int, _ p: MathParameters) -> OptimizationInstance {
        if variant == 0 {
            let v = [p[0] / 2, p[1] / 3, -p[2] / 4, p[3] / 5]
            let mass = (p[4] + p[5]) / 4
            let sorted = v.sorted(by: >)
            var sum = 0.0
            var threshold = 0.0
            for i in 0..<4 {
                sum += sorted[i]
                let candidate = (sum - mass) / Double(i + 1)
                if sorted[i] > candidate { threshold = candidate }
            }
            let coordinate = Int(p[6] + p[7]) % 4
            return OptimizationInstance(#"Let $C=\{x\in\mathbb{R}^{4}:x_i\ge0,\ \sum_{i=1}^{4}x_i=s\}$, with $s=\#(OptimizationMath.number(mass))$ and $v=\#(OptimizationMath.vector(v))$. Find coordinate \#(coordinate + 1) (coordinates are numbered 1 through 4) of the Euclidean projection $\argmin_{x\in C}\frac{1}{2}\|x-v\|_{2}^{2}$."#, max(0, v[coordinate] - threshold))
        }
        let h = [[p[0] + 2, 1], [1, p[1] + 2]]
        if variant == 1 {
            let v = [p[2] / 2, -p[3] / 3]
            let a = [p[4] / 3, p[5] / 4]
            let b = (p[6] - p[7]) / 2
            let distance = abs(OptimizationMath.dot(a, v) - b) / sqrt(OptimizationMath.dot(a, OptimizationMath.solve2(h, a)))
            return OptimizationInstance(#"Use the norm $\|z\|_H=\sqrt{z^{\mathrm{T}}Hz}$, with $H=\#(OptimizationMath.matrix(h))$. For $v=\#(OptimizationMath.vector(v))$, find the metric distance $\min_{a^{\mathrm{T}}x=b}\|x-v\|_H$ to the hyperplane with $a=\#(OptimizationMath.vector(a))$ and $b=\#(OptimizationMath.number(b))$. Report distance, not its square."#, distance)
        }
        if variant == 2 {
            let v = [p[0] - p[1], p[2] / 2, -p[3] / 3]
            let c = [p[4] / 4, -p[5] / 5, p[6] / 6]
            let radius = p[7] / 3
            let offset = zip(v, c).map(-)
            return OptimizationInstance(#"Let $B=\{x\in\mathbb{R}^{3}:\|x-c\|_{2}\le r\}$, with $c=\#(OptimizationMath.vector(c))$, $r=\#(OptimizationMath.number(radius))$, and $v=\#(OptimizationMath.vector(v))$. Find $\|v-\Pi_B(v)\|_{2}$, the Euclidean distance from $v$ to its ball projection."#, max(0, OptimizationMath.norm(offset) - radius))
        }
        let upper = [p[4] / 2, p[5] / 3]
        let v = [p[2] - p[6] / 3, p[3] - p[7] / 4]
        let q = OptimizationMath.multiply(h, v).map { -$0 }
        let projection = OptimizationMath.boxMinimum(h, q, upper)
        let offset = zip(projection, v).map(-)
        return OptimizationInstance(#"For $H=\#(OptimizationMath.matrix(h))$, $v=\#(OptimizationMath.vector(v))$, and $U=\#(OptimizationMath.vector(upper))$, find the optimal objective value $$\min_{0\le x\le U}\frac{1}{2}(x-v)^{\mathrm{T}}H(x-v),\qquad x\in\mathbb{R}^{2},$$ with componentwise bounds."#, 0.5 * OptimizationMath.dot(offset, OptimizationMath.multiply(h, offset)))
    }
}
