import Foundation
import LifePilotCore

/// Rule-based reasoning over a day's real calendar events, producing the
/// same `RecommendationModel`/`DaySignal` shapes `MockRecommendationProvider`
/// hand-wrote as samples. Kept separate from `GhostBrainService` so the
/// rules themselves are unit-testable against fixed `CalendarEvent` arrays
/// without touching EventKit or async orchestration.
///
/// Every rule here explains its own reasoning in the `reasoning` string it
/// produces, per the Core Philosophy in README.md: a recommendation without
/// a "why" isn't one Ghost Brain is allowed to surface.
struct CalendarRecommendationEngine {
    let now: Date
    private let calendar = Calendar.current

    /// How much lead time before a meeting counts as "worth a heads-up."
    private static let upcomingWindow: TimeInterval = 2 * 60 * 60 // 2 hours
    /// Back-to-back events with less than this gap are flagged as tight.
    private static let tightGapThreshold: TimeInterval = 10 * 60 // 10 minutes

    func recommendations(from events: [CalendarEvent]) -> [RecommendationModel] {
        var results: [RecommendationModel] = []
        let sorted = events.sorted { $0.startDate < $1.startDate }

        // Rule 1: overlapping events are a scheduling conflict — always
        // surfaced regardless of how far away they are.
        for (lhs, rhs) in adjacentPairs(sorted) where lhs.overlaps(rhs) {
            results.append(
                RecommendationModel(
                    title: "Resolve conflict between \"\(lhs.title)\" and \"\(rhs.title)\"",
                    reasoning: "These two events overlap on your calendar — "
                        + "\"\(lhs.title)\" runs until \(Self.time(lhs.endDate)) but "
                        + "\"\(rhs.title)\" starts at \(Self.time(rhs.startDate)).",
                    sourceAgent: .calendar,
                    riskLevel: .medium,
                    urgency: .high,
                    createdAt: now
                )
            )
        }

        // Rule 2: back-to-back events with little to no gap between them —
        // not a conflict, but worth a heads-up so the user can plan transit.
        for (lhs, rhs) in adjacentPairs(sorted) where !lhs.overlaps(rhs) {
            let gap = rhs.startDate.timeIntervalSince(lhs.endDate)
            if gap >= 0, gap < Self.tightGapThreshold {
                results.append(
                    RecommendationModel(
                        title: "Only \(Self.minutes(gap)) min between \"\(lhs.title)\" and \"\(rhs.title)\"",
                        reasoning: "\"\(lhs.title)\" ends at \(Self.time(lhs.endDate)) and "
                            + "\"\(rhs.title)\" starts at \(Self.time(rhs.startDate)) — "
                            + "you may want to build in transition time.",
                        sourceAgent: .calendar,
                        riskLevel: .low,
                        urgency: .normal,
                        createdAt: now
                    )
                )
            }
        }

        // Rule 3: the next event starting soon gets a proactive heads-up,
        // scaled by how many attendees are involved (a rough proxy for how
        // disruptive being late would be).
        if let next = sorted.first(where: { $0.startDate > now }) {
            let leadTime = next.startDate.timeIntervalSince(now)
            if leadTime <= Self.upcomingWindow {
                let urgency: RecommendationModel.Urgency = leadTime <= 30 * 60 ? .high : .normal
                results.append(
                    RecommendationModel(
                        title: "\"\(next.title)\" starts at \(Self.time(next.startDate))",
                        reasoning: next.attendeeCount > 1
                            ? "Starting in \(Self.minutes(leadTime)) minutes with "
                                + "\(next.attendeeCount) attendees — worth leaving now if it's off-site."
                            : "Starting in \(Self.minutes(leadTime)) minutes.",
                        sourceAgent: .calendar,
                        riskLevel: .low,
                        urgency: urgency,
                        createdAt: now
                    )
                )
            }
        }

        return results
    }

    func signals(from events: [CalendarEvent]) -> [DaySignal] {
        events.map { event in
            DaySignal(
                kind: .event,
                title: event.title,
                subtitle: event.location,
                timestamp: event.startDate,
                sourceAgent: .calendar
            )
        }
    }

    /// Consecutive (i, i+1) pairs from a sorted event list — the unit both
    /// the conflict and tight-gap rules reason over.
    private func adjacentPairs(_ events: [CalendarEvent]) -> [(CalendarEvent, CalendarEvent)] {
        guard events.count > 1 else { return [] }
        return zip(events, events.dropFirst()).map { ($0, $1) }
    }

    private static func time(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    private static func minutes(_ interval: TimeInterval) -> Int {
        Int(interval / 60)
    }
}
