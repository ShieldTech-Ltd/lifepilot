import LifePilotDesignSystem
import LifePilotGhostBrain
import SwiftUI

/// The Insights tab — a snapshot of how much Ghost Brain is catching
/// today, per README.md's Insights feature description. Backed by
/// `InsightsViewModel`, which reads the same `GhostBrainServing` model
/// `HomeView` does, so these numbers always agree with what's on Home.
public struct InsightsView: View {
    @State private var viewModel: InsightsViewModel

    public init(session: DemoSessionStore) {
        _viewModel = State(initialValue: InsightsViewModel(session: session))
    }

    public init(ghostBrain: GhostBrainServing) {
        self.init(session: DemoSessionStore(ghostBrain: ghostBrain))
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.xl) {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text("Today's Snapshot")
                        .font(.LifePilot.titleLarge)
                        .foregroundStyle(Color.LifePilot.textPrimary)

                    Text("A running read on how much Ghost Brain is catching before it becomes your problem.")
                        .font(.LifePilot.body)
                        .foregroundStyle(Color.LifePilot.textSecondary)
                }

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: Spacing.sm) {
                    ForEach(viewModel.metrics) { metric in
                        InsightCard(value: metric.value, label: metric.label, trend: metric.trend)
                    }
                }

                if !viewModel.breakdown.isEmpty {
                    VStack(alignment: .leading, spacing: Spacing.md) {
                        SectionHeader(title: "By Agent", symbolName: "square.grid.2x2")

                        CardContainer {
                            VStack(spacing: 0) {
                                ForEach(viewModel.breakdown) { item in
                                    HStack(spacing: Spacing.md) {
                                        AgentAvatar(agent: item.agent, size: 24)

                                        Text(item.agent.displayName)
                                            .font(.LifePilot.body)
                                            .foregroundStyle(Color.LifePilot.textPrimary)

                                        Spacer()

                                        Text("\(item.count)")
                                            .font(.LifePilot.caption.weight(.semibold))
                                            .foregroundStyle(Color.LifePilot.textSecondary)
                                    }
                                    .padding(.vertical, Spacing.sm)
                                }
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.top, Spacing.md)
            .padding(.bottom, Spacing.xl)
        }
        .background(Color.LifePilot.backgroundPrimary)
        .navigationTitle("Insights")
        .task { await viewModel.load() }
    }
}

#Preview {
    NavigationStack {
        InsightsView(ghostBrain: MockRecommendationProvider())
    }
}
