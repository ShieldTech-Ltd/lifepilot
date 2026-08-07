import Foundation
import LifePilotCore
import XCTest
@testable import LifePilotAppShell
@testable import LifePilotServices

final class AppDependenciesTests: XCTestCase {
    func testLiveDependenciesWireSwiftDataStores() {
        let dependencies = AppDependencies.live
        XCTAssertNotNil(dependencies.taskStore)
        XCTAssertNotNil(dependencies.eventStore)
        XCTAssertNotNil(dependencies.preferenceStore)
        XCTAssertNotNil(dependencies.approvalStore)
        // XCTest host cannot construct UNUserNotificationCenter / EventKit safely.
        XCTAssertTrue(dependencies.notificationScheduler is NoOpNotificationScheduler)
        XCTAssertTrue(dependencies.calendarIntegration is UnavailableCalendarIntegration)
        XCTAssertTrue(dependencies.weatherIntegration is UnavailableWeatherIntegration)
        XCTAssertTrue(dependencies.travelIntegration is UnavailableTravelTimeIntegration)
    }

    func testPreviewDependenciesUseInMemoryStores() async {
        let dependencies = AppDependencies.preview
        let tasks = await dependencies.taskStore.allTasks()
        XCTAssertFalse(tasks.isEmpty)
    }

    func testLiveGhostBrainProvidesProductionModelWithoutThrowing() async throws {
        let dependencies = AppDependencies.live
        let model = try await dependencies.ghostBrain.currentModel()
        XCTAssertLessThanOrEqual(model.generatedAt, Date())
    }
}
