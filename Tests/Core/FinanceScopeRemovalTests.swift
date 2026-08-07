import XCTest
@testable import LifePilotCore

/// Guarantees finance is outside the product while unsafe external actions remain denied.
final class FinanceScopeRemovalTests: XCTestCase {
    func testFinanceAgentIsNotAvailable() {
        let raw = Set(AgentKind.allCases.map(\.rawValue))
        XCTAssertFalse(raw.contains("finance"))
        XCTAssertFalse(raw.contains("bank"))
    }

    func testDaySignalKindsExcludeFinance() {
        let raw = Set(DaySignal.Kind.allCases.map(\.rawValue))
        XCTAssertFalse(raw.contains("finance"))
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
