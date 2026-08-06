import LifePilotCore
import LifePilotDesignSystem
import SwiftUI

public struct LiveExperiencesView: View {
    private let session: DemoSessionStore
    @State private var manager = LiveActivityManager()
    @State private var didRefreshWidgets = false

    public init(session: DemoSessionStore) {
        self.session = session
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.xl) {
                ScreenHeader(
                    eyebrow: "Beyond the app",
                    title: "Live Experiences",
                    subtitle: "Keep the next useful moment visible without opening LifePilot."
                )

                dynamicIslandSection
                widgetSection
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.vertical, Spacing.md)
        }
        .lifePilotScreenBackground(energy: .prominent)
        .navigationTitle("Live Experiences")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .onAppear { manager.refreshState() }
    }

    private var dynamicIslandSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            SectionHeader(title: "Dynamic Island", symbolName: "capsule.fill")

            CardContainer {
                VStack(spacing: Spacing.lg) {
                    dynamicIslandPreview

                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        Text(manager.isActive ? "Live Activity running" : "See your next priority at a glance")
                            .font(.LifePilot.body.weight(.semibold))
                            .foregroundStyle(Color.LifePilot.textPrimary)
                        Text(
                            "The demo keeps \(nextEvent?.title ?? "your next priority") visible on the Lock Screen "
                                + "and Dynamic Island."
                        )
                            .font(.LifePilot.caption)
                            .foregroundStyle(Color.LifePilot.textSecondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    if manager.isActive {
                        Button("End Live Activity") {
                            Task { await manager.end() }
                        }
                        .buttonStyle(.lifePilotSecondary)
                        .accessibilityIdentifier("liveActivity.end")
                    } else {
                        Button("Start Dynamic Island demo") {
                            manager.start(
                                userName: session.firstName,
                                nextItem: nextEvent?.title ?? "Day ready",
                                detail: nextEventDetail,
                                progress: session.readinessProgress
                            )
                        }
                        .buttonStyle(.lifePilotPrimary)
                        .accessibilityIdentifier("liveActivity.start")
                    }

                    if let errorMessage = manager.errorMessage {
                        Label(errorMessage, systemImage: "exclamationmark.circle.fill")
                            .font(.LifePilot.caption)
                            .foregroundStyle(Color.LifePilot.signalRisk)
                    }
                }
            }
        }
    }

    private var dynamicIslandPreview: some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: "sparkles")
                .foregroundStyle(Color.LifePilot.accentStart)
            VStack(alignment: .leading, spacing: 2) {
                Text(nextEvent?.title ?? "Day ready")
                    .font(.system(.caption, design: .rounded, weight: .semibold))
                Text(nextEventTime)
                    .font(.system(.caption2, design: .rounded).monospacedDigit())
                    .foregroundStyle(.white.opacity(0.66))
            }
            Spacer()
            Text("\(readinessPercent)%")
                .font(.system(.caption, design: .rounded, weight: .bold).monospacedDigit())
        }
        .foregroundStyle(.white)
        .padding(.horizontal, Spacing.md)
        .frame(maxWidth: 260, minHeight: 58)
        .background(Color.black, in: Capsule())
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            "Dynamic Island preview, \(nextEvent?.title ?? "day ready") at \(nextEventTime), "
                + "day \(readinessPercent) percent ready"
        )
    }

    private var widgetSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            SectionHeader(title: "Home Screen widgets", symbolName: "square.grid.2x2.fill")

            HStack(alignment: .top, spacing: Spacing.sm) {
                widgetPreview(
                    title: "Next",
                    value: nextEventTime,
                    detail: nextEvent?.title ?? "Day ready",
                    wide: false
                )
                widgetPreview(
                    title: "Today",
                    value: "\(readinessPercent)% ready",
                    detail: pendingActionsText,
                    wide: true
                )
            }

            CardContainer {
                VStack(alignment: .leading, spacing: Spacing.md) {
                    Label("Add the LifePilot widget", systemImage: "plus.rectangle.on.rectangle")
                        .font(.LifePilot.body.weight(.semibold))
                        .foregroundStyle(Color.LifePilot.textPrimary)

                    Text("Touch and hold the Home Screen, tap Edit, choose Add Widget, then search for LifePilot.")
                        .font(.LifePilot.caption)
                        .foregroundStyle(Color.LifePilot.textSecondary)

                    Button(didRefreshWidgets ? "Widgets refreshed" : "Refresh widget data") {
                        session.refreshLiveExperiences()
                        manager.refreshWidgets()
                        didRefreshWidgets = true
                    }
                    .buttonStyle(.lifePilotSecondary)
                    .accessibilityIdentifier("widgets.refresh")
                }
            }
        }
    }

    private var nextEvent: CalendarEvent? {
        session.visibleEvents
            .filter { $0.endDate > Date() }
            .min { $0.startDate < $1.startDate }
    }

    private var nextEventTime: String {
        nextEvent?.startDate.formatted(date: .omitted, time: .shortened) ?? "Ready"
    }

    private var nextEventDetail: String {
        guard let nextEvent else { return "Every prepared action is up to date" }
        let location = nextEvent.location.flatMap { $0.isEmpty ? nil : $0 } ?? "LifePilot schedule"
        return "\(location) · \(nextEventTime)"
    }

    private var readinessPercent: Int { Int(session.readinessProgress * 100) }

    private var pendingActionsText: String {
        let count = session.availableRecommendations.count
        return count == 1 ? "1 action to review" : "\(count) actions to review"
    }

    private func widgetPreview(title: String, value: String, detail: String, wide: Bool) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Image(systemName: "sparkles")
                .foregroundStyle(Color.LifePilot.accentStart)
            Spacer()
            Text(title.uppercased())
                .font(.LifePilot.utility)
                .foregroundStyle(Color.LifePilot.textSecondary)
            Text(value)
                .font(.system(.title3, design: .rounded, weight: .bold))
                .foregroundStyle(Color.LifePilot.textPrimary)
            Text(detail)
                .font(.LifePilot.caption)
                .foregroundStyle(Color.LifePilot.textSecondary)
                .lineLimit(1)
        }
        .padding(Spacing.md)
        .frame(maxWidth: wide ? .infinity : 132, minHeight: 150, alignment: .leading)
        .lifePilotGlass(cornerRadius: 24)
    }
}

#Preview {
    NavigationStack {
        LiveExperiencesView(session: DemoSessionStore())
    }
}
