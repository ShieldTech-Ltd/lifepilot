import Foundation
import LifePilotCore

/// Realistic sample notification data for previews, tests, and the offline demo.
public enum MockNotifications {
    public static func items(relativeTo now: Date = Date()) -> [NotificationItem] {
        [
            NotificationItem(
                title: "Train delayed",
                body: "The 1A23 service to London Euston is running 18 minutes late.",
                receivedAt: now.addingTimeInterval(-30 * 60),
                sourceAgent: .travel,
                isRead: false
            ),
            NotificationItem(
                title: "Appointment coming up",
                body: "Your dentist appointment starts at 14:00. Leave enough travel time.",
                receivedAt: now.addingTimeInterval(-2 * 3600),
                sourceAgent: .calendar,
                isRead: false
            ),
            NotificationItem(
                title: "Morning briefing ready",
                body: "Your day is prepared. Helpful recommendations are waiting.",
                receivedAt: now.addingTimeInterval(-6 * 3600),
                sourceAgent: nil,
                isRead: true
            ),
        ]
    }
}
