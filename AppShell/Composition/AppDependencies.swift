import LifePilotGhostBrain
import LifePilotServices

/// The composition root: wires concrete implementations to the protocols
/// `Features` depend on, per docs/ENGINEERING_GUIDE.md's Dependency
/// Injection standard: "A lightweight composition root in App/ wires
/// concrete implementations to their protocols at app launch."
///
/// `live` now wires the real `GhostBrainService`, backed by
/// `EventKitCalendarReader` — the first non-mock data source in the app
/// (docs/MASTER_ROADMAP.md Phase 7's calendar integration, feeding Phase
/// 5's reasoning seam). `MockRecommendationProvider` remains available via
/// `preview` for SwiftUI Previews and any context without Calendar access.
public struct AppDependencies: Sendable {
    public let ghostBrain: GhostBrainServing

    public init(ghostBrain: GhostBrainServing) {
        self.ghostBrain = ghostBrain
    }

    /// The production set of dependencies: real calendar data, rule-based
    /// Ghost Brain reasoning.
    public static let live = AppDependencies(
        ghostBrain: GhostBrainService(
            calendarReader: EventKitCalendarReader(),
            userFirstName: "Alex"
        )
    )

    /// Mock-backed dependencies for Previews and contexts where prompting
    /// for Calendar access isn't appropriate.
    public static let preview = AppDependencies(ghostBrain: MockRecommendationProvider())
}
