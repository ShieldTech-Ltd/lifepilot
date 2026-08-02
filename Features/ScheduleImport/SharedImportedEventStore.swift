import Foundation
import LifePilotCore

public enum SharedImportedEventStore {
    public static func load() -> [CalendarEvent] {
        guard
            let defaults = UserDefaults(suiteName: UpcomingEventWidgetStore.appGroupIdentifier),
            let data = defaults.data(forKey: StorageKey.importedCalendarEvents)
        else { return [] }
        return (try? JSONDecoder().decode([CalendarEvent].self, from: data)) ?? []
    }

    public static func add(_ event: CalendarEvent) {
        var events = load()
        events.removeAll { $0.id == event.id }
        events.append(event)
        replace(events)
    }

    public static func replace(_ events: [CalendarEvent]) {
        guard let defaults = UserDefaults(suiteName: UpcomingEventWidgetStore.appGroupIdentifier) else { return }
        let sortedEvents = events.sorted { $0.startDate < $1.startDate }
        defaults.set(try? JSONEncoder().encode(sortedEvents), forKey: StorageKey.importedCalendarEvents)
        defaults.synchronize()
    }

    public static func clear() {
        guard let defaults = UserDefaults(suiteName: UpcomingEventWidgetStore.appGroupIdentifier) else { return }
        defaults.removeObject(forKey: StorageKey.importedCalendarEvents)
        defaults.synchronize()
    }
}
