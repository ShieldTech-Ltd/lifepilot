/// Shared `UserDefaults` keys for small pieces of local device state that
/// span multiple modules — e.g. `AppShell`'s onboarding gate and Settings'
/// profile/preference screens. Centralized here, in the one module every
/// other module already depends on, so the two sides of each key never
/// drift out of sync.
public enum StorageKey {
    public static let hasCompletedOnboarding = "com.lifepilot.hasCompletedOnboarding"
    public static let profileDisplayName = "com.lifepilot.profile.displayName"
    public static let profileEmail = "com.lifepilot.profile.email"
    public static let profileCourse = "com.lifepilot.profile.course"
    public static let profileUniversity = "com.lifepilot.profile.university"
    public static let profileLocation = "com.lifepilot.profile.location"
    public static let profileBriefingTime = "com.lifepilot.profile.briefingTime"
    public static let connectedCalendar = "com.lifepilot.connected.calendar"
    public static let connectedEmail = "com.lifepilot.connected.email"
    public static let connectedTravel = "com.lifepilot.connected.travel"
    public static let connectedFinance = "com.lifepilot.connected.finance"
    public static let approvalsNotifyOnHighRisk = "com.lifepilot.approvals.notifyOnHighRisk"

    /// Every key above, for bulk operations like Settings' "Reset Local
    /// Demo Data" action — kept as a single array so a forgotten new key
    /// can't silently escape the reset.
    public static let all: [String] = [
        hasCompletedOnboarding,
        profileDisplayName,
        profileEmail,
        profileCourse,
        profileUniversity,
        profileLocation,
        profileBriefingTime,
        connectedCalendar,
        connectedEmail,
        connectedTravel,
        connectedFinance,
        approvalsNotifyOnHighRisk,
    ]
}
