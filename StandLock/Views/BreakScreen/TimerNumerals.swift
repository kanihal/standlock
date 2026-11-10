import SwiftUI

struct TimerNumerals: View {
    let remainingSeconds: TimeInterval
    let palette: BreakPalette

    private var timeString: String {
        let seconds = max(0, Int(remainingSeconds))
        return String(format: "%02d:%02d", seconds / 60, seconds % 60)
    }

    var body: some View {
        Text(timeString)
            .font(.system(size: 14, weight: .regular, design: .monospaced))
            .monospacedDigit()
            .foregroundStyle(palette.inkSoft)
            .contentTransition(.identity)
            .transaction { $0.animation = nil }
            .accessibilityLabel(Text("Break time remaining"))
            .accessibilityValue(timeString)
    }
}
