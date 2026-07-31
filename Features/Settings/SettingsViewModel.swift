import Foundation

/// Builds Settings rows from the live demo session.
@Observable
@MainActor
public final class SettingsViewModel {
    public let session: DemoSessionStore

    public init(session: DemoSessionStore) {
        self.session = session
    }

    public convenience init() {
        self.init(session: DemoSessionStore())
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
                SettingsRow(id: "version", symbolName: "graduationcap.fill", title: "UK Student Demo", detail: "0.5.0"),
            ]),
        ]
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
}
