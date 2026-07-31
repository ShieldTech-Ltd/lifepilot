import LifePilotDesignSystem
import SwiftUI

/// The Timeline screen — a unified, chronological view of everything
/// happening across connected apps, per README.md's Timeline feature.
public struct TimelineView: View {
    @State private var viewModel: TimelineViewModel

    public init(session: DemoSessionStore) {
        _viewModel = State(initialValue: TimelineViewModel(session: session))
    }

    public init() {
        self.init(session: DemoSessionStore())
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.md) {
                filterBar

                if viewModel.entries.isEmpty {
                    EmptyStateView(
                        symbolName: "line.3.horizontal.decrease.circle",
                        message: "Nothing matches this view. Choose another source or reconnect it in Settings."
                    )
                } else {
                    LazyVStack(spacing: 0) {
                        ForEach(viewModel.entries) { entry in
                            TimelineRow(content: .init(
                                time: entry.date.formatted(date: .omitted, time: .shortened),
                                title: entry.title,
                                subtitle: entry.subtitle,
                                accentColor: color(for: entry.kind)
                            ))
                        }
                    }
                }
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.top, Spacing.md)
        }
        .background(Color.LifePilot.backgroundPrimary)
        .navigationTitle("Timeline")
        .task { await viewModel.load() }
    }

    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Spacing.sm) {
                ForEach(TimelineFilter.allCases) { filter in
                    Button(filter.rawValue) {
                        viewModel.selectedFilter = filter
                    }
                    .font(.LifePilot.caption.weight(.semibold))
                    .foregroundStyle(viewModel.selectedFilter == filter ? .white : Color.LifePilot.textPrimary)
                    .padding(.horizontal, Spacing.md)
                    .padding(.vertical, Spacing.sm)
                    .background {
                        Capsule()
                            .fill(viewModel.selectedFilter == filter
                                ? Color.LifePilot.accentEnd
                                : Color.LifePilot.backgroundElevated)
                    }
                    .accessibilityIdentifier("timeline.filter.\(filter.rawValue.lowercased())")
                }
            }
        }
    }

    private func color(for kind: TimelineEntry.Kind) -> Color {
        switch kind {
        case .event: return Color.LifePilot.accentStart
        case .email: return Color.LifePilot.accentEnd
        case .task: return Color.LifePilot.signalSuccess
        case .travel: return Color.LifePilot.signalRisk
        case .action: return Color.LifePilot.signalSuccess
        }
    }
}

#Preview {
    NavigationStack {
        TimelineView()
    }
}
