import SwiftUI

/// One quiet composition for every discipline mode and the settings preview.
struct RestRecallContent: View {
    let remainingSeconds: TimeInterval
    let palette: BreakPalette

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                palette.paper
                Text("Rest & Recall")
                    .font(BreakTypography.exerciseName(size: min(96, max(28, geometry.size.width * 0.075))))
                    .foregroundStyle(palette.ink)
                    .multilineTextAlignment(.center)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                    .padding(.horizontal, 32)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .accessibilityAddTraits(.isHeader)
                TimerNumerals(remainingSeconds: remainingSeconds, palette: palette)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                    .padding(24)
            }
        }
    }
}
