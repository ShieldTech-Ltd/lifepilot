import LifePilotCore
import LifePilotGhostBrain
import LifePilotMocks
import LifePilotServices

/// The composition root: wires concrete implementations to the protocols
/// `Features` depend on, per docs/ENGINEERING_GUIDE.md's Dependency
/// Injection standard: "A lightweight composition root in App/ wires
/// concrete implementations to their protocols at app launch."
///
public struct AppDependencies: Sendable {
    public let ghostBrain: GhostBrainServing
    public let taskStore: any TaskStore
    public let eventStore: any EventStore
    public let preferenceStore: any PreferenceStore
    public let approvalStore: any ApprovalStore
    public let notificationScheduler: any NotificationScheduling
    public let calendarIntegration: any CalendarIntegrating
    public let remindersIntegration: any RemindersIntegrating
    public let locationProvider: any LocationProviding
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
        remindersIntegration: any RemindersIntegrating = UnavailableRemindersIntegration(),
        locationProvider: any LocationProviding = UnavailableLocationProvider(),
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
        self.remindersIntegration = remindersIntegration
        self.locationProvider = locationProvider
        self.weatherIntegration = weatherIntegration
        self.travelIntegration = travelIntegration
    }

    /// Production dependencies. iOS uses durable SwiftData plus system
    /// Calendar, Reminders, Notifications, Location, WeatherKit, and MapKit.
    public static let live = {
        let container = PersistenceController.shared.container
        let taskStore = SwiftDataTaskStore(container: container)
        let eventStore = SwiftDataEventStore(container: container)
        let preferenceStore = SwiftDataPreferenceStore(container: container)
        let approvalStore = SwiftDataApprovalStore(container: container)

        #if os(iOS)
        let calendar = EventKitCalendarIntegration()
        let reminders = EventKitRemindersIntegration()
        let location = SystemLocationProvider()
        let weather = WeatherKitIntegration(locationProvider: location)
        let notifications = UserNotificationsScheduler()
        let travel = MapKitTravelTimeIntegration()
        #else
        let calendar = UnavailableCalendarIntegration()
        let reminders = UnavailableRemindersIntegration()
        let location = UnavailableLocationProvider()
        let weather = UnavailableWeatherIntegration()
        let notifications = NoOpNotificationScheduler()
        let travel = UnavailableTravelTimeIntegration()
        #endif

        let ghostBrain = GhostBrainService(
            taskStore: taskStore,
            eventStore: eventStore,
            preferenceStore: preferenceStore,
            calendarIntegration: calendar,
            remindersIntegration: reminders,
            weatherIntegration: weather
        )
        return AppDependencies(
            ghostBrain: ghostBrain,
            taskStore: taskStore,
            eventStore: eventStore,
            preferenceStore: preferenceStore,
            approvalStore: approvalStore,
            notificationScheduler: notifications,
            calendarIntegration: calendar,
            remindersIntegration: reminders,
            locationProvider: location,
            weatherIntegration: weather,
            travelIntegration: travel
        )
    }()

    public static let preview = AppDependencies(
        taskStore: InMemoryTaskStore(seed: MockTasks.items()),
        eventStore: InMemoryEventStore(seed: MockCalendar.events())
    )
}
