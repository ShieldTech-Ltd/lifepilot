/// A single step in the onboarding flow. Each step names the concrete
/// feature it unlocks, per docs/MASTER_ROADMAP.md Phase 4's UX
/// requirement that permission requests are contextual, not a blanket
/// upfront dump.
public struct OnboardingStep: Identifiable {
    public let id: String
    public let symbolName: String
    public let title: String
    public let message: String
    public let permission: PermissionKind?

    public init(
        id: String,
        symbolName: String,
        title: String,
        message: String,
        permission: PermissionKind? = nil
    ) {
        self.id = id
        self.symbolName = symbolName
        self.title = title
        self.message = message
        self.permission = permission
    }

    public static let allSteps: [OnboardingStep] = [
        OnboardingStep(
            id: "welcome",
            symbolName: "sparkle",
            title: "Meet LifePilot",
            message: "A personal planner for events, reminders, work shifts, appointments, and everyday travel."
        ),
        OnboardingStep(
            id: "calendar",
            symbolName: "calendar",
            title: "Connect your calendar",
            message: "Bring appointments, work shifts, plans, and invitations into one timeline.",
            permission: .calendar
        ),
        OnboardingStep(
            id: "reminders",
            symbolName: "checklist",
            title: "Bring in your reminders",
            message: "See open commitments beside your LifePilot tasks, or connect them later.",
            permission: .reminders
        ),
        OnboardingStep(
            id: "notifications",
            symbolName: "bell.badge.fill",
            title: "Choose helpful alerts",
            message: "Get briefings and approved leave-by alerts without exposing sensitive previews.",
            permission: .notifications
        ),
        OnboardingStep(
            id: "location",
            symbolName: "location.fill",
            title: "Add local context",
            message: "Location improves UK weather and travel guidance. LifePilot still works if you skip it.",
            permission: .location
        ),
        OnboardingStep(
            id: "approvals",
            symbolName: "checkmark.shield.fill",
            title: "You're always in control",
            message: "LifePilot prepares recommendations. Nothing sends, books, "
                + "or acts outside LifePilot without your explicit approval."
        ),
        OnboardingStep(
            id: "ready",
            symbolName: "arrow.right.circle.fill",
            title: "You're ready",
            message: "Your daily briefing is waiting."
        ),
    ]

    /// Concise, permission-free sequence used by the self-contained personal preview.
    public static let showcaseSteps: [OnboardingStep] = [
        allSteps[0],
        OnboardingStep(
            id: "calendar",
            symbolName: "calendar",
            title: "Preview connected sources",
            message: "This preview uses realistic personal events to show how LifePilot organises "
                + "appointments, work, reminders, and travel without accessing a real account."
        ),
        allSteps[5],
        allSteps[6],
    ]
}
