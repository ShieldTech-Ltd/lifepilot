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
public final class DemoSessionStore { // swiftlint:disable:this type_body_length
    public private(set) var model: GhostBrainModel?
    public private(set) var activities: [DemoActivity] = []
    public private(set) var emailMessages: [EmailMessage] = []
    public private(set) var tasks: [TaskItem] = []
    public private(set) var travelItineraries: [TravelItinerary] = []
    public private(set) var importedEvents: [CalendarEvent] = []
    public private(set) var isLoading = false
    public private(set) var loadErrorMessage: String?

    public private(set) var displayName: String
    public private(set) var email: String
    public private(set) var course: String
    public private(set) var university: String
    public private(set) var location: String
    public private(set) var briefingTime: String
    public private(set) var profileImageData: Data?
    public private(set) var passwordUpdatedAt: Date?
    public private(set) var appearancePreference: AppearancePreference

    public private(set) var calendarEnabled: Bool
    public private(set) var emailEnabled: Bool
    public private(set) var travelEnabled: Bool
    public private(set) var financeEnabled: Bool
    public private(set) var notifyOnHighRisk: Bool

    public var timelineFilter: TimelineFilter = .all

    private let ghostBrain: GhostBrainServing
    private let defaults: UserDefaults
    private var resolvedRecommendationKeys: Set<String> = []

    public init(
        ghostBrain: GhostBrainServing = MockRecommendationProvider(),
        defaults: UserDefaults = .standard
    ) {
        self.ghostBrain = ghostBrain
        self.defaults = defaults
        displayName = defaults.string(forKey: StorageKey.profileDisplayName) ?? "Ritik Sah"
        email = defaults.string(forKey: StorageKey.profileEmail) ?? "ritik.sah@example.com"
        course = defaults.string(forKey: StorageKey.profileCourse) ?? "BSc Computing"
        university = defaults.string(forKey: StorageKey.profileUniversity) ?? "Ulster University London"
        location = defaults.string(forKey: StorageKey.profileLocation) ?? "London"
        briefingTime = defaults.string(forKey: StorageKey.profileBriefingTime) ?? "08:00"
        profileImageData = defaults.data(forKey: StorageKey.profileImageData)
        passwordUpdatedAt = defaults.object(forKey: StorageKey.passwordUpdatedAt) as? Date
        appearancePreference = AppearancePreference(
            rawValue: defaults.string(forKey: StorageKey.appearancePreference) ?? ""
        ) ?? .system
        calendarEnabled = Self.boolValue(defaults, key: StorageKey.connectedCalendar, fallback: true)
        emailEnabled = Self.boolValue(defaults, key: StorageKey.connectedEmail, fallback: true)
        travelEnabled = Self.boolValue(defaults, key: StorageKey.connectedTravel, fallback: true)
        financeEnabled = Self.boolValue(defaults, key: StorageKey.connectedFinance, fallback: true)
        notifyOnHighRisk = Self.boolValue(defaults, key: StorageKey.approvalsNotifyOnHighRisk, fallback: true)
        if let data = defaults.data(forKey: StorageKey.importedCalendarEvents) {
            importedEvents = (try? JSONDecoder().decode([CalendarEvent].self, from: data)) ?? []
        } else if defaults === UserDefaults.standard {
            importedEvents = SharedImportedEventStore.load()
        }
        if let data = defaults.data(forKey: StorageKey.approvalHistory) {
            activities = (try? JSONDecoder().decode([DemoActivity].self, from: data)) ?? []
        }
        resolvedRecommendationKeys = Set(defaults.stringArray(forKey: StorageKey.resolvedRecommendationKeys) ?? [])
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
            !resolvedRecommendationKeys.contains(resolutionKey(for: $0)) && isEnabled($0.sourceAgent)
        }
    }

    public var visibleEvents: [CalendarEvent] {
        let connectedEvents = calendarEnabled ? model?.upcomingEvents ?? [] : []
        return (connectedEvents + importedEvents).sorted { $0.startDate < $1.startDate }
    }

    public var visibleSignals: [DaySignal] {
        (model?.signals ?? []).filter { isEnabled($0.sourceAgent) }
    }

    public var readinessProgress: Double {
        guard isPrepared else { return 0.08 }
        let total = activities.count + availableRecommendations.count
        let reviewedRatio = total == 0 ? 1 : Double(activities.count) / Double(total)
        let sourceRatio = Double(connectedSourceCount) / 4
        return min(1, 0.52 + sourceRatio * 0.18 + reviewedRatio * 0.3)
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
            publishNextEvent()
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
        resolvedRecommendationKeys.insert(resolutionKey(for: recommendation))
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
        persistApprovalHistory()
        publishNextEvent()
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
        publishNextEvent()
    }

    public func setNotifyOnHighRisk(_ isEnabled: Bool) {
        notifyOnHighRisk = isEnabled
        defaults.set(isEnabled, forKey: StorageKey.approvalsNotifyOnHighRisk)
    }

    public func setAppearancePreference(_ preference: AppearancePreference) {
        appearancePreference = preference
        defaults.set(preference.rawValue, forKey: StorageKey.appearancePreference)
    }

    public func updateProfileImage(_ data: Data?) {
        profileImageData = data
        if let data {
            defaults.set(data, forKey: StorageKey.profileImageData)
        } else {
            defaults.removeObject(forKey: StorageKey.profileImageData)
        }
    }

    public func recordPasswordUpdate(at date: Date = Date()) {
        passwordUpdatedAt = date
        defaults.set(date, forKey: StorageKey.passwordUpdatedAt)
    }

    public func addImportedEvent(_ event: CalendarEvent) {
        importedEvents.append(event)
        importedEvents.sort { $0.startDate < $1.startDate }
        defaults.set(try? JSONEncoder().encode(importedEvents), forKey: StorageKey.importedCalendarEvents)
        if defaults === UserDefaults.standard {
            SharedImportedEventStore.replace(importedEvents)
        }
        publishNextEvent()
    }

    public func reloadSharedEvents() {
        guard defaults === UserDefaults.standard else { return }
        importedEvents = SharedImportedEventStore.load()
        defaults.set(try? JSONEncoder().encode(importedEvents), forKey: StorageKey.importedCalendarEvents)
        publishNextEvent()
    }

    public func refreshLiveExperiences() {
        publishNextEvent()
    }

    public func updateProfile(
        displayName: String,
        email: String,
        course: String,
        university: String,
        location: String,
        briefingTime: String
    ) { // swiftlint:disable:this function_parameter_count
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
        displayName = "Ritik Sah"
        email = "ritik.sah@example.com"
        course = "BSc Computing"
        university = "Ulster University London"
        location = "London"
        briefingTime = "08:00"
        profileImageData = nil
        passwordUpdatedAt = nil
        appearancePreference = .system
        calendarEnabled = true
        emailEnabled = true
        travelEnabled = true
        financeEnabled = true
        notifyOnHighRisk = true
        resolvedRecommendationKeys = []
        activities = []
        importedEvents = []
        timelineFilter = .all
        if defaults === UserDefaults.standard {
            SharedImportedEventStore.clear()
        }
        publishNextEvent()
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

    private func publishNextEvent(now: Date = Date()) {
        let nextEvent = visibleEvents
            .filter { $0.endDate > now }
            .min { $0.startDate < $1.startDate }
        UpcomingEventWidgetStore.save(
            event: nextEvent,
            readiness: Int(readinessProgress * 100),
            pendingActions: availableRecommendations.count
        )
    }

    private func resolutionKey(for recommendation: RecommendationModel) -> String {
        "\(recommendation.sourceAgent.rawValue)|\(recommendation.title)"
    }

    private func persistApprovalHistory() {
        defaults.set(try? JSONEncoder().encode(activities), forKey: StorageKey.approvalHistory)
        defaults.set(resolvedRecommendationKeys.sorted(), forKey: StorageKey.resolvedRecommendationKeys)
    }

    private static func boolValue(_ defaults: UserDefaults, key: String, fallback: Bool) -> Bool {
        defaults.object(forKey: key) == nil ? fallback : defaults.bool(forKey: key)
    }
}

public struct DemoActivity: Codable, Identifiable, Hashable, Sendable {
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

public enum AppearancePreference: String, CaseIterable, Identifiable, Hashable, Sendable {
    case system
    case light
    case dark

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .system: "System"
        case .light: "Light"
        case .dark: "Dark"
        }
    }

    public var symbolName: String {
        switch self {
        case .system: "circle.lefthalf.filled"
        case .light: "sun.max.fill"
        case .dark: "moon.stars.fill"
        }
    }
}
