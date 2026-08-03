import LifePilotDesignSystem
import LifePilotFeatures
import SwiftUI

/// The root `TabView`, hosting the five tabs defined in `AppTab`. Each tab
/// wraps its screen in its own `NavigationStack`, per SwiftUI's recommended
/// pattern for independent per-tab navigation history.
public struct RootTabView: View {
    @Environment(\.scenePhase) private var scenePhase
    @State private var session: DemoSessionStore
    @State private var selectedTab: AppTab = Self.initialTab
    @State private var tabBarMinimisationEnabled = false

    private static var initialTab: AppTab {
        #if DEBUG
        let arguments = ProcessInfo.processInfo.arguments
        if let flagIndex = arguments.firstIndex(of: "-LifePilotDemoTab"),
           arguments.indices.contains(flagIndex + 1),
           let tab = AppTab(rawValue: arguments[flagIndex + 1])
        {
            return tab
        }
        #endif
        return .home
    }

    public init(dependencies: AppDependencies) {
        _session = State(initialValue: DemoSessionStore(ghostBrain: dependencies.ghostBrain))
    }

    public init(session: DemoSessionStore) {
        _session = State(initialValue: session)
    }

    public var body: some View {
        Group {
            #if os(iOS)
            if #available(iOS 18.0, *) {
                modernTabView
            } else {
                legacyTabView
            }
            #else
            legacyTabView
            #endif
        }
        .tint(Color.LifePilot.accentEnd)
        .lifePilotTabChrome(minimisationEnabled: tabBarMinimisationEnabled)
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                session.reloadSharedEvents()
            }
        }
        .task {
            await session.prepare()
        }
        .task(id: selectedTab) {
            #if os(iOS)
            guard #available(iOS 26.0, *) else { return }
            tabBarMinimisationEnabled = false
            try? await Task.sleep(for: .milliseconds(350))
            guard !Task.isCancelled else { return }
            tabBarMinimisationEnabled = true
            #endif
        }
    }

    #if os(iOS)
    @available(iOS 18.0, *)
    private var modernTabView: some View {
        TabView(selection: $selectedTab) {
            ForEach(AppTab.allCases) { tab in
                Tab(tab.title, systemImage: tab.symbolName, value: tab) {
                    tabRoot(for: tab)
                }
                .accessibilityIdentifier("tab.\(tab.rawValue)")
            }
        }
    }
    #endif

    private var legacyTabView: some View {
        TabView(selection: $selectedTab) {
            ForEach(AppTab.allCases) { tab in
                tabRoot(for: tab)
                    .tabItem {
                        Label(tab.title, systemImage: tab.symbolName)
                            .accessibilityIdentifier("tab.\(tab.rawValue)")
                    }
                    .tag(tab)
            }
        }
    }

    private func tabRoot(for tab: AppTab) -> some View {
        NavigationStack {
            destination(for: tab)
        }
    }

    @ViewBuilder
    private func destination(for tab: AppTab) -> some View {
        switch tab {
        case .home:
            HomeView(session: session) { filter in
                session.timelineFilter = filter
                selectedTab = .timeline
            }
                .navigationTitle("")
                #if os(iOS)
                .navigationBarTitleDisplayMode(.inline)
                #endif
        case .timeline:
            TimelineView(session: session)
        case .memory:
            MemoryView(session: session)
        case .insights:
            InsightsView(
                session: session,
                onReviewApprovals: { selectedTab = .home },
                onOpenTimeline: { filter in
                    session.timelineFilter = filter
                    selectedTab = .timeline
                }
            )
        case .settings:
            SettingsView(session: session)
        }
    }
}

private extension View {
    @ViewBuilder
    func lifePilotTabChrome(minimisationEnabled: Bool) -> some View {
        #if os(iOS)
        #if compiler(>=6.2)
        if #available(iOS 26.0, *) {
            tabBarMinimizeBehavior(minimisationEnabled ? .onScrollDown : .never)
        } else {
            toolbarBackground(.ultraThinMaterial, for: .tabBar)
                .toolbarBackground(.visible, for: .tabBar)
        }
        #else
        toolbarBackground(.ultraThinMaterial, for: .tabBar)
            .toolbarBackground(.visible, for: .tabBar)
        #endif
        #else
        self
        #endif
    }
}

#Preview {
    RootTabView(dependencies: .live)
}
