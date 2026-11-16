import Foundation
import StandLockCore

/// One chronological walk, with next-day times above 86400 rather than wrapped to midnight.
public struct DayTimeline: Equatable, Sendable {
    public enum Kind: Equatable, Sendable { case work, shortBreak, longBreak, gap }
    public struct Segment: Equatable, Sendable {
        public let kind: Kind
        public let start: TimeInterval
        public let end: TimeInterval
        public let breakIndex: Int?
        public var duration: TimeInterval { end - start }
    }
    public let segments: [Segment]
    public let start: TimeInterval
    public let end: TimeInterval
    public let windowEnd: TimeInterval
    public let firstCycle: Range<TimeInterval>?

    public func duration(for kind: Kind) -> TimeInterval {
        segments.filter { $0.kind == kind }.reduce(0) { $0 + $1.duration }
    }

    public init(schedule: Schedule, preview: DayPreview) {
        let windows = Self.merged(schedule.windows.compactMap { window -> Range<TimeInterval>? in
            let start = TimeInterval(window.startHour * 3600 + window.startMinute * 60)
            var end = TimeInterval(window.endHour * 3600 + window.endMinute * 60)
            guard start != end else { return nil }
            if end < start { end += 86400 }
            return start..<end
        })
        guard !schedule.days.activeDays.isEmpty, let first = windows.first, let last = windows.last else {
            segments = []; start = 0; end = 0; windowEnd = 0; firstCycle = nil
            return
        }
        let breaks = preview.items.enumerated().compactMap { index, item -> Segment? in
            guard item.duration.isFinite, item.duration > 0, item.dayOffset >= 0 else { return nil }
            let start = Double(item.dayOffset) * 86400 + Double(item.hour * 3600 + item.minute * 60 + item.second)
            var kind = Kind.shortBreak
            if let rule = schedule.repetitionRule, rule.shortBreakCount >= 0, rule.shortBreakCount < Int.max,
               index % (rule.shortBreakCount + 1) == rule.shortBreakCount { kind = .longBreak }
            return Segment(kind: kind, start: start, end: start + item.duration, breakIndex: index)
        }.sorted { $0.start < $1.start }
        var work: [Segment] = []
        for window in windows {
            var cursor = window.lowerBound
            for pause in breaks where pause.end > cursor && pause.start < window.upperBound {
                if pause.start > cursor {
                    work.append(Segment(kind: .work, start: cursor, end: min(pause.start, window.upperBound), breakIndex: nil))
                }
                cursor = min(window.upperBound, max(cursor, pause.end))
            }
            if cursor < window.upperBound {
                work.append(Segment(kind: .work, start: cursor, end: window.upperBound, breakIndex: nil))
            }
        }
        let occupied = (work + breaks).sorted { $0.start < $1.start }
        var filled: [Segment] = []
        var cursor = min(first.lowerBound, occupied.first?.start ?? first.lowerBound)
        start = cursor
        windowEnd = last.upperBound
        end = max(last.upperBound, occupied.last?.end ?? last.upperBound)
        for segment in occupied {
            if cursor < segment.start {
                filled.append(Segment(kind: .gap, start: cursor, end: segment.start, breakIndex: nil))
            }
            filled.append(segment)
            cursor = max(cursor, segment.end)
        }
        if cursor < end { filled.append(Segment(kind: .gap, start: cursor, end: end, breakIndex: nil)) }
        segments = filled
        let finalKind: Kind = schedule.repetitionRule == nil ? .shortBreak : .longBreak
        if let workStart = work.first?.start, let cycleEnd = breaks.first(where: { $0.kind == finalKind })?.end,
           workStart < cycleEnd {
            firstCycle = workStart..<cycleEnd
        } else { firstCycle = nil }
    }

    private static func merged(_ ranges: [Range<TimeInterval>]) -> [Range<TimeInterval>] {
        var result: [Range<TimeInterval>] = []
        for range in ranges.sorted(by: { $0.lowerBound < $1.lowerBound }) {
            if let last = result.last, range.lowerBound <= last.upperBound {
                result[result.count - 1] = last.lowerBound..<max(last.upperBound, range.upperBound)
            } else { result.append(range) }
        }
        return result
    }
}
