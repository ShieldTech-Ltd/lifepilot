import Foundation
import LifePilotCore
import LifePilotDesignSystem
import LifePilotGhostBrain
import SwiftUI

/// Presents live metrics from the shared demo session so approval and
/// connection changes are reflected across tabs immediately.
@Observable
@MainActor
public final class InsightsViewModel {
    public let session: DemoSessionStore
    public var selectedPeriod: InsightPeriod = .today

    public init(session: DemoSessionStore) {
        self.session = session
    }

    public convenience init(ghostBrain: GhostBrainServing) {
        self.init(session: DemoSessionStore(ghostBrain: ghostBrain))
    }

    public var metrics: [Metric] {
        let pending = session.availableRecommendations.count
        let approved = session.activities.filter(\.wasApproved).count
        switch selectedPeriod {
        case .today:
            return [
                Metric(
                    id: "pending",
                    value: "\(pending)",
                    label: "Awaiting review",
                    trend: .flat,
                    symbolName: "checkmark.shield.fill",
                    tint: Color.LifePilot.signalWarning,
                    detail: "Prepared actions waiting for your decision. Nothing executes before you approve it.",
                    actionLabel: pending == 0 ? "View action history" : "Review actions"
                ),
                Metric(
                    id: "approved",
                    value: "\(approved)",
                    label: "Approved today",
                    trend: approved > 0 ? .up : .flat,
                    symbolName: "checkmark.circle.fill",
                    tint: Color.LifePilot.signalSuccess,
                    detail: "Actions you approved today, with their simulated outcomes recorded in your timeline.",
                    actionLabel: "View approved actions"
                ),
                Metric(
                    id: "signals",
                    value: "\(session.visibleSignals.count)",
                    label: "Signals connected",
                    trend: .flat,
                    symbolName: "wave.3.right.circle.fill",
                    tint: Color.LifePilot.accentEnd,
                    detail: "Useful changes detected across your active events, reminders, and travel sources.",
                    actionLabel: "Open unified timeline"
                ),
                Metric(
                    id: "saved",
                    value: "\(approved * 5)m",
                    label: "Estimated time saved",
                    trend: approved > 0 ? .up : .flat,
                    symbolName: "clock.badge.checkmark.fill",
                    tint: Color.LifePilot.accentAI,
                    detail: "A conservative estimate based on five minutes of planning or follow-up "
                        + "avoided per approved action.",
                    actionLabel: "See how it was saved"
                ),
            ]
        case .week:
            return historicalMetrics(actions: 12 + approved, approvalRate: 82, signals: 28, saved: "47m")
        case .month:
            return historicalMetrics(actions: 47 + approved, approvalRate: 86, signals: 104, saved: "3.4h")
        }
    }

    public var breakdown: [AgentBreakdown] {
        let recommendations = (session.model?.recommendations ?? []).filter { session.isEnabled($0.sourceAgent) }
        return Dictionary(grouping: recommendations, by: \.sourceAgent)
            .map { agent, recommendations in
                AgentBreakdown(
                    agent: agent,
                    count: recommendations.count,
                    reviewedCount: session.activities.filter { $0.sourceAgent == agent }.count
                )
            }
            .sorted { $0.count > $1.count }
    }

    public var readinessProgress: Double { session.readinessProgress }

    public var readinessText: String { "\(Int(readinessProgress * 100))%" }

    public var summaryText: String {
        let pending = session.availableRecommendations.count
        if pending == 0 {
            return "You have reviewed every prepared action. Your plan is ready to run."
        }
        return "\(pending) prepared \(pending == 1 ? "action needs" : "actions need") your attention."
    }

    public var trendPoints: [TrendPoint] {
        switch selectedPeriod {
        case .today:
            [
                TrendPoint(label: "08", value: 1),
                TrendPoint(label: "10", value: 3),
                TrendPoint(label: "12", value: 2),
                TrendPoint(label: "14", value: 4),
                TrendPoint(label: "16", value: max(2, session.activities.count + 2)),
                TrendPoint(label: "Now", value: max(3, session.visibleSignals.count + session.activities.count)),
            ]
        case .week:
            [
                TrendPoint(label: "Mon", value: 5),
                TrendPoint(label: "Tue", value: 7),
                TrendPoint(label: "Wed", value: 4),
                TrendPoint(label: "Thu", value: 8),
                TrendPoint(label: "Fri", value: 6 + session.activities.count),
                TrendPoint(label: "Sat", value: 3),
                TrendPoint(label: "Sun", value: 4),
            ]
        case .month:
            [
                TrendPoint(label: "W1", value: 14),
                TrendPoint(label: "W2", value: 18),
                TrendPoint(label: "W3", value: 22),
                TrendPoint(label: "W4", value: 19 + session.activities.count),
            ]
        }
    }

    public func load() async {
        await session.prepare()
    }

    private func historicalMetrics(actions: Int, approvalRate: Int, signals: Int, saved: String) -> [Metric] {
        [
            Metric(
                id: "pending",
                value: "\(actions)",
                label: "Actions prepared",
                trend: .up,
                symbolName: "wand.and.stars",
                tint: Color.LifePilot.signalWarning,
                detail: "Recommendations LifePilot prepared during this period before they became "
                    + "manual planning work.",
                actionLabel: "Review current actions"
            ),
            Metric(
                id: "approved",
                value: "\(approvalRate)%",
                label: "Approval rate",
                trend: .up,
                symbolName: "checkmark.circle.fill",
                tint: Color.LifePilot.signalSuccess,
                detail: "The share of prepared actions you chose to approve during this period.",
                actionLabel: "View action history"
            ),
            Metric(
                id: "signals",
                value: "\(signals)",
                label: "Signals connected",
                trend: .up,
                symbolName: "wave.3.right.circle.fill",
                tint: Color.LifePilot.accentEnd,
                detail: "Relevant changes detected across your active sources during this period.",
                actionLabel: "Open unified timeline"
            ),
            Metric(
                id: "saved",
                value: saved,
                label: "Estimated time saved",
                trend: .up,
                symbolName: "clock.badge.checkmark.fill",
                tint: Color.LifePilot.accentAI,
                detail: "Estimated planning and follow-up time avoided through prepared context and approved actions.",
                actionLabel: "See approved actions"
            ),
        ]
    }

    public struct Metric: Identifiable {
        public let id: String
        public let value: String
        public let label: String
        public let trend: InsightCard.Trend?
        public let symbolName: String
        public let tint: Color
        public let detail: String
        public let actionLabel: String
    }

    public struct AgentBreakdown: Identifiable {
        public var id: AgentKind { agent }
        public let agent: AgentKind
        public let count: Int
        public let reviewedCount: Int

        public var progress: Double {
            guard count >= 1 else { return 0 }
            return min(1, Double(reviewedCount) / Double(count))
        }
    }

    public struct TrendPoint: Identifiable {
        public var id: String { label }
        public let label: String
        public let value: Int
    }
}

public enum InsightPeriod: String, CaseIterable, Identifiable {
    case today = "Today"
    case week = "7 days"
    case month = "30 days"

    public var id: String { rawValue }
}
