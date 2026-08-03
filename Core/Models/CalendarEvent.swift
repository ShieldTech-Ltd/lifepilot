import Foundation

/// A calendar-shaped event. External EventKit records map into this shape;
/// LifePilot-owned local events use `source == .local`.
public struct CalendarEvent: Identifiable, Hashable, Sendable, Codable {
    public let id: UUID
    public var title: String
    public var notes: String?
    public var location: String?
    public var startDate: Date
    public var endDate: Date
    public var isAllDay: Bool
    public var attendeeCount: Int
    public var context: LifeContext
    public var eventKind: EventKind
    public var preparationMinutes: Int
    public var travelBufferMinutes: Int
    public var recurrence: RecurrenceRule?
    public var source: DataSource
    public var externalIdentifier: String?
    public var syncState: SyncState
    public var status: AttendanceStatus

    public init(
        id: UUID = UUID(),
        title: String,
        notes: String? = nil,
        location: String? = nil,
        startDate: Date,
        endDate: Date,
        isAllDay: Bool = false,
        attendeeCount: Int = 0,
        context: LifeContext = .personal,
        eventKind: EventKind = .personal,
        preparationMinutes: Int = 0,
        travelBufferMinutes: Int = 0,
        recurrence: RecurrenceRule? = nil,
        source: DataSource = .local,
        externalIdentifier: String? = nil,
        syncState: SyncState = .localOnly,
        status: AttendanceStatus = .confirmed
    ) {
        self.id = id
        self.title = title
        self.notes = notes
        self.location = location
        self.startDate = startDate
        self.endDate = endDate
        self.isAllDay = isAllDay
        self.attendeeCount = attendeeCount
        self.context = context
        self.eventKind = eventKind
        self.preparationMinutes = preparationMinutes
        self.travelBufferMinutes = travelBufferMinutes
        self.recurrence = recurrence
        self.source = source
        self.externalIdentifier = externalIdentifier
        self.syncState = syncState
        self.status = status
    }

    /// Whether this event's time window overlaps another's.
    public func overlaps(_ other: CalendarEvent) -> Bool {
        guard status != .declined, other.status != .declined else { return false }
        return startDate < other.endDate && other.startDate < endDate
    }

    /// Effective start including preparation and travel buffer.
    public var bufferedStart: Date {
        let minutes = preparationMinutes + travelBufferMinutes
        return startDate.addingTimeInterval(TimeInterval(-minutes * 60))
    }
}

public enum EventKind: String, CaseIterable, Hashable, Sendable, Codable {
    case personal
    case work
    case meeting
    case shift
    case focus
    case `break`
    case commute
    case availability
}

public enum AttendanceStatus: String, CaseIterable, Hashable, Sendable, Codable {
    case confirmed
    case tentative
    case declined
}
