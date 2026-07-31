import Foundation
import LifePilotCore

/// Realistic sample inbox data for previews, tests, and Phase 3's
/// mock-driven screens.
public enum MockEmail {
    public static func messages(relativeTo now: Date = Date()) -> [EmailMessage] {
        [
            EmailMessage(
                sender: "Dr Sarah Ahmed",
                subject: "TechFest demo checklist: reply by Friday",
                preview: "Before the showcase, please confirm your presentation slot and equipment checklist.",
                receivedAt: now.addingTimeInterval(-3 * 24 * 3600),
                isUnread: true,
                requiresReply: true
            ),
            EmailMessage(
                sender: "National Rail",
                subject: "Your London Euston journey has been updated",
                preview: "There is a delay affecting your upcoming journey into London.",
                receivedAt: now.addingTimeInterval(-2 * 3600),
                isUnread: true,
                requiresReply: false
            ),
            EmailMessage(
                sender: "GitHub",
                subject: "[LifePilot] TechFest demo pull request",
                preview: "The TechFest readiness branch is ready for review.",
                receivedAt: now.addingTimeInterval(-45 * 60),
                isUnread: false,
                requiresReply: false
            ),
            EmailMessage(
                sender: "Maya Patel",
                subject: "Rehearsal room confirmed",
                preview: "Room 4.01 is booked for our LifePilot rehearsal at 14:00.",
                receivedAt: now.addingTimeInterval(-18 * 3600),
                isUnread: false,
                requiresReply: true
            ),
        ]
    }
}
