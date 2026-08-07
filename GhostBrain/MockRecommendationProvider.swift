import Foundation
import LifePilotCore
import LifePilotMocks

/// A `GhostBrainServing` implementation backed entirely by mock data. This
/// is what the App composition root wires in during Phase 3; see
/// docs/MASTER_ROADMAP.md's Phase 4 risk mitigation: "screens are built
/// against the Prediction/Recommendation types... even while populated by
/// stub data," so Features never needs to change when GhostBrainService
/// replaces this in Phase 5.
///
/// Recommendations, events, and signals are all derived from the same
/// `LifePilotMocks` data `TimelineViewModel` merges, so Home and Timeline
/// tell one consistent story about "today" instead of two disconnected
/// ones, and the reasoning text is computed from the mock facts rather than
/// duplicated as a separate hardcoded string.
public struct MockRecommendationProvider: GhostBrainServing {
    private let clock: @Sendable () -> Date

    public init(clock: @escaping @Sendable () -> Date = { Date() }) {
        self.clock = clock
    }

    public func currentModel() async throws -> GhostBrainModel {
        let now = clock()
        let events = MockCalendar.events(relativeTo: now)
        return GhostBrainModel(
            generatedAt: now,
            greetingContext: greetingContext(for: now),
            recommendations: Self.sampleRecommendations(events: events, relativeTo: now),
            upcomingEvents: events,
            signals: Self.sampleSignals(relativeTo: now)
        )
    }

    private func greetingContext(for date: Date) -> GhostBrainModel.GreetingContext {
        let hour = Calendar.current.component(.hour, from: date)
        let timeOfDay: GreetingTimeOfDay
        switch hour {
        case 0 ..< 12: timeOfDay = .morning
        case 12 ..< 17: timeOfDay = .afternoon
        default: timeOfDay = .evening
        }
        return GhostBrainModel.GreetingContext(userFirstName: "Alex", timeOfDay: timeOfDay)
    }

    private static func sampleRecommendations(events: [CalendarEvent], relativeTo now: Date) -> [RecommendationModel] {
        var recommendations: [RecommendationModel] = []

        if let flight = MockTravel.itineraries(relativeTo: now).first(where: { $0.status == .delayed }) {
            recommendations.append(RecommendationModel(
                title: "\(flight.carrier) \(flight.identifier) is delayed",
                reasoning: "Now departing later than scheduled on the \(flight.origin) to \(flight.destination) "
                    + "route. Check the platform before leaving for the station.",
                sourceAgent: .travel,
                riskLevel: .low,
                urgency: .high,
                createdAt: now
            ))
        }

        let staleThreshold: TimeInterval = 2 * 24 * 3600
        let overdueEmail = MockEmail.messages(relativeTo: now)
            .filter { $0.requiresReply && now.timeIntervalSince($0.receivedAt) > staleThreshold }
            .max {
                now.timeIntervalSince($0.receivedAt) < now.timeIntervalSince($1.receivedAt)
            }
        if let overdueEmail {
            recommendations.append(RecommendationModel(
                title: "Reply to \(overdueEmail.sender) about \"\(overdueEmail.subject)\"",
                reasoning: "This email has been waiting since "
                    + overdueEmail.receivedAt.formatted(date: .abbreviated, time: .omitted)
                    + " and looks time-sensitive.",
                sourceAgent: .email,
                riskLevel: .low,
                urgency: .normal,
                createdAt: now
            ))
        }

        if let appointment = events.first(where: { $0.title == "Dentist appointment" }) {
            let precedingEvent = events
                .filter { $0.id != appointment.id && $0.endDate <= appointment.startDate }
                .min {
                    appointment.startDate.timeIntervalSince($0.endDate)
                        < appointment.startDate.timeIntervalSince($1.endDate)
                }

            if let precedingEvent, appointment.startDate.timeIntervalSince(precedingEvent.endDate) < 15 * 60 {
                recommendations.append(RecommendationModel(
                    title: "Leave \"\(precedingEvent.title)\" a few minutes early",
                    reasoning: "It ends at \(precedingEvent.endDate.formatted(date: .omitted, time: .shortened)), "
                        + "just before your appointment. Allow time to travel between places.",
                    sourceAgent: .calendar,
                    riskLevel: .medium,
                    urgency: .high,
                    createdAt: now
                ))
            }
        }

        return recommendations
    }

    private static func sampleSignals(relativeTo now: Date) -> [DaySignal] {
        var signals: [DaySignal] = []

        let weather = MockWeather.snapshot(relativeTo: now)
        signals.append(DaySignal(
            kind: .weather,
            title: weather.condition == .rain ? "Rain today" : "Rain expected this afternoon",
            subtitle: "\(Int(weather.precipitationChance * 100))% chance from around 15:00",
            timestamp: now,
            sourceAgent: .calendar
        ))

        return signals
    }
}
