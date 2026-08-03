import LifePilotCore
import LifePilotDesignSystem
import LifePilotGhostBrain
import SwiftUI

/// The Morning Briefing: explained recommendations, connected-source
/// signals, schedule, working quick actions, and shared approval history.
public struct HomeView: View { // swiftlint:disable:this type_body_length
    @State private var viewModel: HomeViewModel
    @State private var selectedRecommendation: BriefingCard.Content?
    @State private var selectedEvent: CalendarEvent?
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    private let onOpenTimeline: (TimelineFilter) -> Void

    public init(session: DemoSessionStore, onOpenTimeline: @escaping (TimelineFilter) -> Void = { _ in }) {
        _viewModel = State(initialValue: HomeViewModel(session: session))
        self.onOpenTimeline = onOpenTimeline
    }

    public init(ghostBrain: GhostBrainServing) {
        self.init(session: DemoSessionStore(ghostBrain: ghostBrain))
    }

    public var body: some View { // swiftlint:disable:this function_body_length
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.xl + Spacing.xs) {
                primaryHeader
                nextEventSection
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
        .lifePilotScreenBackground(energy: .prominent)
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
        .sheet(item: $selectedEvent) { event in
            eventPreview(event)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
    }

    // MARK: - Hero Header

    private var primaryHeader: some View {
        ScreenHeader(
            eyebrow: "Your day",
            title: viewModel.dateText.isEmpty ? "Preparing today" : viewModel.dateText,
            subtitle: viewModel.profileContextText,
            imageName: "LifePilotLogo",
            status: viewModel.eventsAhead.isEmpty ? "Clear" : "\(viewModel.eventsAhead.count) ahead",
            tint: Color.LifePilot.accentStart
        )
    }

    // MARK: - Next Event

    @ViewBuilder
    private var nextEventSection: some View {
        if let event = viewModel.nextEvent {
            Button {
                selectedEvent = event
            } label: {
                CardContainer {
                    VStack(alignment: .leading, spacing: Spacing.md) {
                        HStack(alignment: .top, spacing: Spacing.md) {
                            VStack(alignment: .leading, spacing: Spacing.xs) {
                                Label("NEXT TO ATTEND", systemImage: "location.fill")
                                    .font(.LifePilot.utility)
                                    .foregroundStyle(Color.LifePilot.accentStart)

                                Text(event.title)
                                    .font(.LifePilot.titleMedium)
                                    .foregroundStyle(Color.LifePilot.textPrimary)
                                    .multilineTextAlignment(.leading)

                                if let location = event.location, !location.isEmpty {
                                    Text(location)
                                        .font(.LifePilot.caption)
                                        .foregroundStyle(Color.LifePilot.textSecondary)
                                        .multilineTextAlignment(.leading)
                                }
                            }

                            Spacer(minLength: Spacing.sm)

                            VStack(spacing: 2) {
                                Text(eventDayLabel(event.startDate).uppercased())
                                    .font(.system(.caption2, design: .rounded, weight: .bold))
                                    .foregroundStyle(Color.LifePilot.accentEnd)
                                Text(event.startDate.formatted(date: .omitted, time: .shortened))
                                    .font(.system(.title3, design: .rounded, weight: .bold).monospacedDigit())
                                    .foregroundStyle(Color.LifePilot.textPrimary)
                            }
                            .padding(.horizontal, Spacing.sm)
                            .padding(.vertical, Spacing.sm)
                            .background(
                                Color.LifePilot.selectionFill,
                                in: RoundedRectangle(cornerRadius: CornerRadius.md)
                            )
                        }

                        HStack {
                            Label(eventDurationLabel(event), systemImage: "clock")
                            Spacer()
                            Label("View details", systemImage: "chevron.right")
                        }
                        .font(.LifePilot.caption)
                        .foregroundStyle(Color.LifePilot.textSecondary)
                    }
                }
            }
            .buttonStyle(.lifePilotPressable)
            .accessibilityHint("Opens this event's details")
            .accessibilityIdentifier("home.nextEvent")
        } else {
            EmptyStateView(
                symbolName: "calendar.badge.checkmark",
                message: "No more events need your attention today. Import a screenshot or invitation to add one."
            )
        }
    }

    private var heroHeader: some View {
        CardContainer {
            VStack(alignment: .leading, spacing: Spacing.md) {
                if dynamicTypeSize.isAccessibilitySize {
                    VStack(alignment: .leading, spacing: Spacing.md) {
                        greetingCopy
                        readinessOrbit
                    }
                } else {
                    HStack(spacing: Spacing.md) {
                        greetingCopy
                        Spacer(minLength: 0)
                        readinessOrbit
                    }
                }

                if dynamicTypeSize.isAccessibilitySize {
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        reviewSummary
                        sourceSummary
                    }
                } else {
                    HStack(spacing: Spacing.sm) {
                        reviewSummary
                        sourceSummary
                    }
                }
            }
        }
        .accessibilityElement(children: .combine)
    }

    private var greetingCopy: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text(viewModel.greeting.isEmpty ? "Good morning" : viewModel.greeting)
                .font(.LifePilot.titleLarge)
                .foregroundStyle(Color.LifePilot.textPrimary)

            Text(daySummary)
                .font(.LifePilot.body)
                .foregroundStyle(Color.LifePilot.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var readinessOrbit: some View {
        StatusOrbit(
            progress: viewModel.readinessProgress,
            value: viewModel.readinessText,
            label: "Ready",
            tint: Color.LifePilot.accentStart,
            size: 102
        )
    }

    private var reviewSummary: some View {
        summaryPill(
            symbol: "checkmark.shield.fill",
            text: "\(viewModel.pendingCount) to review",
            color: viewModel.pendingCount == 0
                ? Color.LifePilot.signalSuccess
                : Color.LifePilot.signalWarning
        )
    }

    private var sourceSummary: some View {
        summaryPill(
            symbol: "link",
            text: "\(viewModel.connectedSourceCount) sources",
            color: Color.LifePilot.accentEnd
        )
    }

    private var daySummary: String {
        if viewModel.pendingCount == 0 {
            return "Your plan is clear. Every prepared action has been reviewed."
        }
        return "Your student day is organised. Review the last \(viewModel.pendingCount) prepared actions."
    }

    private func summaryPill(symbol: String, text: String, color: Color) -> some View {
        Label(text, systemImage: symbol)
            .font(.LifePilot.utility)
            .foregroundStyle(color)
            .padding(.horizontal, Spacing.sm)
            .padding(.vertical, Spacing.xs + 2)
            .background(color.opacity(0.11), in: Capsule())
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
                        .buttonStyle(.lifePilotPressable)
                        .accessibilityHint("Opens approval details")
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
            SectionHeader(title: "Later in your agenda", symbolName: "calendar")

            if viewModel.laterEvents.isEmpty {
                EmptyStateView(symbolName: "calendar", message: "Nothing is scheduled after your next event.")
            } else {
                CardContainer {
                    VStack(spacing: 0) {
                        ForEach(viewModel.laterEvents) { event in
                            TimelineRow(content: .init(
                                time: eventTimeLabel(event.startDate),
                                title: event.title,
                                subtitle: event.location
                            ))
                        }
                    }
                }
            }
        }
    }

    private func eventTimeLabel(_ date: Date) -> String {
        if Calendar.current.isDateInToday(date) {
            return date.formatted(date: .omitted, time: .shortened)
        }
        return date.formatted(.dateTime.day().month(.abbreviated).hour().minute())
    }

    private func eventDayLabel(_ date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            return "Today"
        }
        if calendar.isDateInTomorrow(date) {
            return "Tomorrow"
        }
        return date.formatted(.dateTime.weekday(.abbreviated).day())
    }

    private func eventDurationLabel(_ event: CalendarEvent) -> String {
        let start = event.startDate.formatted(date: .omitted, time: .shortened)
        let end = event.endDate.formatted(date: .omitted, time: .shortened)
        return "\(start) to \(end)"
    }

    private func eventPreview(_ event: CalendarEvent) -> some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.lg) {
                    HStack(alignment: .top, spacing: Spacing.md) {
                        Image(systemName: "calendar.badge.clock")
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundStyle(Color.LifePilot.accentStart)
                            .frame(width: 52, height: 52)
                            .background(Color.LifePilot.accentStart.opacity(0.13), in: Circle())

                        VStack(alignment: .leading, spacing: Spacing.xs) {
                            Text("NEXT TO ATTEND")
                                .font(.LifePilot.utility)
                                .foregroundStyle(Color.LifePilot.accentStart)

                            Text(event.title)
                                .font(.LifePilot.titleLarge)
                                .foregroundStyle(Color.LifePilot.textPrimary)
                        }
                    }

                    CardContainer {
                        VStack(spacing: 0) {
                            eventDetailRow(
                                symbol: "calendar",
                                label: "Date",
                                value: event.startDate.formatted(.dateTime.weekday(.wide).day().month(.wide).year())
                            )

                            Divider().overlay(Color.LifePilot.glassBorder)

                            eventDetailRow(
                                symbol: "clock",
                                label: "Time",
                                value: eventDurationLabel(event)
                            )

                            Divider().overlay(Color.LifePilot.glassBorder)

                            eventDetailRow(
                                symbol: "location.fill",
                                label: "Location",
                                value: event.location.flatMap { $0.isEmpty ? nil : $0 } ?? "Location not provided"
                            )

                            if event.attendeeCount > 0 {
                                Divider().overlay(Color.LifePilot.glassBorder)

                                eventDetailRow(
                                    symbol: "person.2.fill",
                                    label: "Attendees",
                                    value: "\(event.attendeeCount) invited"
                                )
                            }
                        }
                    }

                    Label("LifePilot will keep this event visible as it approaches.", systemImage: "bell.badge.fill")
                        .font(.LifePilot.caption)
                        .foregroundStyle(Color.LifePilot.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(Spacing.lg)
            }
            .lifePilotScreenBackground(energy: .subtle)
            .navigationTitle("Event preview")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { selectedEvent = nil }
                }
            }
        }
    }

    private func eventDetailRow(symbol: String, label: String, value: String) -> some View {
        HStack(alignment: .top, spacing: Spacing.md) {
            Image(systemName: symbol)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Color.LifePilot.accentStart)
                .frame(width: 28, height: 28)
                .background(Color.LifePilot.accentStart.opacity(0.10), in: Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.LifePilot.utility)
                    .foregroundStyle(Color.LifePilot.textSecondary)
                Text(value)
                    .font(.LifePilot.body.weight(.semibold))
                    .foregroundStyle(Color.LifePilot.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(.vertical, Spacing.sm)
    }

    // MARK: - Quick Actions

    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            SectionHeader(title: "Quick Actions", symbolName: "bolt.fill")

            Group {
                if dynamicTypeSize.isAccessibilitySize {
                    VStack(spacing: Spacing.sm) {
                        quickActions
                    }
                } else {
                    HStack(spacing: Spacing.sm) {
                        quickActions
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var quickActions: some View {
        QuickActionCard(
            symbolName: "envelope.fill",
            title: "Inbox",
            tint: Color.LifePilot.accentAI
        ) {
            onOpenTimeline(.email)
        }
        QuickActionCard(
            symbolName: "checklist",
            title: "Tasks",
            tint: Color.LifePilot.accentEnd
        ) {
            onOpenTimeline(.task)
        }
        QuickActionCard(
            symbolName: "tram.fill",
            title: "Travel",
            tint: Color.LifePilot.accentStart
        ) {
            onOpenTimeline(.travel)
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
} // swiftlint:disable:this file_length
