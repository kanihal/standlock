import Foundation

public enum MathTopic: String, Codable, CaseIterable, Sendable {
    case linearAlgebra, optimization, probability

    public var title: String {
        switch self {
        case .linearAlgebra: "Linear Algebra"
        case .optimization: "Optimization"
        case .probability: "Probability & Statistics"
        }
    }

    public var prefix: String {
        switch self {
        case .linearAlgebra: "LA"
        case .optimization: "OPT"
        case .probability: "PS"
        }
    }
}
