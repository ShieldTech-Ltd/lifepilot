import XCTest
@testable import LifePilotCore

final class TimelineProvidingTests: XCTestCase {
    func testTimelineEntryKindsAreDistinct() {
        let event = TimelineEntry(date: Date(), title: "A", subtitle: nil, kind: .event)
        let task = TimelineEntry(date: Date(), title: "B", subtitle: nil, kind: .task)
        XCTAssertNotEqual(event.kind, task.kind)
    }
}
