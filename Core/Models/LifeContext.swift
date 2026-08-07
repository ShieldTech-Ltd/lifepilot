import Foundation

/// Life context for tasks, events, and preferences. Separates personal and work
/// surfaces without requiring accounts.
public enum LifeContext: String, CaseIterable, Hashable, Sendable, Codable {
    case personal
    case work
    case shared
    case `private`
}

/// Where a record originated and whether LifePilot or an external system owns it.
public enum DataSource: String, CaseIterable, Hashable, Sendable, Codable {
    case local
    case eventKitCalendar
    case eventKitReminders
    case userImport
    case shareSheet
    case planning
}

/// Sync / availability status of a connected source.
public enum SyncState: String, CaseIterable, Hashable, Sendable, Codable {
    case localOnly
    case synced
    case pendingWrite
    case conflict
    case unavailable
}
