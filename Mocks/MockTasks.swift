import Foundation
import LifePilotCore

/// Realistic sample task/reminder data for previews, tests, and Phase 3's
/// mock-driven screens.
public enum MockTasks {
    public static func items(relativeTo now: Date = Date()) -> [TaskItem] {
        [
            TaskItem(
                title: "Finish the TechFest presentation",
                dueDate: now.addingTimeInterval(3 * 3600),
                priority: .high
            ),
            TaskItem(
                title: "Test LifePilot on the demo iPhone",
                dueDate: now.addingTimeInterval(5 * 3600),
                priority: .normal
            ),
            TaskItem(
                title: "Print project QR cards",
                dueDate: now.addingTimeInterval(6 * 3600),
                priority: .low
            ),
            TaskItem(
                title: "Submit module reflection",
                dueDate: nil,
                isCompleted: true,
                priority: .low
            ),
        ]
    }
}
