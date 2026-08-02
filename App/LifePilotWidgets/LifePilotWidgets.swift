import ActivityKit
import LifePilotFeatures
import SwiftUI
import WidgetKit

@main
struct LifePilotWidgetBundle: WidgetBundle {
    var body: some Widget {
        LifePilotBriefingWidget()
        LifePilotLiveActivity()
    }
}

private struct BriefingEntry: WidgetKit.TimelineEntry {
    let date: Date
    let readiness: Int
    let pendingActions: Int
    let nextTitle: String
    let nextTime: String
    let nextLocation: String
    let nextDate: Date
}

private struct BriefingProvider: TimelineProvider {
    func placeholder(in context: Context) -> BriefingEntry {
        entry
    }

    func getSnapshot(in context: Context, completion: @escaping (BriefingEntry) -> Void) {
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<BriefingEntry>) -> Void) {
        let nextRefresh = min(entry.nextDate.addingTimeInterval(60), Date().addingTimeInterval(60 * 30))
        completion(Timeline(entries: [entry], policy: .after(nextRefresh)))
    }

    private var entry: BriefingEntry {
        let fallbackDate = Calendar.current.date(from: DateComponents(
            year: 2026, month: 8, day: 3, hour: 13, minute: 30
        )) ?? Date().addingTimeInterval(3600)
        let nextEvent = UpcomingEventWidgetStore.load()
        return BriefingEntry(
            date: Date(),
            readiness: nextEvent?.readiness ?? 70,
            pendingActions: nextEvent?.pendingActions ?? 3,
            nextTitle: nextEvent?.title ?? "TechFest 2026 Showcase",
            nextTime: (nextEvent?.startDate ?? fallbackDate).formatted(date: .omitted, time: .shortened),
            nextLocation: nextEvent?.location ?? "International House",
            nextDate: nextEvent?.startDate ?? fallbackDate
        )
    }
}

private struct LifePilotBriefingWidget: Widget {
    let kind = "LifePilotBriefingWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: BriefingProvider()) { entry in
            BriefingWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("LifePilot Briefing")
        .description("See day readiness, actions, and the next important moment.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

private struct BriefingWidgetView: View {
    let entry: BriefingEntry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        if family == .systemSmall {
            smallView
        } else {
            mediumView
        }
    }

    private var smallView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("LifePilot", systemImage: "sparkles")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.teal)
            Spacer()
            Text("UP NEXT")
                .font(.caption2.weight(.bold))
                .foregroundStyle(.secondary)
            Text(entry.nextTime)
                .font(.system(.title2, design: .rounded, weight: .bold).monospacedDigit())
            Text(entry.nextTitle)
                .font(.caption.weight(.semibold))
                .lineLimit(2)
            Text(entry.nextLocation)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
    }

    private var mediumView: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                Label("LifePilot", systemImage: "sparkles")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.teal)
                Spacer()
                Text("\(entry.readiness)% ready")
                    .font(.system(.title2, design: .rounded, weight: .bold).monospacedDigit())
                Text("\(entry.pendingActions) prepared actions need review")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Divider()

            VStack(alignment: .leading, spacing: 6) {
                Text("NEXT")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.secondary)
                Text(entry.nextTime)
                    .font(.system(.title3, design: .rounded, weight: .bold).monospacedDigit())
                Text(entry.nextTitle)
                    .font(.caption.weight(.medium))
                    .lineLimit(2)
                if !entry.nextLocation.isEmpty {
                    Label(entry.nextLocation, systemImage: "location.fill")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                Spacer()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

private struct LifePilotLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: LifePilotActivityAttributes.self) { context in
            HStack(spacing: 14) {
                Image(systemName: "sparkles")
                    .foregroundStyle(.teal)
                    .font(.title3.weight(.semibold))

                VStack(alignment: .leading, spacing: 3) {
                    Text(context.state.nextItem)
                        .font(.headline)
                    Text(context.state.detail)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Text("\(Int(context.state.progress * 100))%")
                    .font(.system(.headline, design: .rounded, weight: .bold).monospacedDigit())
            }
            .padding()
            .activityBackgroundTint(Color.black.opacity(0.86))
            .activitySystemActionForegroundColor(.white)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Label("LifePilot", systemImage: "sparkles")
                        .foregroundStyle(.teal)
                        .font(.caption.weight(.semibold))
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("\(Int(context.state.progress * 100))%")
                        .font(.system(.caption, design: .rounded, weight: .bold).monospacedDigit())
                }
                DynamicIslandExpandedRegion(.bottom) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(context.state.nextItem)
                            .font(.headline)
                        Text(context.state.detail)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            } compactLeading: {
                Image(systemName: "sparkles")
                    .foregroundStyle(.teal)
            } compactTrailing: {
                Text("\(Int(context.state.progress * 100))%")
                    .font(.caption2.weight(.bold).monospacedDigit())
            } minimal: {
                Image(systemName: "sparkles")
                    .foregroundStyle(.teal)
            }
            .keylineTint(.teal)
        }
    }
}
