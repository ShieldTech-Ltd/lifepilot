import Foundation
import LifePilotCore

/// Realistic personal calendar data for previews, tests, and the offline demo.
public enum MockCalendar {
    /// A full day's worth of varied events, anchored relative to `now` so
    /// previews always show a plausible "today."
    public static func events(
        relativeTo now: Date = Date()
    ) -> [CalendarEvent] {
        let calendar = Calendar.current
        return [
            CalendarEvent(
                title: "Morning planning",
                location: "Home",
                startDate: calendar.date(bySettingHour: 9, minute: 0, second: 0, of: now) ?? now,
                endDate: calendar.date(bySettingHour: 9, minute: 30, second: 0, of: now) ?? now,
                attendeeCount: 1
            ),
            CalendarEvent(
                title: "Work shift",
                location: "City Centre",
                startDate: calendar.date(bySettingHour: 10, minute: 0, second: 0, of: now) ?? now,
                endDate: calendar.date(bySettingHour: 13, minute: 50, second: 0, of: now) ?? now,
                attendeeCount: 1
            ),
            CalendarEvent(
                title: "Dentist appointment",
                location: "High Street Dental Practice",
                startDate: calendar.date(bySettingHour: 14, minute: 0, second: 0, of: now) ?? now,
                endDate: calendar.date(bySettingHour: 14, minute: 45, second: 0, of: now) ?? now,
                attendeeCount: 1
            ),
            CalendarEvent(
                title: "Grocery pickup",
                location: "Local supermarket",
                startDate: calendar.date(bySettingHour: 16, minute: 0, second: 0, of: now) ?? now,
                endDate: calendar.date(bySettingHour: 16, minute: 30, second: 0, of: now) ?? now,
                attendeeCount: 1
            ),
            CalendarEvent(
                title: "Dinner with Maya",
                location: "Neighbourhood cafe",
                startDate: calendar.date(bySettingHour: 18, minute: 30, second: 0, of: now) ?? now,
                endDate: calendar.date(bySettingHour: 20, minute: 0, second: 0, of: now) ?? now,
                attendeeCount: 2
            ),
        ].sorted { $0.startDate < $1.startDate }
    }
}
