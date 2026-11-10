import Foundation

public enum MathAnswer {
    public enum Kind: String, Codable, Sendable { case real, integer }

    public static func parse(_ text: String) -> Double? {
        let parts = text.trimmingCharacters(in: .whitespacesAndNewlines)
            .split(separator: "/", omittingEmptySubsequences: false)
        guard (1...2).contains(parts.count),
              let numerator = Double(parts[0].trimmingCharacters(in: .whitespaces)),
              numerator.isFinite else { return nil }
        if parts.count == 1 { return numerator }
        guard let denominator = Double(parts[1].trimmingCharacters(in: .whitespaces)),
              denominator.isFinite, denominator != 0 else { return nil }
        let value = numerator / denominator
        return value.isFinite ? value : nil
    }

    public static func isCorrect(_ text: String, expected: Double, kind: Kind) -> Bool {
        guard let value = parse(text), expected.isFinite else { return false }
        if kind == .integer { return value == expected && value.rounded() == value }
        return abs(value - expected) <= 1e-6 * max(1, abs(expected))
    }
}
