import Foundation
import XCTest
@testable import LifePilotFeatures

final class ScheduleScreenshotParserTests: XCTestCase {
    func testRecognisedScheduleTextProducesEditableEventDraft() {
        let referenceDate = Date(timeIntervalSince1970: 1_780_000_000)
        let draft = ScheduleScreenshotParser.draft(
            from: [
                "Weekly schedule",
                "Dentist appointment",
                "3 August 2026, 13:30 - 14:30",
                "International House, Room 4.01",
            ],
            referenceDate: referenceDate
        )
        let calendar = Calendar.current

        XCTAssertEqual(draft.title, "Dentist appointment")
        XCTAssertEqual(draft.location, "International House, Room 4.01")
        XCTAssertEqual(calendar.component(.year, from: draft.startDate), 2026)
        XCTAssertEqual(calendar.component(.month, from: draft.startDate), 8)
        XCTAssertEqual(calendar.component(.day, from: draft.startDate), 3)
        XCTAssertEqual(calendar.component(.hour, from: draft.startDate), 13)
        XCTAssertEqual(calendar.component(.minute, from: draft.startDate), 30)
        XCTAssertEqual(calendar.component(.hour, from: draft.endDate), 14)
        XCTAssertEqual(calendar.component(.minute, from: draft.endDate), 30)
    }

    func testSingleTimeDefaultsToOneHour() {
        let referenceDate = Date(timeIntervalSince1970: 1_780_000_000)
        let draft = ScheduleScreenshotParser.draft(
            from: ["Project supervision", "10:15 AM", "Microsoft Teams"],
            referenceDate: referenceDate
        )

        XCTAssertEqual(draft.endDate.timeIntervalSince(draft.startDate), 3600, accuracy: 1)
    }

    func testICSInvitationProducesScheduleDraft() {
        let invitation = """
        BEGIN:VCALENDAR
        BEGIN:VEVENT
        SUMMARY:Weekend football match
        DTSTART:20260803T133000
        DTEND:20260803T143000
        LOCATION:International House\\, Room 4.01
        END:VEVENT
        END:VCALENDAR
        """

        let draft = CalendarInvitationParser.draft(from: invitation)
        let calendar = Calendar.current

        XCTAssertEqual(draft.title, "Weekend football match")
        XCTAssertEqual(draft.location, "International House, Room 4.01")
        XCTAssertEqual(calendar.component(.year, from: draft.startDate), 2026)
        XCTAssertEqual(calendar.component(.month, from: draft.startDate), 8)
        XCTAssertEqual(calendar.component(.day, from: draft.startDate), 3)
        XCTAssertEqual(calendar.component(.hour, from: draft.startDate), 13)
        XCTAssertEqual(calendar.component(.minute, from: draft.startDate), 30)
        XCTAssertEqual(draft.endDate.timeIntervalSince(draft.startDate), 3600, accuracy: 1)
    }

    func testPlainInvitationTextUsesScheduleTextParser() {
        let draft = CalendarInvitationParser.draft(from: """
        Group project supervision
        3 August 2026, 10:00 - 11:00
        Microsoft Teams
        """)

        XCTAssertEqual(draft.title, "Group project supervision")
        XCTAssertEqual(draft.location, "Microsoft Teams")
    }
}
