import Foundation
import LifePilotCore
import LifePilotDesignSystem
import LifePilotGhostBrain

/// Presents live metrics from the shared demo session so approval and
/// connection changes are reflected across tabs immediately.
@Observable
@MainActor
public final class InsightsViewModel {
    public let session: DemoSessionStore

    public init(session: DemoSessionStore) {
        self.session = session
    }

    public convenience init(ghostBrain: GhostBrainServing) {
        self.init(session: DemoSessionStore(ghostBrain: ghostBrain))
    }

    public var metrics: [Metric] {
        let pending = session.availableRecommendations.count
        let approved = session.activities.filter(\.wasApproved).count
        return [
            Metric(id: "pending", value: "\(pending)", label: "Awaiting your review", trend: .flat),
            Metric(id: "approved", value: "\(approved)", label: "Actions approved", trend: approved > 0 ? .up : .flat),
            Metric(id: "signals", value: "\(session.visibleSignals.count)", label: "Signals observed", trend: .flat),
            Metric(id: "saved", value: "\(approved * 5)", label: "Est. minutes saved", trend: approved > 0 ? .up : .flat),
        ]
    }

    public var breakdown: [AgentBreakdown] {
        Dictionary(grouping: session.availableRecommendations, by: \.sourceAgent)
            .map { AgentBreakdown(agent: $0.key, count: $0.value.count) }
            .sorted { $0.count > $1.count }
    }

    public func load() async {
        await session.prepare()
    }

    public struct Metric: Identifiable {
        public let id: String
        public let value: String
        public let label: String
        public let trend: InsightCard.Trend?
    }

    public struct AgentBreakdown: Identifiable {
        public var id: AgentKind { agent }
        public let agent: AgentKind
        public let count: Int
    }
}
