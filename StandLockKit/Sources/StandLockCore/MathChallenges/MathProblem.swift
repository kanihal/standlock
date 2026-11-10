import Foundation

public struct MathProblem: Codable, Equatable, Sendable, Identifiable {
    public let id: UUID
    public let templateID: String
    public let topic: MathTopic
    public let title: String
    public let parameters: MathParameters
    public let prompt: String
    public let answer: Double
    public let answerKind: MathAnswer.Kind

    public init(
        id: UUID = UUID(), templateID: String, topic: MathTopic, title: String,
        parameters: MathParameters, prompt: String, answer: Double,
        answerKind: MathAnswer.Kind = .real
    ) {
        self.id = id
        self.templateID = templateID
        self.topic = topic
        self.title = title
        self.parameters = parameters
        self.prompt = prompt
        self.answer = answer
        self.answerKind = answerKind
    }

    public var signature: String { templateID + ":" + parameters.values.map(String.init).joined(separator: ",") }

    public var isValid: Bool {
        parameters.isValid && answer.isFinite && !prompt.isEmpty && !title.isEmpty
            && (answerKind != .integer || answer.rounded() == answer)
    }
}
