import Foundation

#if os(iOS) && canImport(ActivityKit)
import ActivityKit
import WidgetKit

@Observable
@MainActor
public final class LiveActivityManager {
    public private(set) var isActive = false
    public private(set) var errorMessage: String?

    public init() {
        refreshState()
    }

    public var activitiesAreEnabled: Bool {
        ActivityAuthorizationInfo().areActivitiesEnabled
    }

    public func start(userName: String, nextItem: String, detail: String, progress: Double) {
        errorMessage = nil
        guard activitiesAreEnabled else {
            errorMessage = "Live Activities are disabled for LifePilot in iPhone Settings."
            return
        }

        do {
            let attributes = LifePilotActivityAttributes(
                userName: userName,
                context: "Personal day"
            )
            let state = LifePilotActivityAttributes.ContentState(
                nextItem: nextItem,
                detail: detail,
                progress: progress
            )
            let content = ActivityContent(
                state: state,
                staleDate: Date().addingTimeInterval(60 * 90)
            )
            _ = try Activity.request(attributes: attributes, content: content, pushType: nil)
            refreshState()
        } catch {
            errorMessage = "The Live Activity could not start. Try again on a Dynamic Island iPhone."
        }
    }

    public func end() async {
        let finalState = LifePilotActivityAttributes.ContentState(
            nextItem: "Day ready",
            detail: "Every prepared action is up to date",
            progress: 1
        )
        let finalContent = ActivityContent(state: finalState, staleDate: nil)
        for activity in Activity<LifePilotActivityAttributes>.activities {
            await activity.end(finalContent, dismissalPolicy: .immediate)
        }
        refreshState()
    }

    public func refreshWidgets() {
        WidgetCenter.shared.reloadAllTimelines()
    }

    public func refreshState() {
        isActive = !Activity<LifePilotActivityAttributes>.activities.isEmpty
    }
}
#else
@Observable
@MainActor
public final class LiveActivityManager {
    public private(set) var isActive = false
    public private(set) var errorMessage: String?
    public var activitiesAreEnabled: Bool { false }

    public init() {}
    public func start(userName _: String, nextItem _: String, detail _: String, progress _: Double) {
        errorMessage = "Live Activities are available on supported iPhones."
    }

    public func end() async {}

    public func refreshWidgets() {}

    public func refreshState() {}
}
#endif
