import Foundation
import LifePilotCore
import XCTest
@testable import LifePilotGhostBrain

final class MockRecommendationProviderTests: XCTestCase {
    func testCurrentModelReturnsRecommendations() async throws {
        let provider = MockRecommendationProvider()

        let model = try await provider.currentModel()

        XCTAssertFalse(model.recommendations.isEmpty)
        XCTAssertFalse(model.upcomingEvents.isEmpty)
    }

    func testRankedRecommendationsAreSortedByUrgencyDescending() async throws {
        let provider = MockRecommendationProvider()

        let model = try await provider.currentModel()
        let urgencies = model.rankedRecommendations.map(\.urgency)

        XCTAssertEqual(urgencies, urgencies.sorted(by: >))
    }

    func testGreetingContextMatchesInjectedClock() async throws {
        var components = DateComponents()
        components.year = 2026
        components.month = 7
        components.day = 9
        components.hour = 8
        let morning = Calendar.current.date(from: components) ?? Date()

        let provider = MockRecommendationProvider(clock: { morning })

        let model = try await provider.currentModel()

        XCTAssertEqual(model.greetingContext.timeOfDay, .morning)
    }

    func testGhostBrainServiceBuildsEvidenceBackedModelFromLocalData() async throws {
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        let overdue = TaskItem(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000010") ?? UUID(),
            title: "Submit coursework",
            dueDate: now.addingTimeInterval(-3_600)
        )
        let service = GhostBrainService(
            taskStore: TestTaskStore(tasks: [overdue]),
            eventStore: TestEventStore(),
            preferenceStore: TestPreferenceStore(),
            clock: FixedClock(now)
        )

        let first = try await service.currentModel()
        let second = try await service.currentModel()

        XCTAssertEqual(first.recommendations.map(\.id), second.recommendations.map(\.id))
        XCTAssertEqual(first.recommendations.first?.title, "Overdue: Submit coursework")
        XCTAssertFalse(first.recommendations.first?.evidence.isEmpty ?? true)
        XCTAssertEqual(first.recommendations.first?.sourceAgent, .task)
    }

    func testGhostBrainServiceKeepsLocalResultsWhenOptionalSourcesFail() async throws {
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        let task = TaskItem(title: "Submit application form", dueDate: now.addingTimeInterval(-60))
        let service = GhostBrainService(
            taskStore: TestTaskStore(tasks: [task]),
            eventStore: TestEventStore(),
            preferenceStore: TestPreferenceStore(),
            calendarIntegration: FailingCalendarIntegration(),
            remindersIntegration: FailingRemindersIntegration(),
            weatherIntegration: FailingWeatherIntegration(),
            clock: FixedClock(now)
        )

        let model = try await service.currentModel()

        XCTAssertTrue(model.recommendations.contains(where: { $0.title == "Overdue: Submit application form" }))
    }
}

private actor TestTaskStore: TaskStore {
    private var tasks: [TaskItem]

    init(tasks: [TaskItem]) {
        self.tasks = tasks
    }

    func allTasks() async -> [TaskItem] {
        tasks
    }

    func save(_ task: TaskItem) async throws {
        tasks.append(task)
    }

    func delete(id: UUID) async throws {
        tasks.removeAll { $0.id == id }
    }

    func tasks(matching predicate: @Sendable (TaskItem) -> Bool) async -> [TaskItem] {
        tasks.filter(predicate)
    }
}

private actor TestEventStore: EventStore {
    private var events: [CalendarEvent] = []

    func allEvents() async -> [CalendarEvent] {
        events
    }

    func save(_ event: CalendarEvent) async throws {
        events.append(event)
    }

    func delete(id: UUID) async throws {
        events.removeAll { $0.id == id }
    }
}

private actor TestPreferenceStore: PreferenceStore {
    func loadPreferences() async -> UserPreferences {
        UserPreferences()
    }

    func savePreferences(_: UserPreferences) async throws {}

    func allMemory() async -> [MemoryItem] {
        []
    }

    func saveMemory(_: MemoryItem) async throws {}

    func deleteMemory(id _: UUID) async throws {}

    func exportAll() async throws -> Data {
        Data()
    }

    func deleteAllLifePilotData() async throws {}
}

private struct FailingCalendarIntegration: CalendarIntegrating {
    func authorizationState() async -> CapabilityState {
        .authorized
    }

    func requestAccess() async throws -> Bool {
        true
    }

    func fetchEvents(from _: Date, to _: Date) async throws -> [CalendarEvent] {
        throw DomainError.unavailable
    }
}

private struct FailingRemindersIntegration: RemindersIntegrating {
    func authorizationState() async -> CapabilityState {
        .authorized
    }

    func requestAccess() async throws -> Bool {
        true
    }

    func fetchOpenReminders() async throws -> [TaskItem] {
        throw DomainError.unavailable
    }

    func createReminder(
        title _: String,
        notes _: String?,
        dueDate _: Date?,
        recurrence _: RecurrenceRule?
    ) async throws -> String {
        throw DomainError.unavailable
    }
}

private struct FailingWeatherIntegration: WeatherIntegrating {
    func authorizationState() async -> CapabilityState {
        .authorized
    }

    func currentWeather() async throws -> WeatherSnapshot {
        throw DomainError.unavailable
    }
}
