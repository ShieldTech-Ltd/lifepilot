import LifePilotCore
import XCTest
@testable import LifePilotServices

/// `EventKitCalendarReader` talks to the real Calendar store and requires
/// user authorization, so it can't be meaningfully exercised end-to-end in
/// a headless CI run. This confirms the composition-level contract (it
/// conforms to `CalendarReading`, the seam `GhostBrainService` depends on)
/// and documents what still needs manual, on-device verification.
///
/// See the handoff notes in docs/EVENTKIT_INTEGRATION.md for the manual
/// test plan: granting/denying access, an empty calendar, overlapping
/// events, and a tight back-to-back schedule.
final class EventKitCalendarReaderTests: XCTestCase {
    func testConformsToCalendarReading() {
        let reader = EventKitCalendarReader()

        XCTAssertTrue((reader as Any) is CalendarReading)
    }
}
