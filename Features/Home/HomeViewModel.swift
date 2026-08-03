import Foundation
import LifePilotCore
import LifePilotDesignSystem
import LifePilotGhostBrain

/// Optional system integrations used by the store-backed compatibility path.
public struct HomeBriefingIntegrations: Sendable {
    public var reminders: any RemindersIntegrating

    public init(reminders: any RemindersIntegrating = UnavailableRemindersIntegration()) {
        self.reminders = reminders
    }
}

/// Adapts the shared demo session into Home-specific view data.
@Observable
@MainActor
public final class HomeViewModel {
    public let session: DemoSessionStore
    public private(set) var topTasks: [TaskItem] = []
    public private(set) var findings: [PlanningFinding] = []
    public private(set) var freshnessSummary = "Local"

    private let taskStore: (any TaskStore)?
    private let eventStore: (any EventStore)?
    private let preferenceStore: (any PreferenceStore)?
    private let integrations: HomeBriefingIntegrations?

    public init(session: DemoSessionStore) {
        self.session = session
        taskStore = nil
        eventStore = nil
        preferenceStore = nil
        integrations = nil
    }

    public convenience init(ghostBrain: GhostBrainServing) {
        self.init(session: DemoSessionStore(ghostBrain: ghostBrain))
    }

    public init(
        taskStore: any TaskStore,
        eventStore: any EventStore,
        preferenceStore: any PreferenceStore,
        integrations: HomeBriefingIntegrations = HomeBriefingIntegrations()
    ) {
        session = DemoSessionStore()
        self.taskStore = taskStore
        self.eventStore = eventStore
        self.preferenceStore = preferenceStore
        self.integrations = integrations
    }

    public var greeting: String {
        let greetingWord = session.model?.greetingContext.timeOfDay.greetingWord ?? "Good morning"
        return "\(greetingWord), \(session.firstName)"
    }

    public var dateText: String {
        session.model?.generatedAt.formatted(.dateTime.weekday(.wide).month(.wide).day()) ?? ""
    }

    public var recommendations: [BriefingCard.Content] {
        session.availableRecommendations.map { recommendation in
            BriefingCard.Content(
                id: recommendation.id,
                title: recommendation.title,
                reasoning: recommendation.reasoning,
                sourceAgent: recommendation.sourceAgent,
                riskBadgeText: recommendation.riskLevel == .low ? nil : recommendation.riskLevel.rawValue.capitalized
            )
        }
    }

    public var upcomingEvents: [CalendarEvent] { session.visibleEvents }

    public var eventsAhead: [CalendarEvent] {
        upcomingEvents.filter { $0.endDate > eventReferenceDate }
    }

    public var nextEvent: CalendarEvent? { eventsAhead.first }
    public var laterEvents: [CalendarEvent] { Array(eventsAhead.dropFirst()) }
    public var signals: [DaySignal] { session.visibleSignals }
    public var recentActivity: [DemoActivity] { session.activities }
    public var displayName: String { session.displayName }
    public var profileImageData: Data? { session.profileImageData }
    public var profileContextText: String { "Prepared for \(session.briefingTime) • \(session.course)" }
    public var pendingCount: Int { session.availableRecommendations.count }
    public var connectedSourceCount: Int { session.connectedSourceCount }

    public var readinessProgress: Double { session.readinessProgress }

    public var readinessText: String { "\(Int(readinessProgress * 100))%" }
    public var isLoading: Bool { session.isLoading }
    public var isPrepared: Bool { session.isPrepared }
    public var loadErrorMessage: String? { session.loadErrorMessage }

    public func load() async {
        guard let taskStore, let integrations else {
            await session.prepare()
            return
        }

        let local = await taskStore.allTasks()
        let state = await integrations.reminders.authorizationState()
        switch state {
        case .authorized, .limited:
            do {
                let remote = try await integrations.reminders.fetchOpenReminders()
                await reconcileReminders(local: local, remote: remote, in: taskStore)
                topTasks = await taskStore.allTasks().filter { !$0.isCompleted }
                freshnessSummary = "Local data · Reminders connected"
            } catch {
                topTasks = local.filter { !$0.isCompleted }
                freshnessSummary = "Local data · Reminders unavailable"
            }
        default:
            topTasks = local.filter { !$0.isCompleted }
            freshnessSummary = "Local data"
        }
    }

    public func refresh() async {
        await load()
    }

    public func retry() async {
        await session.retry()
    }

    public func approve(_ content: BriefingCard.Content) {
        session.resolve(content.id, approved: true)
    }

    public func dismiss(_ content: BriefingCard.Content) {
        session.resolve(content.id, approved: false)
    }

    private var eventReferenceDate: Date {
        session.model?.generatedAt ?? Date()
    }

    private func reconcileReminders(
        local: [TaskItem],
        remote: [TaskItem],
        in taskStore: any TaskStore
    ) async {
        var existingByExternal: [String: TaskItem] = [:]
        for task in local {
            if let identifier = task.externalIdentifier {
                existingByExternal[identifier] = task
            }
        }
        let remoteIdentifiers = Set(remote.compactMap(\.externalIdentifier))
        for task in local where task.source == .eventKitReminders {
            guard let identifier = task.externalIdentifier,
                  !remoteIdentifiers.contains(identifier)
            else { continue }
            try? await taskStore.delete(id: task.id)
            existingByExternal.removeValue(forKey: identifier)
        }
        for reminder in remote {
            var reconciled = reminder
            if let identifier = reminder.externalIdentifier, let existing = existingByExternal[identifier] {
                reconciled = TaskItem(
                    id: existing.id,
                    title: reminder.title,
                    notes: reminder.notes,
                    dueDate: reminder.dueDate,
                    isCompleted: reminder.isCompleted,
                    completedAt: reminder.completedAt,
                    recurrence: reminder.recurrence,
                    source: .eventKitReminders,
                    externalIdentifier: identifier,
                    syncState: .synced,
                    createdAt: existing.createdAt,
                    updatedAt: Date()
                )
            }
            try? await taskStore.save(reconciled)
            if let identifier = reconciled.externalIdentifier {
                existingByExternal[identifier] = reconciled
            }
        }
    }
}
