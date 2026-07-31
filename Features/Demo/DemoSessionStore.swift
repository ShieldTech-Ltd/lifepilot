import Foundation
import LifePilotCore
import LifePilotGhostBrain
import LifePilotMocks

/// Shared, app-wide state for the TechFest prototype. It gives every tab
/// one coherent model of the day while keeping the external integrations
/// explicitly simulated. Replacing this store with live services does not
/// require changing the presentation flow.
@Observable
@MainActor
public final class DemoSessionStore {
    public private(set) var model: GhostBrainModel?
    public private(set) var activities: [DemoActivity] = []
    public private(set) var emailMessages: [EmailMessage] = []
    public private(set) var tasks: [TaskItem] = []
    public private(set) var travelItineraries: [TravelItinerary] = []
    public private(set) var isLoading = false
    public private(set) var loadErrorMessage: String?

    public private(set) var displayName: String
    public private(set) var email: String
    public private(set) var course: String
    public private(set) var university: String
    public private(set) var location: String
    public private(set) var briefingTime: String

    public private(set) var calendarEnabled: Bool
    public private(set) var emailEnabled: Bool
    public private(set) var travelEnabled: Bool
    public private(set) var financeEnabled: Bool
    public private(set) var notifyOnHighRisk: Bool

    public var timelineFilter: TimelineFilter = .all

    private let ghostBrain: GhostBrainServing
    private let defaults: UserDefaults
    private var resolvedRecommendationIDs: Set<UUID> = []

    public init(
        ghostBrain: GhostBrainServing = MockRecommendationProvider(),
        defaults: UserDefaults = .standard
    ) {
        self.ghostBrain = ghostBrain
        self.defaults = defaults
        displayName = defaults.string(forKey: StorageKey.profileDisplayName) ?? "Alex Morgan"
        email = defaults.string(forKey: StorageKey.profileEmail) ?? "alex@example.com"
        course = defaults.string(forKey: StorageKey.profileCourse) ?? "MSc Computing"
        university = defaults.string(forKey: StorageKey.profileUniversity) ?? "Ulster University London"
        location = defaults.string(forKey: StorageKey.profileLocation) ?? "London"
        briefingTime = defaults.string(forKey: StorageKey.profileBriefingTime) ?? "8:00 AM"
        calendarEnabled = Self.boolValue(defaults, key: StorageKey.connectedCalendar, fallback: true)
        emailEnabled = Self.boolValue(defaults, key: StorageKey.connectedEmail, fallback: true)
        travelEnabled = Self.boolValue(defaults, key: StorageKey.connectedTravel, fallback: true)
        financeEnabled = Self.boolValue(defaults, key: StorageKey.connectedFinance, fallback: true)
        notifyOnHighRisk = Self.boolValue(defaults, key: StorageKey.approvalsNotifyOnHighRisk, fallback: true)
    }

    public var isPrepared: Bool { model != nil }

    public var firstName: String {
        displayName.split(separator: " ").first.map(String.init) ?? "there"
    }

    public var connectedSourceCount: Int {
        [calendarEnabled, emailEnabled, travelEnabled, financeEnabled].filter { $0 }.count
    }

    public var availableRecommendations: [RecommendationModel] {
        guard let model else { return [] }
        return model.rankedRecommendations.filter {
            !resolvedRecommendationIDs.contains($0.id) && isEnabled($0.sourceAgent)
        }
    }

    public var visibleEvents: [CalendarEvent] {
        calendarEnabled ? model?.upcomingEvents ?? [] : []
    }

    public var visibleSignals: [DaySignal] {
        (model?.signals ?? []).filter { isEnabled($0.sourceAgent) }
    }

    public func prepare() async {
        guard model == nil, !isLoading else { return }
        isLoading = true
        loadErrorMessage = nil
        defer { isLoading = false }

        do {
            let loadedModel = try await ghostBrain.currentModel()
            model = loadedModel
            let now = loadedModel.generatedAt
            emailMessages = MockEmail.messages(relativeTo: now)
            tasks = MockTasks.items(relativeTo: now)
            travelItineraries = MockTravel.itineraries(relativeTo: now)
        } catch {
            loadErrorMessage = "The demo day could not be prepared. Try again."
        }
    }

    public func retry() async {
        model = nil
        await prepare()
    }

    public func resolve(_ recommendationID: UUID, approved: Bool) {
        guard let recommendation = model?.recommendations.first(where: { $0.id == recommendationID }) else { return }
        resolvedRecommendationIDs.insert(recommendationID)
        activities.insert(
            DemoActivity(
                recommendationID: recommendationID,
                title: recommendation.title,
                result: approved ? executionResult(for: recommendation) : "Recommendation dismissed",
                sourceAgent: recommendation.sourceAgent,
                wasApproved: approved,
                resolvedAt: Date()
            ),
            at: 0
        )
    }

    public func setConnection(_ agent: AgentKind, isEnabled: Bool) {
        switch agent {
        case .calendar:
            calendarEnabled = isEnabled
            defaults.set(isEnabled, forKey: StorageKey.connectedCalendar)
        case .email:
            emailEnabled = isEnabled
            defaults.set(isEnabled, forKey: StorageKey.connectedEmail)
        case .travel:
            travelEnabled = isEnabled
            defaults.set(isEnabled, forKey: StorageKey.connectedTravel)
        case .finance:
            financeEnabled = isEnabled
            defaults.set(isEnabled, forKey: StorageKey.connectedFinance)
        default:
            break
        }
    }

    public func setNotifyOnHighRisk(_ isEnabled: Bool) {
        notifyOnHighRisk = isEnabled
        defaults.set(isEnabled, forKey: StorageKey.approvalsNotifyOnHighRisk)
    }

    public func updateProfile(
        displayName: String,
        email: String,
        course: String,
        university: String,
        location: String,
        briefingTime: String
    ) {
        self.displayName = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        self.email = email.trimmingCharacters(in: .whitespacesAndNewlines)
        self.course = course.trimmingCharacters(in: .whitespacesAndNewlines)
        self.university = university.trimmingCharacters(in: .whitespacesAndNewlines)
        self.location = location.trimmingCharacters(in: .whitespacesAndNewlines)
        self.briefingTime = briefingTime

        defaults.set(self.displayName, forKey: StorageKey.profileDisplayName)
        defaults.set(self.email, forKey: StorageKey.profileEmail)
        defaults.set(self.course, forKey: StorageKey.profileCourse)
        defaults.set(self.university, forKey: StorageKey.profileUniversity)
        defaults.set(self.location, forKey: StorageKey.profileLocation)
        defaults.set(self.briefingTime, forKey: StorageKey.profileBriefingTime)
    }

    public func resetLocalDemoState() {
        for key in StorageKey.all {
            defaults.removeObject(forKey: key)
        }
        displayName = "Alex Morgan"
        email = "alex@example.com"
        course = "MSc Computing"
        university = "Ulster University London"
        location = "London"
        briefingTime = "8:00 AM"
        calendarEnabled = true
        emailEnabled = true
        travelEnabled = true
        financeEnabled = true
        notifyOnHighRisk = true
        resolvedRecommendationIDs = []
        activities = []
        timelineFilter = .all
    }

    public func isEnabled(_ agent: AgentKind) -> Bool {
        switch agent {
        case .calendar: calendarEnabled
        case .email: emailEnabled
        case .travel: travelEnabled
        case .finance: financeEnabled
        default: true
        }
    }

    private func executionResult(for recommendation: RecommendationModel) -> String {
        switch recommendation.sourceAgent {
        case .calendar: "Calendar buffer added in demo timeline"
        case .email: "Reply draft prepared in demo inbox"
        case .travel: "Delay update shared in demo itinerary"
        case .finance: "Transaction flagged for review"
        default: "Action completed in demo mode"
        }
    }

    private static func boolValue(_ defaults: UserDefaults, key: String, fallback: Bool) -> Bool {
        defaults.object(forKey: key) == nil ? fallback : defaults.bool(forKey: key)
    }
}

public struct DemoActivity: Identifiable, Hashable, Sendable {
    public let id: UUID
    public let recommendationID: UUID
    public let title: String
    public let result: String
    public let sourceAgent: AgentKind
    public let wasApproved: Bool
    public let resolvedAt: Date

    public init(
        id: UUID = UUID(),
        recommendationID: UUID,
        title: String,
        result: String,
        sourceAgent: AgentKind,
        wasApproved: Bool,
        resolvedAt: Date
    ) {
        self.id = id
        self.recommendationID = recommendationID
        self.title = title
        self.result = result
        self.sourceAgent = sourceAgent
        self.wasApproved = wasApproved
        self.resolvedAt = resolvedAt
    }
}

public enum TimelineFilter: String, CaseIterable, Identifiable, Hashable, Sendable {
    case all = "All"
    case calendar = "Calendar"
    case email = "Inbox"
    case task = "Tasks"
    case travel = "Travel"
    case action = "Actions"

    public var id: String { rawValue }
}
