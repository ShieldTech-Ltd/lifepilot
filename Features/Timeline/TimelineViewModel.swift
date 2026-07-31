import Foundation
import LifePilotCore
import LifePilotGhostBrain

/// Builds a connected-source-aware timeline from the shared demo session.
@Observable
@MainActor
public final class TimelineViewModel {
    public let session: DemoSessionStore

    public init(session: DemoSessionStore) {
        self.session = session
    }

    public convenience init() {
        self.init(session: DemoSessionStore(ghostBrain: MockRecommendationProvider()))
    }

    public var selectedFilter: TimelineFilter {
        get { session.timelineFilter }
        set { session.timelineFilter = newValue }
    }

    public var entries: [TimelineEntry] {
        let events = session.calendarEnabled ? session.visibleEvents.map {
            TimelineEntry(id: $0.id, date: $0.startDate, title: $0.title, subtitle: $0.location, kind: .event)
        } : []

        let emails = session.emailEnabled ? session.emailMessages.map {
            TimelineEntry(id: $0.id, date: $0.receivedAt, title: $0.subject, subtitle: $0.sender, kind: .email)
        } : []

        let tasks = session.tasks.compactMap { task -> TimelineEntry? in
            guard let dueDate = task.dueDate else { return nil }
            return TimelineEntry(id: task.id, date: dueDate, title: task.title, subtitle: "Due", kind: .task)
        }

        let travel = session.travelEnabled ? session.travelItineraries.map {
            TimelineEntry(
                id: $0.id,
                date: $0.departureDate,
                title: "\($0.carrier) \($0.identifier) — \($0.origin) to \($0.destination)",
                subtitle: $0.status == .delayed ? "Delayed" : "On time",
                kind: .travel
            )
        } : []

        let actions = session.activities.map {
            TimelineEntry(
                id: $0.id,
                date: $0.resolvedAt,
                title: $0.title,
                subtitle: $0.result,
                kind: .action
            )
        }

        let all = (events + emails + tasks + travel + actions).sorted { $0.date < $1.date }
        return all.filter { selectedFilter.includes($0.kind) }
    }

    public func load() async {
        await session.prepare()
    }
}

public struct TimelineEntry: Identifiable {
    public let id: UUID
    public let date: Date
    public let title: String
    public let subtitle: String?
    public let kind: Kind

    public enum Kind: Hashable {
        case event
        case email
        case task
        case travel
        case action
    }
}

private extension TimelineFilter {
    func includes(_ kind: TimelineEntry.Kind) -> Bool {
        switch (self, kind) {
        case (.all, _), (.calendar, .event), (.email, .email), (.task, .task), (.travel, .travel), (.action, .action):
            true
        default:
            false
        }
    }
}
