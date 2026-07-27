import EventKit
import Foundation
import LifePilotCore

/// EventKit-backed `CalendarReading` adapter — the first real (non-mock)
/// integration in `LifePilotServices`, per docs/MASTER_ROADMAP.md Phase 7.
///
/// Per docs/ARCHITECTURE.md's Dependency Rules, this type is an adapter: it
/// translates `EKEvent` into the framework-agnostic `CalendarEvent` domain
/// model and never leaks `EventKit` types past this file.
public final class EventKitCalendarReader: CalendarReading, @unchecked Sendable {
    private let store: EKEventStore

    public init(store: EKEventStore = EKEventStore()) {
        self.store = store
    }

    /// Requests calendar access if not already determined. Safe to call
    /// repeatedly — EventKit only prompts the user once per app install.
    /// Callers should invoke this before the first `events(on:)` call,
    /// typically at app launch or when a calendar-dependent screen appears.
    @discardableResult
    public func requestAccess() async throws -> Bool {
        try await store.requestFullAccessToEvents()
    }

    public func events(on date: Date) async throws -> [CalendarEvent] {
        let status = EKEventStore.authorizationStatus(for: .event)
        switch status {
        case .fullAccess:
            break
        case .notDetermined:
            guard try await requestAccess() else {
                throw DomainError.unavailable("Calendar access was denied.")
            }
        case .denied, .restricted, .writeOnly:
            throw DomainError.unavailable("Calendar access is not authorized. Enable it in Settings.")
        @unknown default:
            throw DomainError.unavailable("Calendar access status is unknown.")
        }

        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else {
            throw DomainError.invalidState("Could not compute end of day for \(date).")
        }

        let predicate = store.predicateForEvents(withStart: startOfDay, end: endOfDay, calendars: nil)
        let ekEvents = store.events(matching: predicate)

        return ekEvents
            .map(Self.calendarEvent(from:))
            .sorted { $0.startDate < $1.startDate }
    }

    private static func calendarEvent(from ekEvent: EKEvent) -> CalendarEvent {
        CalendarEvent(
            title: ekEvent.title ?? "Untitled Event",
            location: ekEvent.location,
            startDate: ekEvent.startDate,
            endDate: ekEvent.endDate,
            isAllDay: ekEvent.isAllDay,
            attendeeCount: ekEvent.attendees?.count ?? 0
        )
    }
}
