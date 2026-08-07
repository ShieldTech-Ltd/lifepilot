import Foundation
import XCTest
@testable import LifePilotCore

final class DeterministicPlanningEngineTests: XCTestCase {
    private let engine = DeterministicPlanningEngine()
    private let preferences = UserPreferences()

    func testDetectsOverlappingEvents() {
        let now = Date()
        let events = [
            CalendarEvent(
                title: "Sync",
                startDate: now,
                endDate: now.addingTimeInterval(3600),
                context: .work,
                eventKind: .meeting
            ),
            CalendarEvent(
                title: "Pickup",
                startDate: now.addingTimeInterval(1800),
                endDate: now.addingTimeInterval(5400),
                context: .personal
            ),
        ]

        let findings = engine.analyze(events: events, tasks: [], preferences: preferences, now: now)

        XCTAssertTrue(findings.contains { $0.kind == .overlappingEvents })
        XCTAssertFalse(findings.first { $0.kind == .overlappingEvents }?.evidence.isEmpty ?? true)
    }

    func testDetectsInsufficientTravelBuffer() {
        let now = Date()
        let events = [
            CalendarEvent(
                title: "Office",
                startDate: now,
                endDate: now.addingTimeInterval(3600)
            ),
            CalendarEvent(
                title: "School",
                location: "Lincoln",
                startDate: now.addingTimeInterval(3700),
                endDate: now.addingTimeInterval(5400),
                travelBufferMinutes: 20
            ),
        ]

        let findings = engine.analyze(events: events, tasks: [], preferences: preferences, now: now)

        XCTAssertTrue(findings.contains { $0.kind == .insufficientTravelOrPreparation })
    }

    func testDetectsOverdueTasks() {
        let now = Date()
        let tasks = [
            TaskItem(title: "Past due", dueDate: now.addingTimeInterval(-3600), priority: .high),
        ]

        let findings = engine.analyze(events: [], tasks: tasks, preferences: preferences, now: now)

        XCTAssertTrue(findings.contains { $0.kind == .overdueTask })
    }

    func testDeclinedEventsDoNotConflict() {
        let now = Date()
        let events = [
            CalendarEvent(
                title: "A",
                startDate: now,
                endDate: now.addingTimeInterval(3600),
                status: .declined
            ),
            CalendarEvent(
                title: "B",
                startDate: now.addingTimeInterval(1800),
                endDate: now.addingTimeInterval(5400)
            ),
        ]

        let findings = engine.analyze(events: events, tasks: [], preferences: preferences, now: now)

        XCTAssertFalse(findings.contains { $0.kind == .overlappingEvents })
    }
}
