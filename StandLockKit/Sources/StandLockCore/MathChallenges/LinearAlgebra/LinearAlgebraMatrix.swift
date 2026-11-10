import Foundation

/// Tiny dense matrices used only by the bounded linear-algebra constructions.
struct LinearAlgebraMatrix {
    let rows: [[Double]]

    init(_ rows: [[Double]]) { self.rows = rows }

    subscript(_ i: Int, _ j: Int) -> Double { rows[i][j] }
    var rowCount: Int { rows.count }
    var columnCount: Int { rows[0].count }
    var trace: Double { (0..<rowCount).reduce(0) { $0 + self[$1, $1] } }
    var frobeniusSquared: Double { rows.flatMap { $0 }.reduce(0) { $0 + $1 * $1 } }
    var transposed: Self {
        Self((0..<columnCount).map { j in (0..<rowCount).map { self[$0, j] } })
    }
    var text: String { MathLatex.matrix(rows) }

    static func number(_ value: Double) -> String {
        MathLatex.number(value)
    }

    static func vectorText(_ values: [Double]) -> String {
        MathLatex.vector(values, column: true)
    }

    static func dot(_ a: [Double], _ b: [Double]) -> Double {
        zip(a, b).reduce(0) { $0 + $1.0 * $1.1 }
    }

    static func diagonal(_ values: [Double]) -> Self {
        Self(values.indices.map { i in values.indices.map { i == $0 ? values[i] : 0 } })
    }

    static func identity(_ count: Int) -> Self { diagonal(Array(repeating: 1, count: count)) }

    static func outer(_ a: [Double], _ b: [Double]) -> Self {
        Self(a.map { x in b.map { x * $0 } })
    }

    static func + (lhs: Self, rhs: Self) -> Self {
        Self((0..<lhs.rowCount).map { i in
            (0..<lhs.columnCount).map { lhs[i, $0] + rhs[i, $0] }
        })
    }

    static func - (lhs: Self, rhs: Self) -> Self { lhs + rhs.scaled(-1) }

    static func * (lhs: Self, rhs: Self) -> Self {
        Self((0..<lhs.rowCount).map { i in
            (0..<rhs.columnCount).map { j in
                (0..<lhs.columnCount).reduce(0) { $0 + lhs[i, $1] * rhs[$1, j] }
            }
        })
    }

    func scaled(_ scalar: Double) -> Self { Self(rows.map { $0.map { scalar * $0 } }) }

    func applied(to vector: [Double]) -> [Double] {
        rows.map { Self.dot($0, vector) }
    }

    func quadratic(_ vector: [Double]) -> Double { Self.dot(vector, applied(to: vector)) }

    /// Partial-pivoted elimination. All callers construct nonsingular matrices.
    func solving(_ rightHandSide: [Double]) -> [Double] {
        let n = rowCount
        var augmented = rows.enumerated().map { $0.element + [rightHandSide[$0.offset]] }
        for k in 0..<n {
            let pivot = (k..<n).max { abs(augmented[$0][k]) < abs(augmented[$1][k]) }!
            augmented.swapAt(k, pivot)
            let divisor = augmented[k][k]
            for j in k...n { augmented[k][j] /= divisor }
            for i in 0..<n where i != k {
                let factor = augmented[i][k]
                for j in k...n { augmented[i][j] -= factor * augmented[k][j] }
            }
        }
        return augmented.map { $0[n] }
    }

    var inverse: Self {
        let columns = (0..<rowCount).map { i in
            solving((0..<rowCount).map { $0 == i ? 1 : 0 })
        }
        return Self(columns).transposed
    }

    var determinant: Double {
        var a = rows
        var result = 1.0
        for k in 0..<rowCount {
            let pivot = (k..<rowCount).max { abs(a[$0][k]) < abs(a[$1][k]) }!
            if pivot != k { a.swapAt(k, pivot); result = -result }
            let diagonal = a[k][k]
            result *= diagonal
            if k + 1 < rowCount {
                for i in (k + 1)..<rowCount {
                    let factor = a[i][k] / diagonal
                    for j in (k + 1)..<rowCount { a[i][j] -= factor * a[k][j] }
                }
            }
        }
        return result
    }

    var symmetricEigenvalues2: (minimum: Double, maximum: Double) {
        let center = (self[0, 0] + self[1, 1]) / 2
        let radius = hypot((self[0, 0] - self[1, 1]) / 2, self[0, 1])
        return (center - radius, center + radius)
    }

    var spectralNorm2: Double { sqrt((transposed * self).symmetricEigenvalues2.maximum) }
}
