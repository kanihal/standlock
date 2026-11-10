import Foundation

/// Tiny fixed-dimensional operations used by the optimization families.
enum OptimizationMath {
    static func number(_ x: Double) -> String { MathLatex.number(x) }

    static func vector(_ v: [Double]) -> String { MathLatex.vector(v, column: true) }

    static func matrix(_ rows: [[Double]]) -> String { MathLatex.matrix(rows) }

    static func diagonal(_ values: [Double]) -> String {
        MathLatex.matrix(values.indices.map { i in
            values.indices.map { j in i == j ? values[i] : 0 }
        })
    }

    static func dot(_ a: [Double], _ b: [Double]) -> Double {
        zip(a, b).reduce(0) { $0 + $1.0 * $1.1 }
    }

    static func norm(_ a: [Double]) -> Double { sqrt(dot(a, a)) }

    static func multiply(_ h: [[Double]], _ x: [Double]) -> [Double] {
        h.map { dot($0, x) }
    }

    static func solve2(_ h: [[Double]], _ b: [Double]) -> [Double] {
        let determinant = h[0][0] * h[1][1] - h[0][1] * h[1][0]
        return [(h[1][1] * b[0] - h[0][1] * b[1]) / determinant,
                (h[0][0] * b[1] - h[1][0] * b[0]) / determinant]
    }

    static func objective(_ h: [[Double]], _ q: [Double], _ x: [Double]) -> Double {
        0.5 * dot(x, multiply(h, x)) + dot(q, x)
    }

    /// Enumerates the nine faces of a two-dimensional box. Positive definiteness
    /// makes the best feasible face minimizer the unique global minimizer.
    static func boxMinimum(_ h: [[Double]], _ q: [Double], _ upper: [Double]) -> [Double] {
        var best = [0.0, 0.0]
        var bestValue = objective(h, q, best)
        for first in 0..<3 {
            for second in 0..<3 {
                var x = [first == 2 ? upper[0] : 0, second == 2 ? upper[1] : 0]
                if first == 0 && second == 0 {
                    x = solve2(h, q.map { -$0 })
                } else if first == 0 {
                    x[0] = -(q[0] + h[0][1] * x[1]) / h[0][0]
                } else if second == 0 {
                    x[1] = -(q[1] + h[1][0] * x[0]) / h[1][1]
                }
                if (0...upper[0]).contains(x[0]) && (0...upper[1]).contains(x[1]) {
                    let value = objective(h, q, x)
                    if value < bestValue { best = x; bestValue = value }
                }
            }
        }
        return best
    }
}
