import Foundation
import LifePilotCore

/// Realistic sample notification data for previews, tests, and Phase 3's
/// mock-driven screens.
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
                title: "Unusual charge detected",
                body: "A £34 charge at an unfamiliar merchant was flagged for review.",
                receivedAt: now.addingTimeInterval(-2 * 3600),
                sourceAgent: .finance,
                isRead: false
            ),
            NotificationItem(
                title: "Morning briefing ready",
                body: "Your student day is prepared. 3 recommendations are waiting.",
                receivedAt: now.addingTimeInterval(-6 * 3600),
                sourceAgent: nil,
                isRead: true
            ),
        ]
    }
}
