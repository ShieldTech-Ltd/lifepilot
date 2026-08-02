import LifePilotCore
import LifePilotDesignSystem
import SwiftUI

public struct ConnectedAppsView: View {
    private let session: DemoSessionStore
    private let agents: [AgentKind] = [.calendar, .email, .travel, .finance]

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
                    Label("\(session.connectedSourceCount) of 4 active", systemImage: "link.circle.fill")
                        .font(.LifePilot.caption.weight(.semibold))
                        .foregroundStyle(Color.LifePilot.accentStart)
                    Spacer()
                    Text("DEMO DATA")
                        .font(.LifePilot.utility)
                        .foregroundStyle(Color.LifePilot.textSecondary)
                }
                .padding(.horizontal, Spacing.xs)

                VStack(spacing: Spacing.sm) {
                    ForEach(agents, id: \.self) { agent in
                        sourceCard(agent)
                    }
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
                            Text("In Apple Mail or Gmail, open Share and choose LifePilot. Calendar files, invitation text, links, and schedule screenshots are supported.")
                                .font(.LifePilot.caption)
                                .foregroundStyle(Color.LifePilot.textSecondary)
                        }
                    }
                }
                .accessibilityElement(children: .combine)
                .accessibilityIdentifier("connectedSources.shareInvitationHelp")

                Label(
                    "No external account is accessed in this TechFest build.",
                    systemImage: "lock.fill"
                )
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
    }

    private func sourceCard(_ agent: AgentKind) -> some View {
        let isOn = session.isEnabled(agent)
        return CardContainer {
            Toggle(isOn: Binding(
                get: { session.isEnabled(agent) },
                set: { session.setConnection(agent, isEnabled: $0) }
            )) {
                HStack(spacing: Spacing.md) {
                    AgentAvatar(agent: agent, size: 44)
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        Text(agent.displayName)
                            .font(.LifePilot.body.weight(.semibold))
                            .foregroundStyle(Color.LifePilot.textPrimary)
                        Text(isOn ? sourceDescription(agent) : "Paused across the app")
                            .font(.LifePilot.caption)
                            .foregroundStyle(isOn ? Color.LifePilot.textSecondary : Color.LifePilot.signalWarning)
                    }
                }
            }
            .tint(Color.LifePilot.accentStart)
            .accessibilityIdentifier("connectedSource.\(agent.rawValue)")
        }
    }

    private func sourceDescription(_ agent: AgentKind) -> String {
        switch agent {
        case .calendar: "Lectures, deadlines, and event timing"
        case .email: "Important messages and reply context"
        case .travel: "UK journeys, delays, and station timing"
        case .finance: "Spending signals and renewal awareness"
        default: "Connected context"
        }
    }
}

#Preview {
    NavigationStack { ConnectedAppsView() }
}
