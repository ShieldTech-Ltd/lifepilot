/// A single step in the onboarding flow. Each step names the concrete
/// feature it unlocks, per docs/MASTER_ROADMAP.md Phase 4's UX
/// requirement that permission requests are contextual, not a blanket
/// upfront dump.
public struct OnboardingStep: Identifiable {
    public let id: String
    public let symbolName: String
    public let title: String
    public let message: String

    public init(id: String, symbolName: String, title: String, message: String) {
        self.id = id
        self.symbolName = symbolName
        self.title = title
        self.message = message
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
            title: "Preview connected sources",
            message: "This TechFest build uses realistic UK student data to show how LifePilot combines "
                + "your timetable, inbox, travel, and spending without accessing a real account."
        ),
        OnboardingStep(
            id: "approvals",
            symbolName: "checkmark.shield.fill",
            title: "You're always in control",
            message: "LifePilot prepares recommendations. Nothing sends, books, "
                + "or moves money without your explicit approval."
        ),
        OnboardingStep(
            id: "ready",
            symbolName: "arrow.right.circle.fill",
            title: "You're ready",
            message: "Your student briefing is waiting."
        ),
    ]
}
