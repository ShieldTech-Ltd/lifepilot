import LifePilotDesignSystem
import LifePilotGhostBrain
import SwiftUI

/// The Morning Briefing: explained recommendations, connected-source
/// signals, schedule, working quick actions, and shared approval history.
public struct HomeView: View {
    @State private var viewModel: HomeViewModel
    @State private var selectedRecommendation: BriefingCard.Content?
    private let onOpenTimeline: (TimelineFilter) -> Void

    public init(session: DemoSessionStore, onOpenTimeline: @escaping (TimelineFilter) -> Void = { _ in }) {
        _viewModel = State(initialValue: HomeViewModel(session: session))
        self.onOpenTimeline = onOpenTimeline
    }

    public init(ghostBrain: GhostBrainServing) {
        self.init(session: DemoSessionStore(ghostBrain: ghostBrain))
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.xl) {
                heroHeader
                ghostBrainSection
                signalsSection
                upcomingScheduleSection
                quickActionsSection
                recentActivitySection
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.top, Spacing.md)
            .padding(.bottom, Spacing.xl)
        }
        .background(Color.LifePilot.backgroundPrimary)
        .task { await viewModel.load() }
        .sheet(item: $selectedRecommendation) { content in
            ApprovalSheet(
                content: .init(
                    title: content.title,
                    reasoning: content.reasoning,
                    sourceName: content.sourceAgent.displayName,
                    sourceSymbolName: content.sourceAgent.symbolName,
                    riskText: content.riskBadgeText.map { "\($0) risk" } ?? "Low risk"
                ),
                onApprove: {
                    viewModel.approve(content)
                    selectedRecommendation = nil
                },
                onDismiss: {
                    viewModel.dismiss(content)
                    selectedRecommendation = nil
                }
            )
            .presentationDetents([.medium, .large])
        }
    }

    // MARK: - Hero Header

    private var heroHeader: some View {
        HStack(spacing: Spacing.md) {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(viewModel.dateText.isEmpty ? " " : viewModel.dateText)
                    .font(.LifePilot.caption)
                    .foregroundStyle(Color.LifePilot.textSecondary)

                Text(viewModel.greeting.isEmpty ? "Good morning" : viewModel.greeting)
                    .font(.LifePilot.titleLarge)
                    .foregroundStyle(Color.LifePilot.textPrimary)

                Text(viewModel.profileContextText)
                    .font(.LifePilot.caption)
                    .foregroundStyle(Color.LifePilot.textSecondary)
            }

            Spacer(minLength: Spacing.sm)

            ProfileAvatarView(
                imageData: viewModel.profileImageData,
                displayName: viewModel.displayName,
                size: 52
            )
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }

    // MARK: - Ghost Brain

    private var ghostBrainSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            SectionHeader(title: "Prepared for you", symbolName: "sparkle")

            if let loadErrorMessage = viewModel.loadErrorMessage {
                CardContainer {
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        Text(loadErrorMessage)
                            .font(.LifePilot.body)
                            .foregroundStyle(Color.LifePilot.textPrimary)
                        Button("Try again") {
                            Task { await viewModel.retry() }
                        }
                        .buttonStyle(.lifePilotSecondary)
                    }
                }
            } else if viewModel.isLoading || !viewModel.isPrepared {
                EmptyStateView(
                    symbolName: "sparkle",
                    message: "Ghost Brain is preparing your recommendations."
                )
            } else if viewModel.recommendations.isEmpty {
                CardContainer {
                    HStack(spacing: Spacing.md) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: IconSize.lg))
                            .foregroundStyle(Color.LifePilot.signalSuccess)

                        VStack(alignment: .leading, spacing: Spacing.xs) {
                            Text("You're all caught up")
                                .font(.LifePilot.titleMedium)
                                .foregroundStyle(Color.LifePilot.textPrimary)
                            Text("Every recommendation has been reviewed. Your decisions are saved in Actions.")
                                .font(.LifePilot.caption)
                                .foregroundStyle(Color.LifePilot.textSecondary)
                        }
                    }
                }
            } else {
                VStack(spacing: Spacing.sm) {
                    ForEach(viewModel.recommendations) { content in
                        Button {
                            selectedRecommendation = content
                        } label: {
                            BriefingCard(content: content)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    // MARK: - Signals

    @ViewBuilder
    private var signalsSection: some View {
        if !viewModel.signals.isEmpty {
            VStack(alignment: .leading, spacing: Spacing.md) {
                SectionHeader(title: "Also Noticed", symbolName: "eye")

                VStack(spacing: Spacing.sm) {
                    ForEach(viewModel.signals) { signal in
                        GhostCard(title: signal.title, subtitle: signal.subtitle)
                    }
                }
            }
        }
    }

    // MARK: - Upcoming Schedule

    private var upcomingScheduleSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            SectionHeader(title: "Upcoming Schedule", symbolName: "calendar")

            if viewModel.upcomingEvents.isEmpty {
                EmptyStateView(symbolName: "calendar", message: "Nothing else on your calendar today.")
            } else {
                CardContainer {
                    VStack(spacing: 0) {
                        ForEach(viewModel.upcomingEvents) { event in
                            TimelineRow(content: .init(
                                time: event.startDate.formatted(date: .omitted, time: .shortened),
                                title: event.title,
                                subtitle: event.location
                            ))
                        }
                    }
                }
            }
        }
    }

    // MARK: - Quick Actions

    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            SectionHeader(title: "Quick Actions", symbolName: "bolt.fill")

            HStack(spacing: Spacing.sm) {
                QuickActionCard(symbolName: "envelope.fill", title: "Inbox") {
                    onOpenTimeline(.email)
                }
                QuickActionCard(symbolName: "checklist", title: "Tasks") {
                    onOpenTimeline(.task)
                }
                QuickActionCard(symbolName: "airplane", title: "Travel") {
                    onOpenTimeline(.travel)
                }
            }
        }
    }

    // MARK: - Recent Activity

    private var recentActivitySection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            SectionHeader(title: "Recent Activity", symbolName: "clock.arrow.circlepath")

            if viewModel.recentActivity.isEmpty {
                EmptyStateView(
                    symbolName: "clock.arrow.circlepath",
                    message: "Approved and dismissed actions will appear here."
                )
            } else {
                CardContainer {
                    VStack(spacing: 0) {
                        ForEach(viewModel.recentActivity) { entry in
                            TimelineRow(content: .init(
                                time: entry.resolvedAt.formatted(date: .omitted, time: .shortened),
                                title: entry.title,
                                subtitle: entry.result,
                                accentColor: entry.wasApproved
                                    ? Color.LifePilot.signalSuccess
                                    : Color.LifePilot.textSecondary
                            ))
                        }
                    }
                }

                Button("View all actions") {
                    onOpenTimeline(.action)
                }
                .buttonStyle(.lifePilotSecondary)
            }
        }
    }
}

#Preview {
    HomeView(ghostBrain: MockRecommendationProvider())
}
