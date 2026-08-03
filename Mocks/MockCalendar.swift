import Foundation
import LifePilotCore

/// Realistic sample calendar data for previews, tests, and Phase 3's
/// mock-driven screens. Not used by production code; see
/// docs/MASTER_ROADMAP.md Phase 7 for the real EventKit-backed source.
public enum MockCalendar {
    /// A full day's worth of varied events, anchored relative to `now` so
    /// previews always show a plausible "today."
    // swiftlint:disable:next function_body_length
    public static func events(
        relativeTo now: Date = Date()
    ) -> [CalendarEvent] {
        let calendar = Calendar.current
        var events = [
            CalendarEvent(
                title: "Algorithms Lecture",
                location: "International House, Room 2.04",
                startDate: calendar.date(bySettingHour: 9, minute: 0, second: 0, of: now) ?? now,
                endDate: calendar.date(bySettingHour: 10, minute: 0, second: 0, of: now) ?? now,
                attendeeCount: 42
            ),
            CalendarEvent(
                title: "LifePilot Team Stand-up",
                location: "Microsoft Teams",
                startDate: calendar.date(bySettingHour: 10, minute: 30, second: 0, of: now) ?? now,
                endDate: calendar.date(bySettingHour: 11, minute: 0, second: 0, of: now) ?? now,
                attendeeCount: 4
            ),
            CalendarEvent(
                title: "Lunch with Maya",
                location: "Spitalfields Market",
                startDate: calendar.date(bySettingHour: 12, minute: 0, second: 0, of: now) ?? now,
                endDate: calendar.date(bySettingHour: 13, minute: 0, second: 0, of: now) ?? now,
                attendeeCount: 2
            ),
            CalendarEvent(
                title: "Group Project Lab",
                location: "Computer Lab 3",
                startDate: calendar.date(bySettingHour: 13, minute: 0, second: 0, of: now) ?? now,
                endDate: calendar.date(bySettingHour: 14, minute: 0, second: 0, of: now) ?? now,
                attendeeCount: 4
            ),
            CalendarEvent(
                title: "TechFest Demo Rehearsal",
                location: "International House, Room 4.01",
                startDate: calendar.date(bySettingHour: 14, minute: 0, second: 0, of: now) ?? now,
                endDate: calendar.date(bySettingHour: 14, minute: 45, second: 0, of: now) ?? now,
                attendeeCount: 8
            ),
            CalendarEvent(
                title: "Portfolio Review",
                location: "Library Study Zone",
                startDate: calendar.date(bySettingHour: 16, minute: 0, second: 0, of: now) ?? now,
                endDate: calendar.date(bySettingHour: 17, minute: 0, second: 0, of: now) ?? now,
                attendeeCount: 2
            ),
        ]

        let techFestSessions = [
            CalendarEvent(
                title: "TechFest 2026 Showcase",
                location: "International House",
                startDate: calendar.date(from: DateComponents(
                    year: 2026, month: 8, day: 3, hour: 13, minute: 30
                )) ?? now,
                endDate: calendar.date(from: DateComponents(
                    year: 2026, month: 8, day: 3, hour: 14, minute: 30
                )) ?? now,
                attendeeCount: 60
            ),
            CalendarEvent(
                title: "TechFest 2026 Awards",
                location: "International House",
                startDate: calendar.date(from: DateComponents(
                    year: 2026, month: 8, day: 3, hour: 16, minute: 30
                )) ?? now,
                endDate: calendar.date(from: DateComponents(
                    year: 2026, month: 8, day: 3, hour: 17, minute: 30
                )) ?? now,
                attendeeCount: 60
            ),
        ].filter { $0.endDate > now }

        events.append(contentsOf: techFestSessions)
        return events.sorted { $0.startDate < $1.startDate }
    }
}
