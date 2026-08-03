import LifePilotDesignSystem
import LifePilotGhostBrain
import SwiftUI

/// Interactive insight centre for readiness, trends, and agent coverage.
public struct InsightsView: View { // swiftlint:disable:this type_body_length
    @State private var viewModel: InsightsViewModel
    @State private var selectedMetric: InsightsViewModel.Metric?
    @State private var selectedAgent: InsightsViewModel.AgentBreakdown?
    private let onReviewApprovals: () -> Void
    private let onOpenTimeline: (TimelineFilter) -> Void

    public init(
        session: DemoSessionStore,
        onReviewApprovals: @escaping () -> Void = {},
        onOpenTimeline: @escaping (TimelineFilter) -> Void = { _ in }
    ) {
        _viewModel = State(initialValue: InsightsViewModel(session: session))
        self.onReviewApprovals = onReviewApprovals
        self.onOpenTimeline = onOpenTimeline
    }

    public init(ghostBrain: GhostBrainServing) {
        self.init(session: DemoSessionStore(ghostBrain: ghostBrain))
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.xl) {
                ScreenHeader(
                    eyebrow: "LifePilot intelligence",
                    title: "Insights",
                    subtitle: "See what was prepared, why it mattered, and where your time came back.",
                    symbolName: "lightbulb.max.fill",
                    status: viewModel.selectedPeriod.rawValue,
                    tint: Color.LifePilot.signalSuccess
                )

                periodControl
                readinessCard
                metricGrid
                trendCard
                agentBreakdown
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.top, Spacing.md)
            .padding(.bottom, Spacing.xl)
        }
        .lifePilotScreenBackground(energy: .prominent)
        .navigationTitle("")
        .task { await viewModel.load() }
        .sheet(item: $selectedMetric) { metric in
            metricSheet(metric)
                .presentationDetents([.medium])
        }
        .sheet(item: $selectedAgent) { item in
            agentSheet(item)
                .presentationDetents([.medium])
        }
    }

    private var periodControl: some View {
        Picker("Insight period", selection: $viewModel.selectedPeriod) {
            ForEach(InsightPeriod.allCases) { period in
                Text(period.rawValue).tag(period)
            }
        }
        .pickerStyle(.segmented)
        .accessibilityIdentifier("insights.period")
    }

    private var readinessCard: some View {
        CardContainer {
            HStack(spacing: Spacing.lg) {
                StatusOrbit(
                    progress: viewModel.readinessProgress,
                    value: viewModel.readinessText,
                    label: "Ready",
                    tint: Color.LifePilot.accentStart,
                    size: 118
                )

                VStack(alignment: .leading, spacing: Spacing.sm) {
                    Label("Day readiness", systemImage: "gauge.with.dots.needle.67percent")
                        .font(.LifePilot.utility)
                        .foregroundStyle(Color.LifePilot.accentStart)

                    Text(viewModel.summaryText)
                        .font(.LifePilot.body.weight(.semibold))
                        .foregroundStyle(Color.LifePilot.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)

                    Button(viewModel.session.availableRecommendations.isEmpty ? "View action history" : "Review now") {
                        if viewModel.session.availableRecommendations.isEmpty {
                            onOpenTimeline(.action)
                        } else {
                            onReviewApprovals()
                        }
                    }
                    .font(.LifePilot.caption.weight(.semibold))
                    .foregroundStyle(Color.LifePilot.accentEnd)
                    .accessibilityIdentifier("insights.review")
                }

                Spacer(minLength: 0)
            }
        }
    }

    private var metricGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: Spacing.sm) {
            ForEach(viewModel.metrics) { metric in
                Button {
                    selectedMetric = metric
                } label: {
                    InsightCard(
                        value: metric.value,
                        label: metric.label,
                        trend: metric.trend,
                        symbolName: metric.symbolName,
                        tint: metric.tint,
                        showsDisclosure: true
                    )
                }
                .buttonStyle(.lifePilotPressable)
                .accessibilityHint("Opens the explanation and next action")
                .accessibilityIdentifier("insights.metric.\(metric.id)")
            }
        }
    }

    private var trendCard: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            SectionHeader(title: "Prepared activity", symbolName: "chart.bar.fill")

            CardContainer {
                VStack(alignment: .leading, spacing: Spacing.md) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Signals connected over time")
                                .font(.LifePilot.body.weight(.semibold))
                                .foregroundStyle(Color.LifePilot.textPrimary)
                            Text("Tap a metric above to understand the outcome.")
                                .font(.LifePilot.caption)
                                .foregroundStyle(Color.LifePilot.textSecondary)
                        }
                        Spacer()
                        Text(viewModel.selectedPeriod.rawValue)
                            .font(.LifePilot.utility)
                            .foregroundStyle(Color.LifePilot.accentStart)
                            .padding(.horizontal, Spacing.sm)
                            .padding(.vertical, Spacing.xs)
                            .background(Color.LifePilot.accentStart.opacity(0.12), in: Capsule())
                    }

                    trendBars
                }
            }
        }
    }

    private var trendBars: some View {
        let maximum = max(viewModel.trendPoints.map(\.value).max() ?? 1, 1)
        return HStack(alignment: .bottom, spacing: Spacing.sm) {
            ForEach(viewModel.trendPoints) { point in
                VStack(spacing: Spacing.xs) {
                    Text("\(point.value)")
                        .font(.system(.caption2, design: .rounded, weight: .semibold).monospacedDigit())
                        .foregroundStyle(Color.LifePilot.textSecondary)

                    Capsule()
                        .fill(Color.LifePilot.accentStart.opacity(0.82))
                        .frame(height: max(18, CGFloat(point.value) / CGFloat(maximum) * 96))

                    Text(point.label)
                        .font(.system(.caption2, design: .rounded, weight: .medium))
                        .foregroundStyle(Color.LifePilot.textTertiary)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("\(point.label), \(point.value) connected signals")
            }
        }
        .frame(height: 140, alignment: .bottom)
    }

    @ViewBuilder
    private var agentBreakdown: some View {
        if !viewModel.breakdown.isEmpty {
            VStack(alignment: .leading, spacing: Spacing.md) {
                SectionHeader(title: "Agent coverage", symbolName: "square.grid.2x2.fill")

                CardContainer {
                    VStack(spacing: 0) {
                        ForEach(Array(viewModel.breakdown.enumerated()), id: \.element.id) { index, item in
                            Button {
                                selectedAgent = item
                            } label: {
                                HStack(spacing: Spacing.md) {
                                    AgentAvatar(agent: item.agent, size: 38)

                                    VStack(alignment: .leading, spacing: Spacing.xs) {
                                        HStack {
                                            Text(item.agent.displayName)
                                                .font(.LifePilot.body.weight(.semibold))
                                                .foregroundStyle(Color.LifePilot.textPrimary)
                                            Spacer()
                                            Text("\(item.reviewedCount)/\(item.count) reviewed")
                                                .font(.LifePilot.utility)
                                                .foregroundStyle(Color.LifePilot.textSecondary)
                                        }

                                        ProgressView(value: item.progress)
                                            .tint(Color.LifePilot.accentStart)
                                    }

                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundStyle(Color.LifePilot.textTertiary)
                                }
                                .frame(minHeight: 58)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.lifePilotPressable)
                            .accessibilityIdentifier("insights.agent.\(item.agent.rawValue)")

                            if index < viewModel.breakdown.count - 1 {
                                Divider().overlay(Color.LifePilot.glassBorder)
                            }
                        }
                    }
                }
            }
        }
    }

    private func metricSheet(_ metric: InsightsViewModel.Metric) -> some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                HStack {
                    Image(systemName: metric.symbolName)
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundStyle(metric.tint)
                        .frame(width: 52, height: 52)
                        .background(metric.tint.opacity(0.14), in: Circle())
                    Spacer()
                    Text(metric.value)
                        .font(.LifePilot.metric)
                        .foregroundStyle(Color.LifePilot.textPrimary)
                }

                VStack(alignment: .leading, spacing: Spacing.sm) {
                    Text(metric.label)
                        .font(.LifePilot.titleMedium)
                        .foregroundStyle(Color.LifePilot.textPrimary)
                    Text(metric.detail)
                        .font(.LifePilot.body)
                        .foregroundStyle(Color.LifePilot.textSecondary)
                }

                Spacer()

                Button(metric.actionLabel) {
                    selectedMetric = nil
                    performAction(for: metric.id)
                }
                .buttonStyle(.lifePilotPrimary)
                .accessibilityIdentifier("insights.metric.action")
            }
            .padding(Spacing.lg)
            .lifePilotScreenBackground(energy: .subtle)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { selectedMetric = nil }
                }
            }
        }
    }

    private func agentSheet(_ item: InsightsViewModel.AgentBreakdown) -> some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                HStack(spacing: Spacing.md) {
                    AgentAvatar(agent: item.agent, size: 54)
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        Text("\(item.agent.displayName) agent")
                            .font(.LifePilot.titleMedium)
                            .foregroundStyle(Color.LifePilot.textPrimary)
                        Text("\(item.reviewedCount) of \(item.count) prepared outputs reviewed")
                            .font(.LifePilot.caption)
                            .foregroundStyle(Color.LifePilot.textSecondary)
                    }
                }

                ProgressView(value: item.progress)
                    .tint(Color.LifePilot.accentStart)

                Text(agentExplanation(item.agent.rawValue))
                    .font(.LifePilot.body)
                    .foregroundStyle(Color.LifePilot.textSecondary)

                Spacer()

                Button("Open related timeline") {
                    selectedAgent = nil
                    onOpenTimeline(timelineFilter(for: item.agent.rawValue))
                }
                .buttonStyle(.lifePilotPrimary)
                .accessibilityIdentifier("insights.agent.action")
            }
            .padding(Spacing.lg)
            .lifePilotScreenBackground(energy: .subtle)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { selectedAgent = nil }
                }
            }
        }
    }

    private func performAction(for metricID: String) {
        switch metricID {
        case "pending":
            if viewModel.session.availableRecommendations.isEmpty {
                onOpenTimeline(.action)
            } else {
                onReviewApprovals()
            }
        case "approved", "saved": onOpenTimeline(.action)
        default: onOpenTimeline(.all)
        }
    }

    private func timelineFilter(for agent: String) -> TimelineFilter {
        switch agent {
        case "calendar": .calendar
        case "email": .email
        case "travel": .travel
        default: .all
        }
    }

    private func agentExplanation(_ agent: String) -> String {
        switch agent {
        case "calendar": "Finds timetable conflicts and protects the time you need to move between classes and events."
        case "email": "Surfaces messages that need a reply and prepares the context before you open your inbox."
        case "travel": "Connects UK travel disruption with the rest of your day so delays are visible early."
        case "finance": "Flags unusual spending and upcoming renewals without moving money or changing accounts."
        default: "Connects useful context to your daily briefing while keeping every action under your control."
        }
    }
}

#Preview {
    NavigationStack {
        InsightsView(ghostBrain: MockRecommendationProvider())
    }
}
