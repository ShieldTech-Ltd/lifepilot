import LifePilotCore
import LifePilotDesignSystem
import SwiftUI

public struct ConnectedAppsView: View {
    @Environment(\.openURL) private var openURL
    @State private var states: [String: PermissionState] = [:]
    @State private var message: String?
    private let session: DemoSessionStore
    private let kinds: [PermissionKind] = [.calendar, .reminders, .notifications, .location]

    public init(session: DemoSessionStore) {
        self.session = session
    }

    public init() {
        self.init(session: DemoSessionStore())
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.xl) {
                ScreenHeader(
                    eyebrow: "Your data boundaries",
                    title: "Connected sources",
                    subtitle: "Pause any source and its content disappears across Home, Timeline, Memory, and Insights."
                )

                HStack {
                    Label("\(connectedCount) of \(kinds.count) connected", systemImage: "link.circle.fill")
                        .font(.LifePilot.caption.weight(.semibold))
                        .foregroundStyle(Color.LifePilot.accentStart)
                    Spacer()
                    Text("ON DEVICE")
                        .font(.LifePilot.utility)
                        .foregroundStyle(Color.LifePilot.textSecondary)
                }
                .padding(.horizontal, Spacing.xs)

                VStack(spacing: Spacing.sm) {
                    ForEach(kinds, id: \.rawValue) { kind in
                        sourceCard(kind)
                    }
                }

                if let message {
                    Text(message)
                        .font(.LifePilot.caption)
                        .foregroundStyle(Color.LifePilot.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                }

                CardContainer {
                    HStack(alignment: .top, spacing: Spacing.md) {
                        Image(systemName: "square.and.arrow.down.fill")
                            .foregroundStyle(Color.LifePilot.accentStart)
                            .frame(width: 36, height: 36)
                            .background(Color.LifePilot.accentStart.opacity(0.12), in: Circle())

                        VStack(alignment: .leading, spacing: Spacing.xs) {
                            Text("Add invitations to LifePilot")
                                .font(.LifePilot.body.weight(.semibold))
                                .foregroundStyle(Color.LifePilot.textPrimary)
                            Text(
                                "In Apple Mail or Gmail, open Share and choose LifePilot. Calendar files, "
                                    + "invitation text, links, and schedule screenshots are supported."
                            )
                                .font(.LifePilot.caption)
                                .foregroundStyle(Color.LifePilot.textSecondary)
                        }
                    }
                }
                .accessibilityElement(children: .combine)
                .accessibilityIdentifier("connectedSources.shareInvitationHelp")

                Label("LifePilot reads only sources you authorize.", systemImage: "lock.fill")
                .font(.LifePilot.caption)
                .foregroundStyle(Color.LifePilot.textSecondary)
                .frame(maxWidth: .infinity, alignment: .center)
            }
            .padding(Spacing.lg)
        }
        .lifePilotScreenBackground(energy: .prominent)
        .navigationTitle("Sources")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .task { await refreshStates() }
    }

    private func sourceCard(_ kind: PermissionKind) -> some View {
        let state = states[kind.rawValue] ?? .notRequested
        return CardContainer {
            HStack(spacing: Spacing.md) {
                Image(systemName: symbolName(for: kind))
                    .foregroundStyle(Color.LifePilot.accentStart)
                    .frame(width: 44, height: 44)
                    .background(Color.LifePilot.accentStart.opacity(0.12), in: Circle())
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text(kind.displayName)
                        .font(.LifePilot.body.weight(.semibold))
                        .foregroundStyle(Color.LifePilot.textPrimary)
                    Text(sourceDescription(kind))
                        .font(.LifePilot.caption)
                        .foregroundStyle(Color.LifePilot.textSecondary)
                }
                Spacer()
                Button(buttonTitle(for: state)) {
                    Task { await handle(kind, state: state) }
                }
                .font(.LifePilot.caption.weight(.semibold))
                .foregroundStyle(state == .authorized || state == .limited
                    ? Color.LifePilot.signalSuccess
                    : Color.LifePilot.accentEnd)
                .accessibilityIdentifier("connectedSource.\(kind.rawValue)")
            }
        }
    }

    private var connectedCount: Int {
        states.values.filter { $0 == .authorized || $0 == .limited }.count
    }

    private func refreshStates() async {
        await session.refreshPermissionStates()
        states = session.permissionStates
    }

    private func handle(_ kind: PermissionKind, state: PermissionState) async {
        if state == .denied || state == .restricted {
            if let url = PermissionSystemSettings.url {
                openURL(url)
            }
            return
        }
        do {
            let updated = try await session.requestPermission(kind)
            states[kind.rawValue] = updated
            message = updated == .authorized || updated == .limited
                ? "\(kind.displayName) connected. Pull to refresh your briefing."
                : "\(kind.displayName) was not connected."
        } catch {
            message = error.localizedDescription
        }
    }

    private func buttonTitle(for state: PermissionState) -> String {
        switch state {
        case .authorized, .limited: "Connected"
        case .denied, .restricted: "Settings"
        case .notRequested: "Connect"
        case .unavailable: "Unavailable"
        }
    }

    private func symbolName(for kind: PermissionKind) -> String {
        switch kind {
        case .calendar: "calendar"
        case .reminders: "checklist"
        case .notifications: "bell.fill"
        case .location: "location.fill"
        }
    }

    private func sourceDescription(_ kind: PermissionKind) -> String {
        switch kind {
        case .calendar: "Appointments, shifts, plans, and schedule conflicts"
        case .reminders: "Open Apple Reminders beside LifePilot tasks"
        case .notifications: "Due-task and approved planning alerts"
        case .location: "Local WeatherKit and travel context"
        }
    }
}

#Preview {
    NavigationStack { ConnectedAppsView() }
}
