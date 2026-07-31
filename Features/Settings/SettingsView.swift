import LifePilotDesignSystem
import SwiftUI

/// Settings for the local demo identity, connected sources, approval
/// preferences, and repeatable showcase data.
public struct SettingsView: View {
    @State private var viewModel: SettingsViewModel

    public init(session: DemoSessionStore) {
        _viewModel = State(initialValue: SettingsViewModel(session: session))
    }

    public init() {
        self.init(session: DemoSessionStore())
    }

    public var body: some View {
        List {
            ForEach(viewModel.sections) { section in
                Section(section.title) {
                    ForEach(section.rows) { row in
                        rowContent(row)
                    }
                }
            }
        }
        .navigationTitle("Settings")
        .navigationDestination(for: SettingsDestination.self) { destination in
            destinationView(for: destination)
        }
    }

    @ViewBuilder
    private func rowContent(_ row: SettingsRow) -> some View {
        if let destination = row.destination {
            NavigationLink(value: destination) {
                rowLabel(row)
            }
        } else {
            rowLabel(row)
        }
    }

    private func rowLabel(_ row: SettingsRow) -> some View {
        HStack(spacing: Spacing.md) {
            Image(systemName: row.symbolName)
                .foregroundStyle(LinearGradient.LifePilot.accent)
                .frame(width: 24)

            Text(row.title)
                .font(.LifePilot.body)
                .foregroundStyle(Color.LifePilot.textPrimary)

            Spacer()

            if let detail = row.detail {
                Text(detail)
                    .font(.LifePilot.caption)
                    .foregroundStyle(Color.LifePilot.textSecondary)
            }
        }
    }

    @ViewBuilder
    private func destinationView(for destination: SettingsDestination) -> some View {
        switch destination {
        case .profile: ProfileDetailView(session: viewModel.session)
        case .connectedApps: ConnectedAppsView(session: viewModel.session)
        case .approvalPreferences: ApprovalPreferencesView(session: viewModel.session)
        case .dataPrivacy: DataPrivacyView(session: viewModel.session)
        }
    }
}

#Preview {
    NavigationStack {
        SettingsView()
    }
}
