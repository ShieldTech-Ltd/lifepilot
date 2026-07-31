import LifePilotCore
import LifePilotDesignSystem
import SwiftUI

/// Shows which of LifePilot's sources Ghost Brain can read from. Every
/// source is mock data in this phase (real integrations arrive in
/// docs/MASTER_ROADMAP.md Phase 7), but the on/off state is real and
/// persists locally - the user, not Ghost Brain, decides what it can see,
/// per README.md's "Orchestrate, don't replace" principle.
public struct ConnectedAppsView: View {
    private let session: DemoSessionStore

    public init(session: DemoSessionStore) {
        self.session = session
    }

    public init() {
        self.init(session: DemoSessionStore())
    }

    public var body: some View {
        List {
            Section {
                toggleRow(agent: .calendar)
                toggleRow(agent: .email)
                toggleRow(agent: .travel)
                toggleRow(agent: .finance)
            } footer: {
                Text("These switches control the realistic demo sources shown across Home, Timeline, Memory, and Insights. No external account is accessed.")
            }
        }
        .navigationTitle("Connected Apps")
    }

    private func toggleRow(agent: AgentKind) -> some View {
        let isOn = session.isEnabled(agent)
        return Toggle(isOn: Binding(
            get: { session.isEnabled(agent) },
            set: { session.setConnection(agent, isEnabled: $0) }
        )) {
            HStack(spacing: Spacing.md) {
                AgentAvatar(agent: agent, size: 28)
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text(agent.displayName)
                        .font(.LifePilot.body)
                        .foregroundStyle(Color.LifePilot.textPrimary)
                    Text(isOn ? "Demo source active" : "Demo source paused")
                        .font(.LifePilot.caption)
                        .foregroundStyle(Color.LifePilot.textSecondary)
                }
            }
        }
        .accessibilityIdentifier("connectedSource.\(agent.rawValue)")
    }
}

#Preview {
    NavigationStack {
        ConnectedAppsView()
    }
}
