import XCTest
@testable import LifePilotCore

/// Guarantees contextual demo signals remain read-only and cannot trigger unsafe actions.
final class FinanceScopeRemovalTests: XCTestCase {
    func testDemoContextAgentsRemainAvailable() {
        let raw = Set(AgentKind.allCases.map(\.rawValue))
        for context in ["finance", "shopping", "health", "email"] {
            XCTAssertTrue(raw.contains(context), "Missing demo AgentKind.\(context)")
        }
        XCTAssertFalse(raw.contains("bank"))
    }

    func testDaySignalKindsSupportReadOnlyFinanceAndHealthContext() {
        let raw = Set(DaySignal.Kind.allCases.map(\.rawValue))
        XCTAssertTrue(raw.contains("finance"))
        XCTAssertTrue(raw.contains("health"))
    }

    func testActionTypesIncludeExplicitDenials() {
        XCTAssertEqual(
            ActionProposal.ActionType.forbiddenExternalFinancial.rawValue,
            "forbiddenExternalFinancial"
        )
        XCTAssertEqual(ActionProposal.ActionType.forbiddenSendEmail.rawValue, "forbiddenSendEmail")
        XCTAssertFalse(SecurityPolicy().isAllowed(.forbiddenExternalFinancial))
        XCTAssertFalse(SecurityPolicy().isAllowed(.forbiddenSendEmail))
    }

    func testEmailDemoModelsArePresent() {
        let root = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let emailModel = root.appendingPathComponent("Core/Models/EmailMessage.swift")
        let mockEmail = root.appendingPathComponent("Mocks/MockEmail.swift")
        XCTAssertTrue(FileManager.default.fileExists(atPath: emailModel.path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: mockEmail.path))
    }

    func testArchitectureDiagramOmitsFinanceShoppingHealthKit() throws {
        let root = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let svgURL = root.appendingPathComponent("Assets/brand/architecture.svg")
        let svg = try String(contentsOf: svgURL, encoding: .utf8)
        XCTAssertFalse(svg.contains(">Finance<"))
        XCTAssertFalse(svg.contains(">Shopping<"))
        XCTAssertFalse(svg.contains("HealthKit"))
        XCTAssertFalse(svg.contains("Spend anomalies"))
    }

    func testOnboardingCopyDoesNotMentionMoneyMovement() throws {
        let root = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let path = root.appendingPathComponent("Features/Onboarding/OnboardingStep.swift")
        let source = try String(contentsOf: path, encoding: .utf8)
        XCTAssertFalse(source.contains("moves money"))
    }
}
