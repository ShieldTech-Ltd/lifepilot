import Foundation
import LifePilotCore

/// Mock timeline data until AppShell wires store-backed providers.
public struct MockTimelineProvider: TimelineProviding {
    public init() {}

    public func loadEntries(relativeTo now: Date) async -> [TimelineEntry] {
        let events = MockCalendar.events(relativeTo: now).map {
            TimelineEntry(
                id: $0.id,
                date: $0.startDate,
                title: $0.title,
                subtitle: $0.location,
                kind: .event,
                context: $0.context
            )
        }
        let tasks = MockTasks.items(relativeTo: now).compactMap { task -> TimelineEntry? in
            guard let dueDate = task.dueDate else { return nil }
            return TimelineEntry(
                id: task.id,
                date: dueDate,
                title: task.title,
                subtitle: "Due",
                kind: .task,
                context: task.context
            )
        }
        let reminders = [
            TimelineEntry(
                date: now.addingTimeInterval(90 * 60),
                title: "Take medication reminder",
                subtitle: "Local reminder",
                kind: .reminder,
                context: .personal
            ),
        ]

        return (events + tasks + reminders).sorted { $0.date < $1.date }
    }
}
