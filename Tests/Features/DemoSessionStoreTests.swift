import Foundation
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

    func testApprovalHistoryAndResolvedActionsPersistAcrossRestarts() async throws {
        let defaults = makeDefaults()
        defer { clear(defaults) }
        let now = Date(timeIntervalSince1970: 1_807_000_000)
        let provider = MockRecommendationProvider(clock: { now })
        let session = DemoSessionStore(ghostBrain: provider, defaults: defaults)
        await session.prepare()
        let recommendation = try XCTUnwrap(session.availableRecommendations.first)

        session.resolve(recommendation.id, approved: true)

        let restored = DemoSessionStore(ghostBrain: provider, defaults: defaults)
        await restored.prepare()
        XCTAssertEqual(restored.activities, session.activities)
        XCTAssertFalse(restored.availableRecommendations.contains(where: {
            $0.title == recommendation.title && $0.sourceAgent == recommendation.sourceAgent
        }))
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
            course: "Daily routine",
            university: "Personal",
            location: "London",
            briefingTime: "09:00"
        )

        XCTAssertTrue(home.greeting.contains("Ritik"))
        XCTAssertTrue(home.profileContextText.contains("09:00"))
        XCTAssertEqual(settings.sections[0].rows[0].detail, "Ritik Sah")
        XCTAssertEqual(defaults.string(forKey: StorageKey.profileBriefingTime), "09:00")
    }

    func testProfileImagePersistsAndCanBeRemoved() {
        let defaults = makeDefaults()
        defer { clear(defaults) }
        let session = DemoSessionStore(ghostBrain: MockRecommendationProvider(), defaults: defaults)
        let imageData = Data([0x01, 0x02, 0x03])

        session.updateProfileImage(imageData)

        XCTAssertEqual(session.profileImageData, imageData)
        XCTAssertEqual(defaults.data(forKey: StorageKey.profileImageData), imageData)

        session.updateProfileImage(nil)

        XCTAssertNil(session.profileImageData)
        XCTAssertNil(defaults.data(forKey: StorageKey.profileImageData))
    }

    func testImportedScreenshotEventPersistsAndAppearsAcrossHomeAndTimeline() {
        let defaults = makeDefaults()
        defer { clear(defaults) }
        let session = DemoSessionStore(ghostBrain: MockRecommendationProvider(), defaults: defaults)
        let event = CalendarEvent(
            title: "Weekend football match",
            location: "Community sports centre",
            startDate: Date(timeIntervalSince1970: 1_785_756_600),
            endDate: Date(timeIntervalSince1970: 1_785_760_200)
        )

        session.addImportedEvent(event)

        XCTAssertTrue(session.visibleEvents.contains(event))
        XCTAssertTrue(TimelineViewModel(session: session).entries.contains(where: { $0.id == event.id }))
        XCTAssertTrue(HomeViewModel(session: session).upcomingEvents.contains(event))

        let restored = DemoSessionStore(ghostBrain: MockRecommendationProvider(), defaults: defaults)
        XCTAssertEqual(restored.importedEvents, [event])
    }

    func testAppearancePreferencePersistsAndResetsToSystem() {
        let defaults = makeDefaults()
        defer { clear(defaults) }
        let session = DemoSessionStore(ghostBrain: MockRecommendationProvider(), defaults: defaults)

        session.setAppearancePreference(.dark)

        XCTAssertEqual(session.appearancePreference, .dark)
        XCTAssertEqual(defaults.string(forKey: StorageKey.appearancePreference), AppearancePreference.dark.rawValue)
        XCTAssertEqual(
            DemoSessionStore(ghostBrain: MockRecommendationProvider(), defaults: defaults).appearancePreference,
            .dark
        )

        session.resetLocalDemoState()

        XCTAssertEqual(session.appearancePreference, .system)
        XCTAssertNil(defaults.string(forKey: StorageKey.appearancePreference))
    }

    func testPasswordUpdateRecordsNoPasswordTextAndResets() {
        let defaults = makeDefaults()
        defer { clear(defaults) }
        let session = DemoSessionStore(ghostBrain: MockRecommendationProvider(), defaults: defaults)
        let updatedAt = Date(timeIntervalSince1970: 1_800_000_000)

        session.recordPasswordUpdate(at: updatedAt)

        XCTAssertEqual(session.passwordUpdatedAt, updatedAt)
        XCTAssertEqual(defaults.object(forKey: StorageKey.passwordUpdatedAt) as? Date, updatedAt)
        XCTAssertFalse(StorageKey.all.contains(where: { $0.lowercased().contains("passwordtext") }))

        session.resetLocalDemoState()

        XCTAssertNil(session.passwordUpdatedAt)
        XCTAssertNil(defaults.object(forKey: StorageKey.passwordUpdatedAt))
    }

    func testInsightPeriodsExposeDifferentMetricsAndTrendGranularity() {
        let defaults = makeDefaults()
        defer { clear(defaults) }
        let session = DemoSessionStore(ghostBrain: MockRecommendationProvider(), defaults: defaults)
        let insights = InsightsViewModel(session: session)

        XCTAssertEqual(insights.selectedPeriod, .today)
        XCTAssertEqual(insights.trendPoints.count, 6)
        XCTAssertEqual(insights.metrics.first?.label, "Awaiting review")

        insights.selectedPeriod = .week

        XCTAssertEqual(insights.trendPoints.count, 7)
        XCTAssertEqual(insights.metrics.first?.label, "Actions prepared")

        insights.selectedPeriod = .month

        XCTAssertEqual(insights.trendPoints.count, 4)
        XCTAssertEqual(insights.metrics.last?.value, "3.4h")
    }

    func testResetRestoresDemoDefaultsAndClearsActivity() async throws {
        let defaults = makeDefaults()
        defer { clear(defaults) }
        let session = DemoSessionStore(ghostBrain: MockRecommendationProvider(), defaults: defaults)
        await session.prepare()
        let recommendation = try XCTUnwrap(session.availableRecommendations.first)
        session.resolve(recommendation.id, approved: true)
        session.setConnection(.calendar, isEnabled: false)
        session.updateProfileImage(Data([0x01]))

        session.resetLocalDemoState()

        XCTAssertTrue(session.activities.isEmpty)
        XCTAssertTrue(session.calendarEnabled)
        XCTAssertEqual(session.displayName, "Alex")
        XCTAssertEqual(session.course, "Daily routine")
        XCTAssertNil(session.profileImageData)
        XCTAssertEqual(
            session.availableRecommendations.count,
            session.model?.recommendations.filter { session.isEnabled($0.sourceAgent) }.count
        )
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
