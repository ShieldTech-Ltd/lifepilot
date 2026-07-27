import Foundation

/// Read-only access to the user's calendar, implemented by an adapter in
/// `LifePilotServices` (e.g. an EventKit-backed reader) and consumed by
/// `LifePilotGhostBrain`. Defined here, in `Core`, per
/// docs/ENGINEERING_GUIDE.md: "protocols are defined in the layer that
/// consumes them" — Ghost Brain depends on this abstraction, never on a
/// concrete framework type.
public protocol CalendarReading: Sendable {
    /// Events occurring on the given calendar day, in `startDate` order.
    func events(on date: Date) async throws -> [CalendarEvent]
}
