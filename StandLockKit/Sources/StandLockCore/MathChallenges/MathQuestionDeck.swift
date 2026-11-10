import Foundation

/// Template exposure outlives an attempt; the three-topic bag is reset with its credit.
public struct MathQuestionDeck: Codable, Equatable, Sendable {
    private var remaining: [String: [Int]] = [:]
    private var topics: [MathTopic] = []

    public init() {}

    public mutating func startAttempt() { topics = [] }

    public mutating func draw<R: RandomNumberGenerator>(using random: inout R) -> (MathTopic, Int) {
        if topics.isEmpty { topics = MathTopic.allCases.shuffled(using: &random) }
        let topic = topics.removeLast()
        var indices = remaining[topic.rawValue] ?? []
        if indices.isEmpty { indices = Array(1...40).shuffled(using: &random) }
        let index = indices.removeLast()
        remaining[topic.rawValue] = indices
        return (topic, index)
    }

    public var isValid: Bool {
        Set(topics).count == topics.count && topics.count <= 3
            && remaining.allSatisfy { key, values in
                MathTopic(rawValue: key) != nil && values.count <= 40
                    && Set(values).count == values.count && values.allSatisfy { (1...40).contains($0) }
            }
    }
}
