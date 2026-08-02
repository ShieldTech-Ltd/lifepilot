import Foundation
import LifePilotCore
import LifePilotDesignSystem
import LifePilotGhostBrain

/// Adapts the shared demo session into Home-specific view data.
@Observable
@MainActor
public final class HomeViewModel {
    public let session: DemoSessionStore

    public init(session: DemoSessionStore) {
        self.session = session
    }

    public convenience init(ghostBrain: GhostBrainServing) {
        self.init(session: DemoSessionStore(ghostBrain: ghostBrain))
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
        await session.prepare()
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
}
