import LifePilotCore
import LifePilotGhostBrain
import XCTest
@testable import LifePilotFeatures

@MainActor
final class DemoSessionStoreTests: XCTestCase {
    func testApprovalUpdatesHomeTimelineAndInsights() async throws {
        let defaults = makeDefaults()
        defer { clear(defaults) }
        let session = DemoSessionStore(ghostBrain: MockRecommendationProvider(), defaults: defaults)
        let home = HomeViewModel(session: session)
        let timeline = TimelineViewModel(session: session)
        let insights = InsightsViewModel(session: session)

        await home.load()
        let recommendation = try XCTUnwrap(home.recommendations.first)
        let pendingBefore = session.availableRecommendations.count

        home.approve(recommendation)

        XCTAssertEqual(session.availableRecommendations.count, pendingBefore - 1)
        XCTAssertEqual(home.recentActivity.first?.wasApproved, true)
        XCTAssertTrue(timeline.entries.contains(where: { $0.kind == .action }))
        XCTAssertEqual(insights.metrics.first(where: { $0.id == "approved" })?.value, "1")
    }

    func testPausingTravelRemovesItsContentAcrossScreens() async {
        let defaults = makeDefaults()
        defer { clear(defaults) }
        let session = DemoSessionStore(ghostBrain: MockRecommendationProvider(), defaults: defaults)
        let timeline = TimelineViewModel(session: session)
        let memory = MemoryViewModel(session: session)

        await session.prepare()
        XCTAssertTrue(session.availableRecommendations.contains(where: { $0.sourceAgent == .travel }))
        XCTAssertTrue(timeline.entries.contains(where: { $0.kind == .travel }))
        XCTAssertTrue(memory.sections.contains(where: { $0.id == "travel" }))

        session.setConnection(.travel, isEnabled: false)

        XCTAssertFalse(session.availableRecommendations.contains(where: { $0.sourceAgent == .travel }))
        XCTAssertFalse(timeline.entries.contains(where: { $0.kind == .travel }))
        XCTAssertFalse(memory.sections.contains(where: { $0.id == "travel" }))
    }

    func testProfileUpdatePersonalizesHomeAndSettings() async {
        let defaults = makeDefaults()
        defer { clear(defaults) }
        let session = DemoSessionStore(ghostBrain: MockRecommendationProvider(), defaults: defaults)
        let home = HomeViewModel(session: session)
        let settings = SettingsViewModel(session: session)
        await home.load()

        session.updateProfile(
            displayName: "Ritik Sah",
            email: "ritik@example.com",
            course: "MSc Computing",
            university: "Ulster University London",
            location: "London",
            briefingTime: "9:00 AM"
        )

        XCTAssertTrue(home.greeting.contains("Ritik"))
        XCTAssertTrue(home.profileContextText.contains("9:00 AM"))
        XCTAssertEqual(settings.sections[0].rows[0].detail, "Ritik Sah")
        XCTAssertEqual(defaults.string(forKey: StorageKey.profileBriefingTime), "9:00 AM")
    }

    func testResetRestoresDemoDefaultsAndClearsActivity() async throws {
        let defaults = makeDefaults()
        defer { clear(defaults) }
        let session = DemoSessionStore(ghostBrain: MockRecommendationProvider(), defaults: defaults)
        await session.prepare()
        let recommendation = try XCTUnwrap(session.availableRecommendations.first)
        session.resolve(recommendation.id, approved: true)
        session.setConnection(.calendar, isEnabled: false)

        session.resetLocalDemoState()

        XCTAssertTrue(session.activities.isEmpty)
        XCTAssertTrue(session.calendarEnabled)
        XCTAssertEqual(session.displayName, "Alex Morgan")
        XCTAssertEqual(session.availableRecommendations.count, session.model?.recommendations.count)
    }

    private func makeDefaults() -> UserDefaults {
        let suiteName = "DemoSessionStoreTests.\(UUID().uuidString)"
        return UserDefaults(suiteName: suiteName) ?? .standard
    }

    private func clear(_ defaults: UserDefaults) {
        for key in StorageKey.all {
            defaults.removeObject(forKey: key)
        }
    }
}
