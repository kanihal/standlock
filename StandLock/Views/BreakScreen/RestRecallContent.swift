import SwiftUI

/// One quiet composition for every discipline mode and the settings preview.
struct RestRecallContent: View {
    let remainingSeconds: TimeInterval
    let palette: BreakPalette

    var body: some View {
        GeometryReader { geometry in
            let size = min(80, max(24, min(geometry.size.width * 0.06, geometry.size.height * 0.12)))
            ZStack {
                palette.paper
                VStack(alignment: .leading, spacing: size * 0.28) {
                    reminder("Rest", size: size) { Image(systemName: "moon.zzz") }
                    reminder("Recall", size: size) { Image(systemName: "brain.head.profile") }
                    reminder("Reorganize", size: size) {
                        ReorganizeActionIcon()
                            .fill()
                            .frame(width: size * 0.75, height: size * 0.75)
                    }
                }
                .foregroundStyle(palette.ink)
                .padding(.horizontal, 32)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                TimerNumerals(remainingSeconds: remainingSeconds, palette: palette)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                    .padding(24)
            }
        }
    }

    private func reminder<Icon: View>(_ title: LocalizedStringKey, size: CGFloat, @ViewBuilder icon: () -> Icon) -> some View {
        HStack(spacing: size * 0.3) {
            icon()
                .font(.system(size: size * 0.65))
                .frame(width: size)
                .accessibilityHidden(true)
            Text(title)
                .font(BreakTypography.exerciseName(size: size))
                .lineLimit(1)
                .minimumScaleFactor(0.5)
        }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isHeader)
    }
}
