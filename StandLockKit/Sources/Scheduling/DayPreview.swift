import Foundation
import StandLockCore

/// The break times of one day, walked through the real evaluator so the two cannot drift apart.
public struct DayPreview: Equatable, Sendable {
    public struct Item: Equatable, Sendable {
        public let hour: Int
        public let minute: Int
        public let second: Int
        public let duration: TimeInterval

        public init(hour: Int, minute: Int, second: Int = 0, duration: TimeInterval) {
            self.hour = hour
            self.minute = minute
            self.second = second
            self.duration = duration
        }
    }

    public let items: [Item]

    public var morning: [Item] { items.filter { $0.hour < 12 } }
    public var afternoon: [Item] { items.filter { (12..<18).contains($0.hour) } }
    public var evening: [Item] { items.filter { $0.hour >= 18 } }
    public var shortestBreak: TimeInterval? { items.map(\.duration).min() }
    public var longestBreak: TimeInterval? { items.map(\.duration).max() }

    /// Previews windows opening on `date`, or the next selected day, including their overnight
    /// tails. Midnight is part of the same rhythm, not the start of another work interval.
    public static func make(
        for schedule: Schedule, from date: Date, evaluator: any SchedulingEngine = ScheduleEvaluator()
    ) -> DayPreview {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: date)
        let activeDay = (0..<7)
            .compactMap { calendar.date(byAdding: .day, value: $0, to: today) }
            .first { day in
                Weekday(rawValue: calendar.component(.weekday, from: day))
                    .map(schedule.days.activeDays.contains) ?? false
            }
        guard let activeDay,
              let weekday = Weekday(rawValue: calendar.component(.weekday, from: activeDay)),
              let nextDay = calendar.date(byAdding: .day, value: 1, to: activeDay) else {
            return DayPreview(items: [])
        }

        let overnightEnd = schedule.windows.filter {
            $0.startHour * 60 + $0.startMinute > $0.endHour * 60 + $0.endMinute
        }.map { $0.endHour * 60 + $0.endMinute }.max() ?? 0
        guard let dayEnd = calendar.date(bySettingHour: overnightEnd / 60,
                                        minute: overnightEnd % 60, second: 0, of: nextDay) else {
            return DayPreview(items: [])
        }
        // Isolate this day's openings so yesterday's overnight tail cannot create a second
        // first interval at 00:00, and tomorrow's openings cannot enter the extended walk.
        var previewSchedule = schedule
        previewSchedule.days = .custom([weekday])

        var items: [Item] = []
        var cursor = activeDay
        var index = 0
        // `next > cursor`: on the day clocks go back the evaluator can answer with a time behind
        // the walk, and following it would hang the Settings window.
        while let next = evaluator.nextBreakTime(for: previewSchedule, after: cursor, cycleIndex: index),
              next > cursor, next < dayEnd {
            let duration = evaluator.breakDuration(for: previewSchedule, breakIndex: index)
            let time = calendar.dateComponents([.hour, .minute, .second], from: next)
            items.append(Item(hour: time.hour ?? 0, minute: time.minute ?? 0, second: time.second ?? 0, duration: duration))
            cursor = next.addingTimeInterval(duration)
            index += 1
        }
        return DayPreview(items: items)
    }
}
