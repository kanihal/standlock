import Foundation

/// Exact source notation for the fixed, locally generated question bank. Delimiters are
/// supplied by the prompt, so matrices can participate in a complete LaTeX equation.
public enum MathLatex {
    public static func number(_ value: Double) -> String {
        let text = String(format: "%.17g", locale: Locale(identifier: "en_US_POSIX"), value)
        let pieces = text.split(separator: "e")
        guard pieces.count == 2, let power = Int(pieces[1]) else { return text }
        return "\(pieces[0])\\times 10^{\(power)}"
    }

    public static func matrix(_ rows: [[Double]]) -> String {
        "\\begin{bmatrix}" + rows.map { $0.map(number).joined(separator: " & ") }
            .joined(separator: " \\\\ ") + "\\end{bmatrix}"
    }

    public static func vector(_ values: [Double], column: Bool = false) -> String {
        matrix(column ? values.map { [$0] } : [values])
    }

    public static func fraction(_ numerator: Double, _ denominator: Double) -> String {
        "\\frac{\(number(numerator))}{\(number(denominator))}"
    }
}
