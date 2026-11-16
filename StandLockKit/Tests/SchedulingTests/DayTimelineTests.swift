import Foundation
import Testing
@testable import Scheduling
import StandLockCore

@Suite("Linear day timeline")
struct DayTimelineTests {
    private let monday = Calendar.current.date(from: DateComponents(year: 2026, month: 5, day: 4, hour: 12))!
    private func schedule(_ windows: [TimeWindow], rule: RepetitionRule? = nil,
                          cycle: [IntervalStep]? = nil) -> Schedule {
        Schedule(name: "Work", days: .weekdays, windows: windows, breakInterval: 3300, breakDuration: 300,
                 intervalCycle: cycle, repetitionRule: rule)
    }

    @Test func fullDayShowsWorkShortBreaksAndLongBreakInOrder() {
        let stored = schedule([.init(startHour: 4, startMinute: 0, endHour: 22, endMinute: 45)],
            rule: .init(shortBreakCount: 2, shortBreakDuration: 300, longBreakDuration: 900))
        let timeline = DayTimeline(schedule: stored, preview: DayPreview.make(for: stored, from: monday))
        #expect(Array(timeline.segments.prefix(6)).map(\.kind) == [.work, .shortBreak, .work, .shortBreak, .work, .longBreak])
        #expect(Array(timeline.segments.prefix(6)).map(\.duration) == [3300, 300, 3300, 300, 3300, 900])
        #expect(timeline.start == 14400)
        #expect(timeline.end == 81900)
        #expect(timeline.firstCycle == 14400..<25800)
        #expect(timeline.duration(for: .shortBreak) == 3600)
        #expect(timeline.duration(for: .longBreak) == 4500)
        #expect(timeline.duration(for: .work) == 59400)
    }

    @Test func overnightBreaksStayAfterTheirOpeningInsteadOfWrappingToTheFront() {
        let stored = schedule([.init(startHour: 22, startMinute: 0, endHour: 2, endMinute: 0)])
        let preview = DayPreview.make(for: stored, from: monday)
        #expect(preview.items.map(\.dayOffset) == [0, 0, 1, 1])
        let timeline = DayTimeline(schedule: stored, preview: preview)
        #expect(timeline.start == 79200)
        #expect(timeline.end == 93600)
        #expect(timeline.segments.filter { $0.kind == .shortBreak }.map(\.start) == [82500, 86100, 89700, 93300])
        #expect(timeline.segments.last?.end == 93600)
    }

    @Test func overlappingWindowsAreMergedAndUnscheduledGapsStayVisible() throws {
        let stored = schedule([.init(startHour: 9, startMinute: 0, endHour: 12, endMinute: 0),
            .init(startHour: 10, startMinute: 0, endHour: 11, endMinute: 0),
            .init(startHour: 13, startMinute: 0, endHour: 14, endMinute: 0)])
        let timeline = DayTimeline(schedule: stored, preview: DayPreview(items: []))
        #expect(timeline.segments.map(\.kind) == [.work, .gap, .work])
        #expect(timeline.duration(for: .work) == 14400)
        try #require(timeline.segments.count == 3)
        #expect(timeline.segments[1].start == 43200)
        #expect(timeline.segments[1].end == 46800)
    }

    @Test func breakPastTheEndRetainsItsFullDurationAndWindowEndpoint() {
        let stored = schedule([.init(startHour: 23, startMinute: 0, endHour: 23, endMinute: 58)])
        let timeline = DayTimeline(schedule: stored, preview: DayPreview(items: [.init(hour: 23, minute: 55, duration: 600)]))
        #expect(timeline.windowEnd == 86280)
        #expect(timeline.end == 86700)
        #expect(timeline.segments.last?.duration == 600)
        #expect(timeline.segments.last?.breakIndex == 0)
    }

    @Test func varyingWorkIntervalsAndSecondsRemainExact() throws {
        let stored = schedule([.init(startHour: 9, startMinute: 0, endHour: 12, endMinute: 0)],
            cycle: [.init(duration: 1230), .init(duration: 2400)])
        let timeline = DayTimeline(schedule: stored, preview: DayPreview.make(for: stored, from: monday))
        #expect(Array(timeline.segments.prefix(4)).map(\.duration) == [1230, 300, 2400, 300])
        try #require(timeline.segments.count >= 4)
        #expect(timeline.segments[1].start == 33630)
        #expect(timeline.firstCycle == 32400..<33930)
    }

    @Test func longOvernightRestIsOneUnbrokenSegment() {
        var stored = schedule([.init(startHour: 22, startMinute: 45, endHour: 4, endMinute: 0)])
        stored.breakInterval = 900
        stored.breakDuration = 18000
        let timeline = DayTimeline(schedule: stored, preview: DayPreview.make(for: stored, from: monday))
        #expect(timeline.segments.map(\.duration) == [900, 18000])
        #expect(timeline.segments.map(\.start) == [81900, 82800])
        #expect(timeline.end == 100800)
    }

    @Test func noActiveDaysHaveNoTimeline() {
        var stored = schedule([.init(startHour: 9, startMinute: 0, endHour: 17, endMinute: 0)])
        stored.days = .custom([])
        let timeline = DayTimeline(schedule: stored, preview: DayPreview(items: []))
        #expect(timeline.segments.isEmpty)
        #expect(timeline.firstCycle == nil)
    }
}
