import Foundation
import LifePilotCore
import XCTest
@testable import LifePilotGhostBrain

final class CalendarRecommendationEngineTests: XCTestCase {
    private let referenceDate = ISO8601DateFormatter().date(from: "2026-07-27T08:00:00Z") ?? Date()

    func testOverlappingEventsProduceAHighUrgencyConflictRecommendation() {
        let engine = CalendarRecommendationEngine(now: referenceDate)
        let first = CalendarEvent(
            title: "Design Review",
            startDate: referenceDate.addingTimeInterval(3600),
            endDate: referenceDate.addingTimeInterval(3600 * 2)
        )
        let second = CalendarEvent(
            title: "1:1 with Priya",
            startDate: referenceDate.addingTimeInterval(3600 * 1.5),
            endDate: referenceDate.addingTimeInterval(3600 * 2.5)
        )

        let recommendations = engine.recommendations(from: [first, second])

        let conflict = recommendations.first { $0.riskLevel == .medium }
        XCTAssertNotNil(conflict, "Overlapping events should produce a conflict recommendation")
        XCTAssertEqual(conflict?.urgency, .high)
        XCTAssertEqual(conflict?.sourceAgent, .calendar)
    }

    func testTightGapBetweenEventsProducesALowRiskHeadsUp() {
        let engine = CalendarRecommendationEngine(now: referenceDate)
        let first = CalendarEvent(
            title: "Design Review",
            startDate: referenceDate.addingTimeInterval(3600),
            endDate: referenceDate.addingTimeInterval(3600 * 2)
        )
        let second = CalendarEvent(
            title: "1:1 with Priya",
            startDate: referenceDate.addingTimeInterval(3600 * 2 + 300), // 5 min gap
            endDate: referenceDate.addingTimeInterval(3600 * 3)
        )

        let recommendations = engine.recommendations(from: [first, second])

        let headsUp = recommendations.first { $0.title.contains("min between") }
        XCTAssertNotNil(headsUp, "A 5-minute gap should produce a tight-gap heads-up")
        XCTAssertEqual(headsUp?.riskLevel, .low)
    }

    func testComfortableGapBetweenEventsProducesNoHeadsUp() {
        let engine = CalendarRecommendationEngine(now: referenceDate)
        let first = CalendarEvent(
            title: "Design Review",
            startDate: referenceDate.addingTimeInterval(3600),
            endDate: referenceDate.addingTimeInterval(3600 * 2)
        )
        let second = CalendarEvent(
            title: "1:1 with Priya",
            startDate: referenceDate.addingTimeInterval(3600 * 3), // 1 hour gap
            endDate: referenceDate.addingTimeInterval(3600 * 4)
        )

        let recommendations = engine.recommendations(from: [first, second])

        XCTAssertTrue(recommendations.isEmpty, "A comfortable gap shouldn't trigger any recommendation")
    }

    func testImminentEventWithAttendeesProducesHighUrgencyHeadsUp() {
        let engine = CalendarRecommendationEngine(now: referenceDate)
        let soon = CalendarEvent(
            title: "Board Deck Review",
            startDate: referenceDate.addingTimeInterval(600), // 10 min from now
            endDate: referenceDate.addingTimeInterval(3600),
            attendeeCount: 4
        )

        let recommendations = engine.recommendations(from: [soon])

        let headsUp = recommendations.first { $0.title.contains(soon.title) }
        XCTAssertNotNil(headsUp)
        XCTAssertEqual(headsUp?.urgency, .high)
        XCTAssertTrue(headsUp?.reasoning.contains("4 attendees") ?? false)
    }

    func testDistantEventProducesNoHeadsUpYet() {
        let engine = CalendarRecommendationEngine(now: referenceDate)
        let farAway = CalendarEvent(
            title: "End of Day Sync",
            startDate: referenceDate.addingTimeInterval(3600 * 5),
            endDate: referenceDate.addingTimeInterval(3600 * 6)
        )

        let recommendations = engine.recommendations(from: [farAway])

        XCTAssertTrue(recommendations.isEmpty, "An event 5 hours away shouldn't produce a heads-up yet")
    }

    func testSignalsMirrorEveryEvent() {
        let engine = CalendarRecommendationEngine(now: referenceDate)
        let events = [
            CalendarEvent(
                title: "Design Review",
                location: "Studio",
                startDate: referenceDate.addingTimeInterval(3600),
                endDate: referenceDate.addingTimeInterval(3600 * 2)
            ),
            CalendarEvent(
                title: "Lunch",
                startDate: referenceDate.addingTimeInterval(3600 * 4),
                endDate: referenceDate.addingTimeInterval(3600 * 5)
            ),
        ]

        let signals = engine.signals(from: events)

        XCTAssertEqual(signals.count, 2)
        XCTAssertEqual(signals.map(\.title), events.map(\.title))
        XCTAssertTrue(signals.allSatisfy { $0.kind == .event && $0.sourceAgent == .calendar })
    }

    func testEmptyCalendarProducesNoRecommendationsOrSignals() {
        let engine = CalendarRecommendationEngine(now: referenceDate)

        XCTAssertTrue(engine.recommendations(from: []).isEmpty)
        XCTAssertTrue(engine.signals(from: []).isEmpty)
    }
}
