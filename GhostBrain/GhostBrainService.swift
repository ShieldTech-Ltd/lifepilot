import Foundation
import LifePilotCore

/// The production `GhostBrainServing` implementation. Fuses real calendar
/// data (via an injected `CalendarReading` adapter) into `GhostBrainModel`
/// using rule-based reasoning — a deliberate first step of
/// docs/MASTER_ROADMAP.md Phase 5, ahead of a learned/LLM-backed reasoning
/// engine. The rules live in `CalendarRecommendationEngine` so this type
/// stays a thin orchestrator and the reasoning itself is independently
/// testable and swappable.
public struct GhostBrainService: GhostBrainServing {
    private let calendarReader: CalendarReading
    private let userFirstName: String
    private let clock: @Sendable () -> Date

    public init(
        calendarReader: CalendarReading,
        userFirstName: String = "there",
        clock: @escaping @Sendable () -> Date = Date.init
    ) {
        self.calendarReader = calendarReader
        self.userFirstName = userFirstName
        self.clock = clock
    }

    public func currentModel() async throws -> GhostBrainModel {
        let now = clock()
        let events = try await calendarReader.events(on: now)
        let engine = CalendarRecommendationEngine(now: now)

        return GhostBrainModel(
            generatedAt: now,
            greetingContext: Self.greetingContext(for: now, userFirstName: userFirstName),
            recommendations: engine.recommendations(from: events),
            upcomingEvents: events,
            signals: engine.signals(from: events)
        )
    }

    private static func greetingContext(
        for date: Date,
        userFirstName: String
    ) -> GhostBrainModel.GreetingContext {
        let hour = Calendar.current.component(.hour, from: date)
        let timeOfDay: GreetingTimeOfDay
        switch hour {
        case 0 ..< 12: timeOfDay = .morning
        case 12 ..< 17: timeOfDay = .afternoon
        default: timeOfDay = .evening
        }
        return GhostBrainModel.GreetingContext(userFirstName: userFirstName, timeOfDay: timeOfDay)
    }
}
