import LifePilotCore
import LifePilotFeatures
import SwiftUI

/// The top-level view controlling the Splash → Onboarding → Main app
/// transition. This is the single entry point the thin Xcode app target
/// (`App/`) is expected to instantiate - see `docs/ARCHITECTURE.md`'s note
/// that `Package.swift` builds the first buildable units ahead of the full
/// iOS app wrapper.
public struct LifePilotRootView: View {
    @State private var phase: LaunchPhase = .splash
    @AppStorage(StorageKey.hasCompletedOnboarding) private var hasCompletedOnboarding = false
    @State private var session: DemoSessionStore

    public init(dependencies: AppDependencies = .live) {
        _session = State(initialValue: DemoSessionStore(
            ghostBrain: dependencies.ghostBrain,
            taskStore: dependencies.taskStore,
            eventStore: dependencies.eventStore,
            preferenceStore: dependencies.preferenceStore,
            approvalStore: dependencies.approvalStore,
            remindersIntegration: dependencies.remindersIntegration,
            notificationScheduler: dependencies.notificationScheduler,
            permissions: PermissionDependencies(
                calendar: dependencies.calendarIntegration,
                reminders: dependencies.remindersIntegration,
                notifications: dependencies.notificationScheduler,
                location: dependencies.locationProvider
            )
        ))
    }

    public var body: some View {
        Group {
            switch phase {
            case .splash:
                SplashView(session: session)
            case .onboarding:
                OnboardingView(session: session, onFinish: {
                    hasCompletedOnboarding = true
                    withAnimation(.easeInOut(duration: 0.35)) {
                        phase = .main
                    }
                })
            case .main:
                RootTabView(session: session)
            }
        }
        .preferredColorScheme(preferredColorScheme)
        .task {
            // A brief, deliberate splash duration - long enough to read as
            // intentional, short enough not to feel like a delay. See
            // docs/DESIGN_SYSTEM.md's Motion principle.
            try? await Task.sleep(for: .seconds(1.25))
            withAnimation(.easeInOut(duration: 0.35)) {
                phase = hasCompletedOnboarding ? .main : .onboarding
            }
        }
    }

    private var preferredColorScheme: ColorScheme? {
        switch session.appearancePreference {
        case .system: nil
        case .light: .light
        case .dark: .dark
        }
    }

    private enum LaunchPhase {
        case splash
        case onboarding
        case main
    }
}

#Preview {
    LifePilotRootView()
}
