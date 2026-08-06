import LifePilotCore
import LifePilotGhostBrain
import LifePilotMocks
import LifePilotServices

/// The composition root: wires concrete implementations to the protocols
/// `Features` depend on, per docs/ENGINEERING_GUIDE.md's Dependency
/// Injection standard: "A lightweight composition root in App/ wires
/// concrete implementations to their protocols at app launch."
///
/// In this phase, `ghostBrain` is always `MockRecommendationProvider` -
/// swapping in the real `GhostBrainService` (docs/MASTER_ROADMAP.md Phase
/// 5) is a one-line change here, with no change required in `Features`.
public struct AppDependencies: Sendable {
    public let ghostBrain: GhostBrainServing
    public let taskStore: any TaskStore
    public let eventStore: any EventStore
    public let preferenceStore: any PreferenceStore
    public let approvalStore: any ApprovalStore
    public let notificationScheduler: any NotificationScheduling
    public let calendarIntegration: any CalendarIntegrating
    public let weatherIntegration: any WeatherIntegrating
    public let travelIntegration: any TravelTimeIntegrating

    public init(
        ghostBrain: GhostBrainServing = MockRecommendationProvider(),
        taskStore: any TaskStore = InMemoryTaskStore(),
        eventStore: any EventStore = InMemoryEventStore(),
        preferenceStore: any PreferenceStore = InMemoryPreferenceStore(),
        approvalStore: any ApprovalStore = InMemoryApprovalStore(),
        notificationScheduler: any NotificationScheduling = NoOpNotificationScheduler(),
        calendarIntegration: any CalendarIntegrating = UnavailableCalendarIntegration(),
        weatherIntegration: any WeatherIntegrating = UnavailableWeatherIntegration(),
        travelIntegration: any TravelTimeIntegrating = UnavailableTravelTimeIntegration()
    ) {
        self.ghostBrain = ghostBrain
        self.taskStore = taskStore
        self.eventStore = eventStore
        self.preferenceStore = preferenceStore
        self.approvalStore = approvalStore
        self.notificationScheduler = notificationScheduler
        self.calendarIntegration = calendarIntegration
        self.weatherIntegration = weatherIntegration
        self.travelIntegration = travelIntegration
    }

    /// The default, production-shaped set of dependencies for this phase.
    public static let live = AppDependencies()

    public static let preview = AppDependencies(
        taskStore: InMemoryTaskStore(seed: MockTasks.items()),
        eventStore: InMemoryEventStore(seed: MockCalendar.events())
    )
}
