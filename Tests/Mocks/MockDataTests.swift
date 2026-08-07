import XCTest
@testable import LifePilotMocks

final class MockDataTests: XCTestCase {
    func testMockCalendarProducesPersonalEvents() {
        let events = MockCalendar.events()
        XCTAssertFalse(events.isEmpty)
        XCTAssertTrue(events.contains(where: { $0.title == "Work shift" }))
        XCTAssertTrue(events.contains(where: { $0.title == "Dentist appointment" }))
    }

    func testMockEmailProducesNonEmptyMessages() {
        XCTAssertFalse(MockEmail.messages().isEmpty)
    }

    func testMockTasksProducesNonEmptyItems() {
        XCTAssertFalse(MockTasks.items().isEmpty)
    }

    func testMockTravelProducesNonEmptyItineraries() {
        let itineraries = MockTravel.itineraries()
        XCTAssertFalse(itineraries.isEmpty)
        XCTAssertTrue(itineraries.contains(where: { $0.destination == "London Euston" }))
    }

    func testMockNotificationsProducesNonEmptyItems() {
        XCTAssertFalse(MockNotifications.items().isEmpty)
    }

    func testMockWeatherProducesAValidPrecipitationChance() {
        let snapshot = MockWeather.snapshot()
        XCTAssertGreaterThanOrEqual(snapshot.precipitationChance, 0)
        XCTAssertLessThanOrEqual(snapshot.precipitationChance, 1)
    }
}
