import Foundation

public enum MathProblemCatalog {
    public struct Template: Identifiable, Sendable {
        public let topic: MathTopic
        public let index: Int
        public let title: String
        public var id: String { topic.prefix + String(format: "%02d", index) }
    }

    public static var templates: [Template] {
        let banks: [(MathTopic, [String])] = [
            (.linearAlgebra, LinearAlgebraQuestionBank.titles),
            (.optimization, OptimizationQuestionBank.titles),
            (.probability, ProbabilityQuestionBank.titles)
        ]
        return banks.flatMap { topic, titles in
            titles.enumerated().map { Template(topic: topic, index: $0.offset + 1, title: $0.element) }
        }
    }

    public static func problem(topic: MathTopic, index: Int, parameters: MathParameters) -> MathProblem {
        switch topic {
        case .linearAlgebra: LinearAlgebraQuestionBank.problem(index: index, parameters: parameters)
        case .optimization: OptimizationQuestionBank.problem(index: index, parameters: parameters)
        case .probability: ProbabilityQuestionBank.problem(index: index, parameters: parameters)
        }
    }

    public static func draw<R: RandomNumberGenerator>(deck: inout MathQuestionDeck, using random: inout R) -> MathProblem {
        let (topic, index) = deck.draw(using: &random)
        return problem(topic: topic, index: index, parameters: MathParameters(using: &random))
    }
}
