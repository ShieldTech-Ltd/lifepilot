import Foundation
import LifePilotCore

/// Realistic sample task/reminder data for previews, tests, and Phase 3's
/// mock-driven screens.
public enum MockTasks {
    public static func items(relativeTo now: Date = Date()) -> [TaskItem] {
        [
            TaskItem(
                title: "Prepare notes for tomorrow",
                dueDate: now.addingTimeInterval(3 * 3600),
                priority: .high
            ),
            TaskItem(
                title: "Call family",
                dueDate: now.addingTimeInterval(5 * 3600),
                priority: .normal
            ),
            TaskItem(
                title: "Pick up groceries",
                dueDate: now.addingTimeInterval(6 * 3600),
                priority: .low
            ),
            TaskItem(
                title: "Book the next appointment",
                dueDate: nil,
                isCompleted: true,
                priority: .low
            ),
        ]
    }
}
