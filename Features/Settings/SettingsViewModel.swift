import Foundation
import LifePilotCore

/// Builds Settings rows from the app session.
@Observable
@MainActor
public final class SettingsViewModel {
    public let session: DemoSessionStore
    public private(set) var preferences = UserPreferences()
    public private(set) var memoryCount = 0
    public private(set) var exportMessage: String?
    public private(set) var syncMessage: String?
    public private(set) var connectionMessage: String?
    public private(set) var transitMessage: String?
    public private(set) var cloudSyncEnabled = false
    public private(set) var connections: [ConnectionCapability]

    private let preferenceStore: (any PreferenceStore)?
    private let cloudSync: any CloudSyncIntegrating
    private let permissions: PermissionDependencies

    public init(session: DemoSessionStore) {
        self.session = session
        preferenceStore = nil
        cloudSync = DisabledCloudSyncIntegration()
        permissions = PermissionDependencies()
        connections = Self.defaultConnections
    }

    public convenience init() {
        self.init(session: DemoSessionStore())
    }

    public init(
        preferenceStore: any PreferenceStore,
        cloudSync: any CloudSyncIntegrating = DisabledCloudSyncIntegration(),
        permissions: PermissionDependencies = PermissionDependencies()
    ) {
        session = DemoSessionStore()
        self.preferenceStore = preferenceStore
        self.cloudSync = cloudSync
        self.permissions = permissions
        connections = Self.defaultConnections
    }

    public var sections: [SettingsSection] {
        [
            SettingsSection(id: "account", title: "Account", rows: [
                SettingsRow(
                    id: "profile",
                    symbolName: "person.crop.circle.fill",
                    title: "Profile",
                    detail: session.displayName,
                    destination: .profile
                ),
                SettingsRow(
                    id: "connected",
                    symbolName: "link",
                    title: "Connected Sources",
                    detail: "\(session.connectedSourceCount) active",
                    destination: .connectedApps
                ),
                SettingsRow(
                    id: "appearance",
                    symbolName: "circle.lefthalf.filled",
                    title: "Appearance",
                    detail: session.appearancePreference.title,
                    destination: .appearance
                ),
                SettingsRow(
                    id: "liveExperiences",
                    symbolName: "wave.3.right.circle",
                    title: "Live Activities",
                    detail: "Widgets ready",
                    destination: .liveExperiences
                ),
            ]),
            SettingsSection(id: "privacy", title: "Privacy & Control", rows: [
                SettingsRow(
                    id: "approvals",
                    symbolName: "checkmark.shield.fill",
                    title: "Approval Preferences",
                    destination: .approvalPreferences
                ),
                SettingsRow(id: "data", symbolName: "lock.fill", title: "Data & Privacy", destination: .dataPrivacy),
            ]),
            SettingsSection(id: "about", title: "About", rows: [
                SettingsRow(
                    id: "about",
                    symbolName: "info.circle.fill",
                    title: "About LifePilot",
                    detail: "0.5.0",
                    destination: .about
                ),
            ]),
        ]
    }

    public func load() async {
        guard let preferenceStore else { return }
        preferences = await preferenceStore.loadPreferences()
        memoryCount = await preferenceStore.allMemory().count
        cloudSyncEnabled = await cloudSync.isSyncEnabled()
        await refreshConnections()
    }

    public func setOnboardingCompleted(_ value: Bool) async throws {
        guard let preferenceStore else { return }
        preferences.onboardingCompleted = value
        try await preferenceStore.savePreferences(preferences)
    }

    public func setSensitivePreviews(_ enabled: Bool) async throws {
        guard let preferenceStore else { return }
        preferences.sensitiveNotificationPreviews = enabled
        try await preferenceStore.savePreferences(preferences)
    }

    public func setBriefingHour(_ hour: Int) async throws {
        guard let preferenceStore else { return }
        preferences.briefingHour = min(23, max(0, hour))
        try await preferenceStore.savePreferences(preferences)
    }

    public func setQuietHours(start: Int, end: Int) async throws {
        guard let preferenceStore else { return }
        preferences.quietHoursStart = min(23, max(0, start))
        preferences.quietHoursEnd = min(23, max(0, end))
        try await preferenceStore.savePreferences(preferences)
    }

    public func setAppearance(_ appearance: UserPreferences.AppearancePreference) async throws {
        guard let preferenceStore else { return }
        preferences.appearance = appearance
        try await preferenceStore.savePreferences(preferences)
    }

    public func setTransitConfiguration(stopID: String, stopName: String, linesText: String) async {
        guard let preferenceStore else { return }
        preferences.transitStopID = stopID.trimmingCharacters(in: .whitespacesAndNewlines)
        preferences.transitStopName = stopName.trimmingCharacters(in: .whitespacesAndNewlines)
        var seen: Set<String> = []
        preferences.transitLineNames = linesText.split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty && seen.insert($0.lowercased()).inserted }
        do {
            try await preferenceStore.savePreferences(preferences)
            transitMessage = preferences.transitStopID.isEmpty
                ? "Live transit is off. The rest of your briefing still works."
                : "Transit stop saved. Pull to refresh Home for live departures."
        } catch {
            transitMessage = "Could not save the transit stop."
        }
    }

    public func requestConnection(_ kind: PermissionKind) async {
        connectionMessage = nil
        do {
            let state = try await permissions.request(kind)
            connectionMessage = state == .authorized
                ? "\(kind.displayName) connected."
                : "\(kind.displayName) access is \(state.rawValue)."
        } catch {
            connectionMessage = error.localizedDescription
        }
        await refreshConnections()
    }

    public func refreshConnections() async {
        async let calendar = permissions.state(for: .calendar)
        async let reminders = permissions.state(for: .reminders)
        async let notifications = permissions.state(for: .notifications)
        async let location = permissions.state(for: .location)
        setConnection("calendar", await calendar)
        setConnection("reminders", await reminders)
        setConnection("notifications", await notifications)
        setConnection("location", await location)
    }

    public func state(for kind: PermissionKind) -> PermissionState {
        connections.first(where: { $0.id == kind.rawValue })?.state ?? .unavailable
    }

    private func setConnection(_ id: String, _ state: PermissionState) {
        guard let index = connections.firstIndex(where: { $0.id == id }) else { return }
        connections[index].state = state
        connections[index].lastCheckedAt = Date()
    }

    private static var defaultConnections: [ConnectionCapability] {
        PermissionKind.allCases.map {
            ConnectionCapability(id: $0.rawValue, displayName: $0.displayName, state: .notRequested)
        }
    }
}

public struct SettingsSection: Identifiable {
    public let id: String
    public let title: String
    public let rows: [SettingsRow]
}

public struct SettingsRow: Identifiable {
    public let id: String
    public let symbolName: String
    public let title: String
    public let detail: String?
    public let destination: SettingsDestination?

    public init(
        id: String,
        symbolName: String,
        title: String,
        detail: String? = nil,
        destination: SettingsDestination? = nil
    ) {
        self.id = id
        self.symbolName = symbolName
        self.title = title
        self.detail = detail
        self.destination = destination
    }
}

public enum SettingsDestination: Hashable {
    case profile
    case connectedApps
    case approvalPreferences
    case dataPrivacy
    case appearance
    case liveExperiences
    case about
}
