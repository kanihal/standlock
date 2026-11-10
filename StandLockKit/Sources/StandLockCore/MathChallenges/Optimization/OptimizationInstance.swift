struct OptimizationInstance {
    let prompt: String
    let answer: Double
    let kind: MathAnswer.Kind

    init(_ prompt: String, _ answer: Double, kind: MathAnswer.Kind = .real) {
        self.prompt = prompt
        self.answer = answer
        self.kind = kind
    }
}
