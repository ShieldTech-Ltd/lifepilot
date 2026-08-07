import Foundation
import LifePilotCore

/// Realistic sample inbox data for previews, tests, and Phase 3's
/// mock-driven screens.
public enum MockEmail {
    public static func messages(relativeTo now: Date = Date()) -> [EmailMessage] {
        [
            EmailMessage(
                sender: "Maya Patel",
                subject: "Dinner plan for Friday",
                preview: "Can you confirm whether 18:30 still works for you?",
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
                sender: "Community Centre",
                subject: "Your weekend class is confirmed",
                preview: "Your booking is confirmed. Please arrive ten minutes early.",
                receivedAt: now.addingTimeInterval(-45 * 60),
                isUnread: false,
                requiresReply: false
            ),
            EmailMessage(
                sender: "High Street Dental Practice",
                subject: "Appointment reminder",
                preview: "This is a reminder for your appointment today at 14:00.",
                receivedAt: now.addingTimeInterval(-18 * 3600),
                isUnread: false,
                requiresReply: true
            ),
        ]
    }
}
