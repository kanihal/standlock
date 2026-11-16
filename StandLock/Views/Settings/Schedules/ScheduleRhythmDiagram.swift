import SwiftUI
import Scheduling
import StandLockCore

/// One repeating cycle, independent of the number of repetitions in the day's preview.
struct ScheduleRhythmDiagram: View {
    let timeline: DayTimeline
    let rhythm: ScheduleRhythm
    @Binding var selection: DayTimeline.Segment?

    @State private var hoveredIndex: Int?
    @State private var pinnedIndex: Int?
    @FocusState private var focusedIndex: Int?
    @EnvironmentObject private var languageStore: LanguageStore
    @Environment(\.locale) private var locale

    private var activeIndex: Int? {
        hoveredIndex ?? focusedIndex ?? pinnedIndex ?? selection.flatMap { segment in
            guard let index = segment.breakIndex, rhythm.breakCount > 0 else { return nil }
            return (index % rhythm.breakCount) * 2 + 1
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: SettingsTokens.cardSpacing) {
            if !rhythm.steps.isEmpty {
                strip
                detail
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Work and break rhythm")
        .onChange(of: rhythm) { _ in hoveredIndex = nil; pinnedIndex = nil; focusedIndex = nil }
        .onChange(of: selection) { value in if value != nil { pinnedIndex = nil; focusedIndex = nil } }
    }

    private var strip: some View {
        GeometryReader { geometry in
            let shortest = rhythm.steps.map(\.duration).filter { $0 > 0 }.min() ?? 1
            let span = max(1, rhythm.duration)
            let scale = max(max(1, geometry.size.width - 2) / span, 8 / shortest)
            let width = span * scale
            ScrollViewReader { proxy in
                ScrollView(.horizontal) {
                    VStack(alignment: .leading, spacing: 7) {
                        LazyHStack(spacing: 0) {
                            ForEach(Array(rhythm.steps.enumerated()), id: \.offset) { index, step in
                                block(step, index: index, width: step.duration * scale)
                                    .id(index)
                            }
                        }
                        .frame(height: 34)
                        repeatArrow.frame(width: width, height: 44)
                    }
                    .frame(width: width)
                    .padding(1)
                    .padding(.bottom, 5)
                }
                .onChange(of: selection) { segment in
                    if segment != nil, let index = activeIndex {
                        proxy.scrollTo(index, anchor: .center)
                    }
                }
                .onChange(of: focusedIndex) { index in
                    if let index { proxy.scrollTo(index, anchor: .center) }
                }
            }
        }
        .frame(height: 100)
    }

    private func block(_ step: ScheduleRhythm.Step, index: Int, width: CGFloat) -> some View {
        Button {
            selection = nil
            pinnedIndex = pinnedIndex == index ? nil : index
        } label: {
            ZStack {
                Rectangle().fill(color(step.kind).opacity(activeIndex == nil || activeIndex == index ? 0.9 : 0.55))
                if width >= 65 {
                    Text(title(step.kind)).font(SettingsTokens.descriptionFont)
                        .lineLimit(1).foregroundStyle(.white).padding(.horizontal, 4)
                }
            }
            .frame(width: width, height: 34)
            .overlay {
                Rectangle().strokeBorder(activeIndex == index ? Color.primary : Color.primary.opacity(0.15),
                                         lineWidth: activeIndex == index ? 2 : 0.5)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .focusable()
        .focused($focusedIndex, equals: index)
        .onHover { inside in
            if inside { hoveredIndex = index }
            else if hoveredIndex == index { hoveredIndex = nil }
        }
        .help(Text(duration(step.duration)))
        .accessibilityLabel(Text(title(step.kind)) + Text(" \(duration(step.duration))"))
        .accessibilityAddTraits(pinnedIndex == index ? .isSelected : [])
        .accessibilityIdentifier("timeline-segment-\(index)")
    }

    private var repeatArrow: some View {
        VStack(spacing: 4) {
            RepeatArrow().stroke(.primary.opacity(0.85), style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
                .frame(height: 26)
            Text("Repeat rhythm").font(.system(size: 10, weight: .medium)).foregroundStyle(.primary)
        }
        .accessibilityLabel("Repeat rhythm")
    }

    private var detail: some View {
        VStack(alignment: .leading, spacing: SettingsTokens.rowTextSpacing) {
            if let selection, hoveredIndex == nil, focusedIndex == nil {
                HStack(spacing: SettingsTokens.listItemSpacing) {
                    Text(title(selection.kind)).fontWeight(.medium)
                    Text("\(time(selection.start))–\(time(selection.end))").monospacedDigit()
                    Text(duration(selection.duration)).foregroundStyle(.secondary)
                }
                .accessibilityIdentifier("timeline-detail")
            } else if let activeIndex, rhythm.steps.indices.contains(activeIndex) {
                let step = rhythm.steps[activeIndex]
                HStack(spacing: SettingsTokens.listItemSpacing) {
                    Text(title(step.kind)).fontWeight(.medium)
                    Text(duration(step.duration)).foregroundStyle(.secondary)
                }
                .accessibilityIdentifier("timeline-detail")
            } else {
                Text("Hover or select a segment to see its duration.").foregroundStyle(.secondary)
            }
            if timeline.end > timeline.windowEnd {
                Text("Schedule ends at \(time(timeline.windowEnd)); the last break continues until \(time(timeline.end)).")
                    .foregroundStyle(.secondary)
            }
        }
        .font(SettingsTokens.descriptionFont)
        .frame(minHeight: 18, alignment: .topLeading)
    }

    private func color(_ kind: DayTimeline.Kind) -> Color {
        switch kind {
        case .work: .blue
        case .shortBreak: .orange
        case .longBreak: .purple
        case .gap: .secondary
        }
    }

    private func title(_ kind: DayTimeline.Kind) -> LocalizedStringKey {
        switch kind {
        case .work: "Work"
        case .shortBreak: "Short break"
        case .longBreak: "Long break"
        case .gap: "Outside schedule"
        }
    }

    private func time(_ seconds: TimeInterval) -> String {
        let value = Int(seconds), local = value % 86400
        let clock = local.isMultiple(of: 60)
            ? String(format: "%02d:%02d", local / 3600, local % 3600 / 60)
            : String(format: "%02d:%02d:%02d", local / 3600, local % 3600 / 60, local % 60)
        return value < 86400 ? clock : "\(clock) (+\(value / 86400))"
    }

    private func duration(_ seconds: TimeInterval) -> String {
        if seconds > 0, seconds < 60 { return languageStore.string("\(Int(seconds.rounded())) sec") }
        if seconds >= 3600 {
            let minutes = Int(seconds / 60)
            if minutes.isMultiple(of: 60) { return languageStore.string("\(minutes / 60) h") }
            return languageStore.string("\(minutes / 60) h \(minutes % 60) min")
        }
        let minutes = (seconds / 60).formatted(.number.precision(.fractionLength(0...2)).locale(locale))
        return languageStore.string("\(minutes) min")
    }

    private struct RepeatArrow: Shape {
        func path(in rect: CGRect) -> Path {
            var path = Path()
            let left = CGPoint(x: 8, y: 3)
            let right = rect.maxX - 8
            let bottom = rect.maxY - 2
            let radius = min(18, rect.width / 4)
            path.move(to: CGPoint(x: right, y: 3))
            path.addLine(to: CGPoint(x: right, y: bottom - radius))
            path.addQuadCurve(to: CGPoint(x: right - radius, y: bottom),
                              control: CGPoint(x: right, y: bottom))
            path.addLine(to: CGPoint(x: left.x + radius, y: bottom))
            path.addQuadCurve(to: CGPoint(x: left.x, y: bottom - radius),
                              control: CGPoint(x: left.x, y: bottom))
            path.addLine(to: left)
            path.move(to: CGPoint(x: 3, y: 9))
            path.addLine(to: left)
            path.addLine(to: CGPoint(x: 13, y: 9))
            return path
        }
    }
}
