import XCTest
@testable import LifePilotMocks

final class MockDataTests: XCTestCase {
    func testMockCalendarProducesNonEmptyEvents() {
        let events = MockCalendar.events()
        XCTAssertFalse(events.isEmpty)
        XCTAssertTrue(events.contains(where: { $0.title == "TechFest Demo Rehearsal" }))
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

    func testMockFinanceProducesNonEmptyTransactions() {
        let transactions = MockFinance.transactions()
        XCTAssertFalse(transactions.isEmpty)
        XCTAssertTrue(transactions.allSatisfy { $0.formattedAmount.contains("£") })
    }

    func testMockFinanceFlagsAtLeastOneAnomaly() {
        let transactions = MockFinance.transactions()
        XCTAssertTrue(transactions.contains { $0.isAnomalous })
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
