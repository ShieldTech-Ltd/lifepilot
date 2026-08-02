import LifePilotCore
import SwiftUI

/// Visual identity for a given AI agent's output, per docs/DESIGN_SYSTEM.md's
/// Components table. Used wherever a recommendation or signal needs to be
/// attributed to the agent that produced it - see docs/MASTER_ROADMAP.md
/// Phase 6's UX requirement that agent output be attributable in the UI.
public struct AgentAvatar: View {
    private let agent: AgentKind
    private let size: CGFloat

    public init(agent: AgentKind, size: CGFloat = 32) {
        self.agent = agent
        self.size = size
    }

    public var body: some View {
        Image(systemName: agent.symbolName)
            .font(.system(size: size * 0.45, weight: .medium))
            .foregroundStyle(.white)
            .frame(width: size, height: size)
            .background(agentColor, in: Circle())
            .overlay {
                Circle().stroke(Color.white.opacity(0.24), lineWidth: 1)
            }
            .clipShape(Circle())
            .accessibilityLabel("\(agent.displayName) agent")
    }

    private var agentColor: Color {
        switch agent {
        case .calendar: Color.LifePilot.accentEnd
        case .email: Color.LifePilot.accentAI
        case .travel: Color.LifePilot.accentStart
        case .finance: Color.LifePilot.accentWarm
        case .memory: Color.LifePilot.signalInfo
        case .reminder: Color.LifePilot.signalRisk
        case .shopping: Color.LifePilot.accentAI
        case .health: Color.LifePilot.signalSuccess
        case .security: Color.LifePilot.textSecondary
        }
    }
}
