import Foundation
import LifePilotCore
import XCTest
@testable import LifePilotGhostBrain

/// A fixed-response `CalendarReading` fake, so `GhostBrainService` can be
/// tested as pure orchestration logic without EventKit or device
/// permissions — the same seam `EventKitCalendarReader` fills in production.
private struct FakeCalendarReader: CalendarReading {
    var events: [CalendarEvent] = []
    var error: Error?

    func events(on date: Date) async throws -> [CalendarEvent] {
        if let error { throw error }
        return events
    }
}

final class GhostBrainServiceTests: XCTestCase {
    private let referenceDate = ISO8601DateFormatter().date(from: "2026-07-27T08:00:00Z") ?? Date()

    func testCurrentModelUsesEventsFromTheInjectedCalendarReader() async throws {
        let event = CalendarEvent(
            title: "Design Review",
            startDate: referenceDate.addingTimeInterval(600),
            endDate: referenceDate.addingTimeInterval(3600)
        )
        let service = GhostBrainService(
            calendarReader: FakeCalendarReader(events: [event]),
            userFirstName: "Alex",
            clock: { self.referenceDate }
        )

        let model = try await service.currentModel()

        XCTAssertEqual(model.upcomingEvents, [event])
        XCTAssertEqual(model.greetingContext.userFirstName, "Alex")
        XCTAssertFalse(model.recommendations.isEmpty, "An imminent event should produce a recommendation")
    }

    func testCurrentModelPropagatesCalendarReaderErrors() async {
        let service = GhostBrainService(
            calendarReader: FakeCalendarReader(error: DomainError.unavailable("Calendar access denied.")),
            clock: { self.referenceDate }
        )

        do {
            _ = try await service.currentModel()
            XCTFail("Expected the calendar reader's error to propagate")
        } catch {
            XCTAssertTrue(error is DomainError)
        }
    }

    func testGreetingTimeOfDayMatchesInjectedClock() async throws {
        var components = DateComponents()
        components.year = 2026
        components.month = 7
        components.day = 27
        components.hour = 19
        let evening = Calendar.current.date(from: components) ?? referenceDate

        let service = GhostBrainService(
            calendarReader: FakeCalendarReader(),
            clock: { evening }
        )

        let model = try await service.currentModel()

        XCTAssertEqual(model.greetingContext.timeOfDay, .evening)
    }

    func testEmptyCalendarProducesNoRecommendationsButStillSucceeds() async throws {
        let service = GhostBrainService(
            calendarReader: FakeCalendarReader(events: []),
            clock: { self.referenceDate }
        )

        let model = try await service.currentModel()

        XCTAssertTrue(model.recommendations.isEmpty)
        XCTAssertTrue(model.upcomingEvents.isEmpty)
    }
}
