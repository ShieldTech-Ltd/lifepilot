import LifePilotDesignSystem
import LifePilotFeatures
import SwiftUI

/// The root `TabView`, hosting the five tabs defined in `AppTab`. Each tab
/// wraps its screen in its own `NavigationStack`, per SwiftUI's recommended
/// pattern for independent per-tab navigation history.
public struct RootTabView: View {
    @State private var session: DemoSessionStore
    @State private var selectedTab: AppTab = .home

    public init(dependencies: AppDependencies) {
        _session = State(initialValue: DemoSessionStore(ghostBrain: dependencies.ghostBrain))
    }

    public init(session: DemoSessionStore) {
        _session = State(initialValue: session)
    }

    public var body: some View {
        TabView(selection: $selectedTab) {
            ForEach(AppTab.allCases) { tab in
                NavigationStack {
                    destination(for: tab)
                }
                .tabItem {
                    Label(tab.title, systemImage: tab.symbolName)
                }
                .tag(tab)
            }
        }
        .tint(Color.LifePilot.accentEnd)
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
            InsightsView(session: session)
        case .settings:
            SettingsView(session: session)
        }
    }
}

#Preview {
    RootTabView(dependencies: .live)
}
