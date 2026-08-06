import LifePilotCore
import LifePilotGhostBrain
import XCTest
@testable import LifePilotFeatures

@MainActor
final class HomeViewModelTests: XCTestCase {
    func testLoadPopulatesGreetingAndRecommendations() async {
        let viewModel = HomeViewModel(ghostBrain: MockRecommendationProvider())

        await viewModel.load()

        XCTAssertFalse(viewModel.greeting.isEmpty)
        XCTAssertFalse(viewModel.recommendations.isEmpty)
        XCTAssertFalse(viewModel.upcomingEvents.isEmpty)
        XCTAssertFalse(viewModel.isLoading)
    }

    func testLoadHandlesFailingProviderGracefully() async {
        struct FailingProvider: GhostBrainServing {
            func currentModel() async throws -> GhostBrainModel {
                throw DomainError.unavailableNamed("test failure")
            }
        }

        let viewModel = HomeViewModel(ghostBrain: FailingProvider())

        await viewModel.load()

        XCTAssertTrue(viewModel.recommendations.isEmpty)
        XCTAssertFalse(viewModel.isLoading)
    }

    func testNextEventIsSeparatedFromTheRemainingAgenda() async throws {
        let calendar = Calendar(identifier: .gregorian)
        let now = try XCTUnwrap(calendar.date(from: DateComponents(
            year: 2026,
            month: 8,
            day: 1,
            hour: 8
        )))
        let viewModel = HomeViewModel(
            ghostBrain: MockRecommendationProvider(clock: { now })
        )

        await viewModel.load()

        XCTAssertEqual(viewModel.nextEvent?.title, "Morning planning")
        XCTAssertEqual(viewModel.laterEvents.count, viewModel.eventsAhead.count - 1)
        XCTAssertFalse(viewModel.laterEvents.contains(where: { $0.id == viewModel.nextEvent?.id }))
    }
}
