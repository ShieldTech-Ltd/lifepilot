/// Identifies which agent produced a given signal, prediction, or
/// recommendation. See the AI Agent System in README.md for what each
/// agent is responsible for at the product level.
public enum AgentKind: String, CaseIterable, Codable, Hashable, Sendable {
    case calendar
    case email
    case reminder
    case task
    case travel
    case weather
    case finance
    case memory
    case planning
    case shopping
    case health
    case security

    /// A short, display-ready name for the agent, used wherever the UI
    /// attributes a recommendation to its source per docs/MASTER_ROADMAP.md's
    /// Phase 6 UX requirement that agent output be attributable.
    public var displayName: String {
        switch self {
        case .calendar: "Calendar"
        case .email: "Email"
        case .reminder: "Reminder"
        case .task: "Tasks"
        case .travel: "Travel"
        case .weather: "Weather"
        case .finance: "Finance"
        case .memory: "Memory"
        case .planning: "Planning"
        case .shopping: "Shopping"
        case .health: "Health"
        case .security: "Security"
        }
    }

    /// The SF Symbol used to represent this agent throughout the UI.
    public var symbolName: String {
        switch self {
        case .calendar: "calendar"
        case .email: "envelope.fill"
        case .reminder: "bell.fill"
        case .task: "checkmark.circle.fill"
        case .travel: "airplane"
        case .weather: "cloud.sun.fill"
        case .finance: "sterlingsign.circle.fill"
        case .memory: "brain.head.profile"
        case .planning: "lightbulb.fill"
        case .shopping: "cart.fill"
        case .health: "heart.fill"
        case .security: "shield.fill"
        }
    }
}
