import Foundation
import LifePilotCore
import LifePilotGhostBrain
import LifePilotMocks

/// Shared, app-wide state. Production composition injects durable stores and
/// authorized system integrations; previews and tests can omit them and use
/// the deterministic mock provider.
@Observable
@MainActor
public final class DemoSessionStore { // swiftlint:disable:this type_body_length
    public private(set) var model: GhostBrainModel?
    public private(set) var activities: [DemoActivity] = []
    public private(set) var emailMessages: [EmailMessage] = []
    public private(set) var tasks: [TaskItem] = []
    public private(set) var travelItineraries: [TravelItinerary] = []
    public private(set) var importedEvents: [CalendarEvent] = []
    public private(set) var memoryItems: [MemoryItem] = []
    public private(set) var isLoading = false
    public private(set) var loadErrorMessage: String?
    public private(set) var permissionStates: [String: PermissionState] = [:]

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
    public private(set) var notifyOnHighRisk: Bool

    public var timelineFilter: TimelineFilter = .all
    public let permissions: PermissionDependencies

    private let ghostBrain: GhostBrainServing
    private let taskStore: (any TaskStore)?
    private let eventStore: (any EventStore)?
    private let preferenceStore: (any PreferenceStore)?
    private let approvalStore: (any ApprovalStore)?
    private let remindersIntegration: (any RemindersIntegrating)?
    private let notificationScheduler: (any NotificationScheduling)?
    private let isLiveSession: Bool
    private let defaults: UserDefaults
    private var resolvedRecommendationKeys: Set<String> = []

    public init(
        ghostBrain: GhostBrainServing = MockRecommendationProvider(),
        taskStore: (any TaskStore)? = nil,
        eventStore: (any EventStore)? = nil,
        preferenceStore: (any PreferenceStore)? = nil,
        approvalStore: (any ApprovalStore)? = nil,
        remindersIntegration: (any RemindersIntegrating)? = nil,
        notificationScheduler: (any NotificationScheduling)? = nil,
        permissions: PermissionDependencies = PermissionDependencies(),
        defaults: UserDefaults = .standard
    ) {
        self.ghostBrain = ghostBrain
        self.taskStore = taskStore
        self.eventStore = eventStore
        self.preferenceStore = preferenceStore
        self.approvalStore = approvalStore
        self.remindersIntegration = remindersIntegration
        self.notificationScheduler = notificationScheduler
        self.permissions = permissions
        self.defaults = defaults
        let usesLiveStores = taskStore != nil || eventStore != nil || preferenceStore != nil
        isLiveSession = usesLiveStores
        displayName = defaults.string(forKey: StorageKey.profileDisplayName) ?? (usesLiveStores ? "You" : "Alex")
        email = defaults.string(forKey: StorageKey.profileEmail) ?? (usesLiveStores ? "" : "alex@example.com")
        course = defaults.string(forKey: StorageKey.profileCourse) ?? "Daily routine"
        university = defaults.string(forKey: StorageKey.profileUniversity) ?? "Personal"
        location = defaults.string(forKey: StorageKey.profileLocation) ?? (usesLiveStores ? "" : "London")
        briefingTime = defaults.string(forKey: StorageKey.profileBriefingTime) ?? "08:00"
        profileImageData = defaults.data(forKey: StorageKey.profileImageData)
        passwordUpdatedAt = defaults.object(forKey: StorageKey.passwordUpdatedAt) as? Date
        appearancePreference = AppearancePreference(
            rawValue: defaults.string(forKey: StorageKey.appearancePreference) ?? ""
        ) ?? .system
        calendarEnabled = Self.boolValue(defaults, key: StorageKey.connectedCalendar, fallback: true)
        emailEnabled = false
        travelEnabled = Self.boolValue(defaults, key: StorageKey.connectedTravel, fallback: true)
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

    public var taskDataStore: (any TaskStore)? { taskStore }

    public var taskNotificationCoordinator: TaskNotificationCoordinator? {
        guard let notificationScheduler, let preferenceStore else { return nil }
        return TaskNotificationCoordinator(
            scheduler: notificationScheduler,
            preferenceStore: preferenceStore
        )
    }

    public var firstName: String {
        displayName.split(separator: " ").first.map(String.init) ?? "there"
    }

    public var connectedSourceCount: Int {
        if isLiveSession {
            return permissionStates.values.filter { $0 == .authorized || $0 == .limited }.count
        }
        [calendarEnabled, travelEnabled].filter { $0 }.count
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
        let sourceRatio = Double(connectedSourceCount) / 2
        return min(1, 0.52 + sourceRatio * 0.18 + reviewedRatio * 0.3)
    }

    public func prepare() async {
        guard model == nil, !isLoading else { return }
        isLoading = true
        loadErrorMessage = nil
        defer { isLoading = false }

        do {
            if isLiveSession {
                await refreshPermissionStates()
            }
            let loadedModel = try await ghostBrain.currentModel()
            model = loadedModel
            if let taskStore {
                tasks = await liveTasks(from: taskStore)
                emailMessages = []
                travelItineraries = []
            } else {
                let now = loadedModel.generatedAt
                emailMessages = MockEmail.messages(relativeTo: now)
                tasks = MockTasks.items(relativeTo: now)
                travelItineraries = MockTravel.itineraries(relativeTo: now)
            }
            if let eventStore {
                let storedEvents = await eventStore.allEvents()
                importedEvents = Self.mergeEvents(importedEvents, storedEvents)
            }
            if let preferenceStore {
                memoryItems = await preferenceStore.allMemory()
            }
            publishNextEvent()
        } catch {
            loadErrorMessage = "Your day could not be prepared. Try again."
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
        persistApprovalAudit(recommendation: recommendation, approved: approved)
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
        if let eventStore {
            Task { try? await eventStore.save(event) }
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

    // swiftlint:disable:next function_parameter_count
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

    public func resetLocalState() {
        for key in StorageKey.all {
            defaults.removeObject(forKey: key)
        }
        let usesLiveStores = taskStore != nil || eventStore != nil || preferenceStore != nil
        displayName = usesLiveStores ? "You" : "Alex"
        email = usesLiveStores ? "" : "alex@example.com"
        course = "Daily routine"
        university = "Personal"
        location = usesLiveStores ? "" : "London"
        briefingTime = "08:00"
        profileImageData = nil
        passwordUpdatedAt = nil
        appearancePreference = .system
        calendarEnabled = true
        emailEnabled = false
        travelEnabled = true
        notifyOnHighRisk = true
        resolvedRecommendationKeys = []
        activities = []
        importedEvents = []
        memoryItems = []
        timelineFilter = .all
        if defaults === UserDefaults.standard {
            SharedImportedEventStore.clear()
        }
        if preferenceStore != nil || notificationScheduler != nil {
            Task {
                try? await preferenceStore?.deleteAllLifePilotData()
                try? await notificationScheduler?.cancelAll()
            }
        }
        publishNextEvent()
    }

    public func refreshPermissionStates() async {
        for kind in PermissionKind.allCases {
            permissionStates[kind.rawValue] = await permissions.state(for: kind)
        }
    }

    @discardableResult
    public func requestPermission(_ kind: PermissionKind) async throws -> PermissionState {
        let state = try await permissions.request(kind)
        permissionStates[kind.rawValue] = state
        if kind == .calendar || kind == .reminders {
            model = nil
            await prepare()
        }
        return state
    }

    @available(*, deprecated, renamed: "resetLocalState")
    public func resetLocalDemoState() {
        resetLocalState()
    }

    public func isEnabled(_ agent: AgentKind) -> Bool {
        switch agent {
        case .calendar: calendarEnabled
        case .email: emailEnabled
        case .travel: travelEnabled
        default: true
        }
    }

    private func executionResult(for _: RecommendationModel) -> String {
        "Approval recorded. No external change was made."
    }

    private func liveTasks(from taskStore: any TaskStore) async -> [TaskItem] {
        let local = await taskStore.allTasks()
        guard let remindersIntegration else { return local }
        let state = await remindersIntegration.authorizationState()
        guard state == .authorized || state == .limited,
              let reminders = try? await remindersIntegration.fetchOpenReminders()
        else { return local }
        var existingByExternal: [String: TaskItem] = [:]
        for task in local {
            if let identifier = task.externalIdentifier {
                existingByExternal[identifier] = task
            }
        }
        let remoteIdentifiers = Set(reminders.compactMap(\.externalIdentifier))
        for task in local where task.source == .eventKitReminders {
            guard let identifier = task.externalIdentifier,
                  !remoteIdentifiers.contains(identifier)
            else { continue }
            try? await taskStore.delete(id: task.id)
            existingByExternal.removeValue(forKey: identifier)
        }
        for reminder in reminders {
            var reconciled = reminder
            if let identifier = reminder.externalIdentifier,
               let existing = existingByExternal[identifier]
            {
                reconciled = TaskItem(
                    id: existing.id,
                    title: reminder.title,
                    notes: reminder.notes,
                    dueDate: reminder.dueDate,
                    isCompleted: reminder.isCompleted,
                    completedAt: reminder.completedAt,
                    recurrence: reminder.recurrence,
                    source: .eventKitReminders,
                    externalIdentifier: identifier,
                    syncState: .synced,
                    createdAt: existing.createdAt,
                    updatedAt: Date()
                )
            }
            try? await taskStore.save(reconciled)
        }
        return await taskStore.allTasks()
    }

    private static func mergeEvents(_ first: [CalendarEvent], _ second: [CalendarEvent]) -> [CalendarEvent] {
        var result = first
        let knownIDs = Set(first.map(\.id))
        result.append(contentsOf: second.filter { !knownIDs.contains($0.id) })
        return result.sorted { $0.startDate < $1.startDate }
    }

    private func persistApprovalAudit(recommendation: RecommendationModel, approved: Bool) {
        guard let approvalStore else { return }
        Task {
            try? await approvalStore.appendAudit(AuditEvent(
                category: "recommendation-decision",
                summary: approved ? "Recommendation approved" : "Recommendation dismissed",
                proposalID: recommendation.id,
                success: true
            ))
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
