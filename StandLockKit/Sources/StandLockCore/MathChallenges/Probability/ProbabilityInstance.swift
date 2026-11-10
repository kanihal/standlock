struct ProbabilityInstance {
    let prompt: String
    let answer: Double
    let answerKind: MathAnswer.Kind

    init(_ prompt: String, _ answer: Double, kind: MathAnswer.Kind = .real) {
        self.prompt = prompt
        self.answer = answer
        self.answerKind = kind
    }
}
