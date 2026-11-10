import Foundation

/// A bounded, reproducible parameterization. Every bank constructs valid instances from
/// eight integers in 1...9; random selection therefore needs no unbounded retry loop.
public struct MathParameters: Codable, Equatable, Sendable {
    public let values: [Int]

    public init(_ values: [Int]) {
        precondition(values.count == 8 && values.allSatisfy { (1...9).contains($0) })
        self.values = values
    }

    public init<R: RandomNumberGenerator>(using random: inout R) {
        values = (0..<8).map { _ in Int.random(in: 1...9, using: &random) }
    }

    public subscript(_ index: Int) -> Double { Double(values[index]) }

    public var isValid: Bool { values.count == 8 && values.allSatisfy { (1...9).contains($0) } }
}
