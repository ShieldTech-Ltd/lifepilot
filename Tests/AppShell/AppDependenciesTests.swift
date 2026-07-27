import XCTest
@testable import LifePilotAppShell
@testable import LifePilotGhostBrain

final class AppDependenciesTests: XCTestCase {
    /// `.live` wires a real `GhostBrainService`, which depends on Calendar
    /// authorization — not available in a CI/simulator test run without a
    /// device prompt. This asserts the composition root wires the correct
    /// *type* rather than exercising EventKit end-to-end (that's
    /// `EventKitCalendarReaderTests`' and `CalendarRecommendationEngineTests`'
    /// job, against fakes).
    func testLiveDependenciesWireARealGhostBrainService() {
        let dependencies = AppDependencies.live

        XCTAssertTrue(dependencies.ghostBrain is GhostBrainService)
    }

    func testPreviewDependenciesProvideAWorkingMockGhostBrain() async throws {
        let dependencies = AppDependencies.preview

        let model = try await dependencies.ghostBrain.currentModel()

        XCTAssertFalse(model.recommendations.isEmpty)
    }
}
