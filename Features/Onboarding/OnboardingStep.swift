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
            message: "A student-first AI planner for lectures, deadlines, travel, and money. "
                + "Built for UK campus life and designed to grow with everyone."
        ),
        OnboardingStep(
            id: "calendar",
            symbolName: "calendar",
            title: "Connect your calendar",
            message: "Bring lectures, deadlines, and invitations into one student-first timeline.",
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
            message: "Your student briefing is waiting."
        ),
    ]

    /// Concise, permission-free sequence used by the self-contained TechFest demo.
    public static let showcaseSteps: [OnboardingStep] = [
        allSteps[0],
        OnboardingStep(
            id: "calendar",
            symbolName: "calendar",
            title: "Preview connected sources",
            message: "This TechFest build uses realistic UK student data to show how LifePilot combines "
                + "your timetable, inbox, travel, and spending without accessing a real account."
        ),
        allSteps[5],
        allSteps[6],
    ]
}
