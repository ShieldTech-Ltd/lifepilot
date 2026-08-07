import Foundation
import LifePilotCore
#if canImport(WidgetKit)
import WidgetKit
#endif

public struct UpcomingEventSnapshot: Codable, Equatable, Sendable {
    public let title: String
    public let location: String
    public let startDate: Date
    public let endDate: Date
    public let readiness: Int?
    public let pendingActions: Int?

    public init(
        title: String,
        location: String,
        startDate: Date,
        endDate: Date,
        readiness: Int? = nil,
        pendingActions: Int? = nil
    ) {
        self.title = title
        self.location = location
        self.startDate = startDate
        self.endDate = endDate
        self.readiness = readiness
        self.pendingActions = pendingActions
    }
}

public enum UpcomingEventWidgetStore {
    public static let appGroupIdentifier = "group.com.ritiksah.lifepilot"
    private static let storageKey = "upcomingEvent"

    public static func save(event: CalendarEvent?, readiness: Int? = nil, pendingActions: Int? = nil) {
        guard let defaults = UserDefaults(suiteName: appGroupIdentifier) else { return }
        if let event {
            let existing = load()
            let snapshot = UpcomingEventSnapshot(
                title: event.title,
                location: event.location ?? "",
                startDate: event.startDate,
                endDate: event.endDate,
                readiness: readiness ?? existing?.readiness,
                pendingActions: pendingActions ?? existing?.pendingActions
            )
            defaults.set(try? JSONEncoder().encode(snapshot), forKey: storageKey)
        } else {
            defaults.removeObject(forKey: storageKey)
        }
        defaults.synchronize()
        #if canImport(WidgetKit)
        WidgetCenter.shared.reloadTimelines(ofKind: "LifePilotBriefingWidget")
        #endif
    }

    public static func load() -> UpcomingEventSnapshot? {
        guard
            let defaults = UserDefaults(suiteName: appGroupIdentifier),
            let data = defaults.data(forKey: storageKey)
        else { return nil }
        return try? JSONDecoder().decode(UpcomingEventSnapshot.self, from: data)
    }
}
